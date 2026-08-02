import { setup, assign, fromPromise } from 'xstate';
import {
	openObservationFile,
	addRecentFile,
	reopenLocalFile,
	getRememberedFileHandle,
	type RecentFileEntry
} from '$lib/platform';
import { fetchVolumeScanBytes } from '$lib/aws-explorer/nexradS3';
import { parseObservation } from '$lib/parsers';
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

interface Ctx {
	observation: Observation | null;
	error: string | null;
	recentFiles: RecentFileEntry[];
	picked: Picked | null;
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
			| { type: 'LOAD_REMOTE'; picked: Picked }
			| { type: 'OPEN_RECENT'; entry: RecentFileEntry }
			| { type: 'RECENT_FILES_LOADED'; recentFiles: RecentFileEntry[] }
	},
	actors: {
		openFile: fromPromise(async (): Promise<Picked | null> => {
			const picked = await openObservationFile();
			return picked ? { ...picked, source: 'local' } : null;
		}),
		parseFile: fromPromise(async ({ input }: { input: Picked }) => {
			const observation = await parseObservation(input);
			const config = await addRecentFile({
				label: input.fileName,
				source: input.source,
				s3Key: input.s3Key
			});
			return { observation, recentFiles: config.recentFiles };
		}),
		resolveRecent: fromPromise(async ({ input }: { input: RecentFileEntry }) =>
			resolveRecentFile(input)
		)
	},
	actions: {
		assignRemotePicked: assign({
			error: null,
			picked: ({ event }) => (event as { picked: Picked }).picked
		}),
		assignRecentFiles: assign({
			recentFiles: ({ event }) => (event as { recentFiles: RecentFileEntry[] }).recentFiles
		})
	}
}).createMachine({
	id: 'observation',
	initial: 'idle',
	context: { observation: null, error: null, recentFiles: [], picked: null },
	// Internal (no target) so it applies from whichever state we're in without disturbing it --
	// the page sends this once on mount, after `loadConfig()` resolves.
	on: { RECENT_FILES_LOADED: { actions: 'assignRecentFiles' } },
	states: {
		idle: {
			on: {
				OPEN: 'opening',
				LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' },
				OPEN_RECENT: 'reopening'
			}
		},
		opening: {
			entry: assign({ error: null }),
			invoke: {
				src: 'openFile',
				onDone: [
					{
						guard: ({ event }) => event.output !== null,
						actions: assign({ picked: ({ event }) => event.output as Picked }),
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
		reopening: {
			entry: assign({ error: null }),
			invoke: {
				src: 'resolveRecent',
				input: ({ event }) => (event as { entry: RecentFileEntry }).entry,
				onDone: {
					target: 'parsing',
					actions: assign({ picked: ({ event }) => event.output })
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
				input: ({ context }) => context.picked as Picked,
				onDone: {
					target: 'ready',
					actions: assign({
						observation: ({ event }) => event.output.observation,
						recentFiles: ({ event }) => event.output.recentFiles
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
		ready: {
			on: {
				OPEN: 'opening',
				LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' },
				OPEN_RECENT: 'reopening'
			}
		},
		error: {
			on: {
				OPEN: 'opening',
				LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' },
				OPEN_RECENT: 'reopening'
			}
		}
	}
});

function errText(e: unknown): string {
	return e instanceof Error ? e.message : String(e);
}
