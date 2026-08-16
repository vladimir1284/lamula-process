import { setup, assign, fromPromise } from 'xstate';
import {
	openObservationFiles,
	addRecentFile,
	reopenLocalFile,
	getRememberedFileHandle,
	type RecentFileEntry
} from '$lib/platform';
import { fetchVolumeScanBytes } from '$lib/aws-explorer/nexradS3';
import { parseObservation } from '$lib/parsers';
import { mergeSweeps, createTimeSpan, type TimeSpan } from '$lib/domain';
import type { Observation } from '$lib/domain/types';

/**
 * Open → parse pipeline as an XState machine. The async, failure-prone part of loading a file
 * (pick a file, decode bytes into an Observation, update the recent-files MRU) is exactly the
 * kind of orchestration a state machine keeps honest: explicit `opening` / `parsing` / `error`
 * states, cancellation handled as a first-class path (picker returns null → back to idle).
 *
 * Product selection / rendering stays reactive Svelte state in the page — only the load pipeline
 * lives here. `LOAD_REMOTE` (AWS S3 explorer) feeds the same `parsing` state as `OPEN` -- both
 * just need a `Picked` {fileName, bytes}, wherever the bytes came from.
 */

interface Picked {
	fileName: string;
	bytes: Uint8Array;
	source: 'local' | 'aws';
	s3Key?: string;
}

/** One resident, still-open observation. `fileName` isn't on the domain `Observation` -- carried
 * alongside from the `Picked` that produced it, the same way `recentFiles` stores labels outside
 * the domain model. */
export interface ObservationEntry {
	observation: Observation;
	fileName: string;
}

interface Ctx {
	observation: Observation | null;
	error: string | null;
	recentFiles: RecentFileEntry[];
	picked: Picked[] | null;
	pickedVolume: Picked[] | null;
	/** Independent from `observation` -- a TimeSpan is a second, parallel data source (multiple
	 * observations across time, for the accumulate product), not a variation of the single current
	 * Observation. Loading one never touches the other. */
	timeSpan: TimeSpan | null;
	pickedAccum: Picked[] | null;
	/** Every observation loaded and not yet closed (the observation-info window's manager list) --
	 * `observation` above always mirrors whichever entry here is `activeObservationId`. */
	observations: ObservationEntry[];
	activeObservationId: string | null;
}

/** Replace-by-`observation.id` or append -- reloading the same file (same site+timestamp) updates
 * its entry in place instead of duplicating it. */
function upsertObservationEntry(
	list: ObservationEntry[],
	entry: ObservationEntry
): ObservationEntry[] {
	const idx = list.findIndex((e) => e.observation.id === entry.observation.id);
	if (idx === -1) return [...list, entry];
	const next = [...list];
	next[idx] = entry;
	return next;
}

/** Re-fetches (aws) or re-reads (local, via the remembered handle) a recent-files entry. */
async function resolveRecentFile(entry: RecentFileEntry): Promise<Picked> {
	if (entry.source === 'aws') {
		if (!entry.s3Key) throw new Error(`Falta la clave S3 para reabrir "${entry.label}".`);
		const { bytes } = await fetchVolumeScanBytes(entry.s3Key);
		return { fileName: entry.label, bytes, source: 'aws', s3Key: entry.s3Key };
	}
	const handle = getRememberedFileHandle(entry.label);
	if (!handle) {
		// i18n-ignore: raw technical detail, shown collapsed behind a translated generic message
		throw new Error(`No se pudo reabrir "${entry.label}" automáticamente -- usa "Abrir archivo".`);
	}
	const { fileName, bytes } = await reopenLocalFile(handle);
	return { fileName, bytes, source: 'local' };
}

export const observationMachine = setup({
	types: {
		context: {} as Ctx,
		events: {} as
			| { type: 'OPEN' }
			| { type: 'OPEN_VOLUME' }
			| { type: 'OPEN_ACCUMULATE' }
			| { type: 'LOAD_REMOTE'; picked: Picked }
			| { type: 'LOAD_VOLUME'; picked: Picked[] }
			| { type: 'LOAD_ACCUMULATE'; picked: Picked[] }
			| { type: 'OPEN_RECENT'; entry: RecentFileEntry }
			| { type: 'RECENT_FILES_LOADED'; recentFiles: RecentFileEntry[] }
			| { type: 'SELECT_OBSERVATION'; id: string }
			| { type: 'CLOSE_OBSERVATION'; id: string }
	},
	actors: {
		// Multi-select so "Abrir archivo" can load several complete observations at once (e.g.
		// several .obs) -- each one is parsed independently by parseFile below and added as its own
		// entry, unlike openFiles/parseVolumeFile which stitch same-volume sweep files together.
		openFile: fromPromise(async (): Promise<Picked[]> => {
			const files = await openObservationFiles();
			return files.map((f) => ({ ...f, source: 'local' as const }));
		}),
		// Multi-file picker for opening a volume's sweep files at once (see parseVolumeFile).
		openFiles: fromPromise(async (): Promise<Picked[]> => {
			const files = await openObservationFiles();
			return files.map((f) => ({ ...f, source: 'local' as const }));
		}),
		// Parses each picked file as its own, independent Observation (unlike parseVolumeFile, which
		// merges same-volume sweep files into one) and records each in the recent-files list.
		parseFile: fromPromise(async ({ input }: { input: Picked[] }) => {
			const observations = await Promise.all(input.map((picked) => parseObservation(picked)));
			const entries = observations.map((observation, i) => ({
				observation,
				fileName: input[i].fileName
			}));
			let recentFiles: RecentFileEntry[] = [];
			for (const picked of input) {
				const config = await addRecentFile({
					label: picked.fileName,
					source: picked.source,
					s3Key: picked.s3Key
				});
				recentFiles = config.recentFiles;
			}
			return { entries, recentFiles };
		}),
		// Parses each single-sweep file and stitches them into one multi-tilt Observation (see
		// domain/mergeSweeps.ts) -- feeds both the AWS-volume-grouping and local-multi-file-open
		// paths, both of which only ever apply to Sigmet/IRIS RAW or NetCDF CfRadial (the two
		// one-sweep-per-file formats). The recent-files entry represents just the first file
		// (re-opening a merged volume later re-opens that one sweep, not the whole volume --
		// exact volume re-open would need a RecentFileEntry shape carrying multiple keys, deferred).
		parseVolumeFile: fromPromise(async ({ input }: { input: Picked[] }) => {
			const parsed = await Promise.all(input.map((picked) => parseObservation(picked)));
			const { observation } = mergeSweeps(parsed);
			const first = input[0];
			const config = await addRecentFile({
				label: first.fileName,
				source: first.source,
				s3Key: first.s3Key
			});
			return { observation, recentFiles: config.recentFiles };
		}),
		resolveRecent: fromPromise(async ({ input }: { input: RecentFileEntry }) =>
			resolveRecentFile(input)
		),
		// Parses each file and stitches them into a TimeSpan by TIME (unlike parseVolumeFile, which
		// stitches single-sweep files by ELEVATION into one Observation) -- feeds the accumulate
		// product's multi-file load. No recent-files entry: reopening 1-of-N files as if it were the
		// whole time series would be misleading (worse than parseVolumeFile's own known wart).
		parseAccumulateFile: fromPromise(async ({ input }: { input: Picked[] }) => {
			const parsed = await Promise.all(input.map((picked) => parseObservation(picked)));
			const { span } = createTimeSpan(parsed);
			return { timeSpan: span };
		})
	},
	actions: {
		assignRemotePicked: assign({
			error: null,
			picked: ({ event }) => [(event as { picked: Picked }).picked]
		}),
		assignVolumePicked: assign({
			error: null,
			pickedVolume: ({ event }) => (event as { picked: Picked[] }).picked
		}),
		assignAccumPicked: assign({
			error: null,
			pickedAccum: ({ event }) => (event as { picked: Picked[] }).picked
		}),
		assignRecentFiles: assign({
			recentFiles: ({ event }) => (event as { recentFiles: RecentFileEntry[] }).recentFiles
		}),
		selectObservation: assign({
			activeObservationId: ({ event }) => (event as { id: string }).id,
			observation: ({ context, event }) => {
				const id = (event as { id: string }).id;
				return (
					context.observations.find((e) => e.observation.id === id)?.observation ??
					context.observation
				);
			}
		}),
		closeObservation: assign(({ context, event }) => {
			const id = (event as { id: string }).id;
			const observations = context.observations.filter((e) => e.observation.id !== id);
			if (context.activeObservationId !== id) return { observations };
			const next = observations[observations.length - 1] ?? null;
			return {
				observations,
				activeObservationId: next?.observation.id ?? null,
				observation: next?.observation ?? null
			};
		})
	}
}).createMachine({
	id: 'observation',
	initial: 'idle',
	context: {
		observation: null,
		error: null,
		recentFiles: [],
		picked: null,
		pickedVolume: null,
		timeSpan: null,
		pickedAccum: null,
		observations: [],
		activeObservationId: null
	},
	// Internal (no target) so it applies from whichever state we're in without disturbing it --
	// the page sends this once on mount, after `loadConfig()` resolves. SELECT_OBSERVATION /
	// CLOSE_OBSERVATION are also global for the same reason -- the observation-info window's
	// manager list must work no matter which settled state (idle/ready/error) we're in.
	on: {
		RECENT_FILES_LOADED: { actions: 'assignRecentFiles' },
		SELECT_OBSERVATION: { actions: 'selectObservation' },
		CLOSE_OBSERVATION: { actions: 'closeObservation' }
	},
	states: {
		idle: {
			on: {
				OPEN: 'opening',
				OPEN_VOLUME: 'openingVolume',
				OPEN_ACCUMULATE: 'openingAccumulate',
				LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' },
				LOAD_VOLUME: { target: 'parsingVolume', actions: 'assignVolumePicked' },
				LOAD_ACCUMULATE: { target: 'parsingAccumulate', actions: 'assignAccumPicked' },
				OPEN_RECENT: 'reopening'
			}
		},
		opening: {
			entry: assign({ error: null }),
			invoke: {
				src: 'openFile',
				onDone: [
					{
						guard: ({ event }) => event.output.length > 0,
						actions: assign({ picked: ({ event }) => event.output }),
						target: 'parsing'
					},
					{ target: 'idle' } // picker cancelled
				],
				onError: {
					target: 'error',
					actions: assign({ error: ({ event }) => errText(event.error) })
				}
			}
		},
		openingVolume: {
			entry: assign({ error: null }),
			invoke: {
				src: 'openFiles',
				onDone: [
					{
						guard: ({ event }) => event.output.length > 0,
						actions: assign({ pickedVolume: ({ event }) => event.output }),
						target: 'parsingVolume'
					},
					{ target: 'idle' } // picker cancelled
				],
				onError: {
					target: 'error',
					actions: assign({ error: ({ event }) => errText(event.error) })
				}
			}
		},
		openingAccumulate: {
			entry: assign({ error: null }),
			invoke: {
				src: 'openFiles',
				onDone: [
					{
						guard: ({ event }) => event.output.length > 0,
						actions: assign({ pickedAccum: ({ event }) => event.output }),
						target: 'parsingAccumulate'
					},
					{ target: 'idle' } // picker cancelled
				],
				onError: {
					target: 'error',
					actions: assign({ error: ({ event }) => errText(event.error) })
				}
			}
		},
		reopening: {
			entry: assign({ error: null }),
			invoke: {
				src: 'resolveRecent',
				input: ({ event }) => (event as { entry: RecentFileEntry }).entry,
				onDone: {
					target: 'parsing',
					actions: assign({ picked: ({ event }) => [event.output] })
				},
				onError: {
					target: 'error',
					actions: assign({ error: ({ event }) => errText(event.error) })
				}
			}
		},
		parsing: {
			invoke: {
				src: 'parseFile',
				input: ({ context }) => context.picked as Picked[],
				onDone: {
					target: 'ready',
					actions: assign({
						observation: ({ event }) =>
							event.output.entries[event.output.entries.length - 1].observation,
						recentFiles: ({ event }) => event.output.recentFiles,
						observations: ({ context, event }) =>
							event.output.entries.reduce(
								(list, entry) =>
									upsertObservationEntry(list, {
										observation: entry.observation,
										fileName: entry.fileName
									}),
								context.observations
							),
						activeObservationId: ({ event }) =>
							event.output.entries[event.output.entries.length - 1].observation.id
					})
				},
				onError: {
					target: 'error',
					actions: assign({
						observation: null,
						error: ({ event }) => errText(event.error)
					})
				}
			}
		},
		parsingVolume: {
			invoke: {
				src: 'parseVolumeFile',
				input: ({ context }) => context.pickedVolume as Picked[],
				onDone: {
					target: 'ready',
					actions: assign({
						observation: ({ event }) => event.output.observation,
						recentFiles: ({ event }) => event.output.recentFiles,
						observations: ({ context, event }) =>
							upsertObservationEntry(context.observations, {
								observation: event.output.observation,
								fileName: context.pickedVolume?.[0]?.fileName ?? event.output.observation.id
							}),
						activeObservationId: ({ event }) => event.output.observation.id
					})
				},
				onError: {
					target: 'error',
					actions: assign({
						observation: null,
						error: ({ event }) => errText(event.error)
					})
				}
			}
		},
		parsingAccumulate: {
			invoke: {
				src: 'parseAccumulateFile',
				input: ({ context }) => context.pickedAccum as Picked[],
				onDone: {
					target: 'ready',
					actions: assign({ timeSpan: ({ event }) => event.output.timeSpan })
				},
				onError: {
					target: 'error',
					actions: assign({
						timeSpan: null,
						error: ({ event }) => errText(event.error)
					})
				}
			}
		},
		ready: {
			on: {
				OPEN: 'opening',
				OPEN_VOLUME: 'openingVolume',
				OPEN_ACCUMULATE: 'openingAccumulate',
				LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' },
				LOAD_VOLUME: { target: 'parsingVolume', actions: 'assignVolumePicked' },
				LOAD_ACCUMULATE: { target: 'parsingAccumulate', actions: 'assignAccumPicked' },
				OPEN_RECENT: 'reopening'
			}
		},
		error: {
			on: {
				OPEN: 'opening',
				OPEN_VOLUME: 'openingVolume',
				OPEN_ACCUMULATE: 'openingAccumulate',
				LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' },
				LOAD_VOLUME: { target: 'parsingVolume', actions: 'assignVolumePicked' },
				LOAD_ACCUMULATE: { target: 'parsingAccumulate', actions: 'assignAccumPicked' },
				OPEN_RECENT: 'reopening'
			}
		}
	}
});

function errText(e: unknown): string {
	return e instanceof Error ? e.message : String(e);
}
