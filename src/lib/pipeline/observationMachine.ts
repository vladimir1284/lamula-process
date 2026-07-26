import { setup, assign, fromPromise } from 'xstate';
import { openObservationFile, addRecentFile } from '$lib/platform';
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
}

interface Ctx {
	observation: Observation | null;
	error: string | null;
	recentFiles: string[];
	picked: Picked | null;
}

export const observationMachine = setup({
	types: {
		context: {} as Ctx,
		events: {} as { type: 'OPEN' } | { type: 'LOAD_REMOTE'; picked: Picked }
	},
	actors: {
		openFile: fromPromise(async () => await openObservationFile()),
		parseFile: fromPromise(async ({ input }: { input: Picked }) => {
			const observation = await parseObservation(input);
			const config = await addRecentFile(input.fileName);
			return { observation, recentFiles: config.recentFiles };
		})
	},
	actions: {
		assignRemotePicked: assign({
			error: null,
			picked: ({ event }) => (event as { picked: Picked }).picked
		})
	}
}).createMachine({
	id: 'observation',
	initial: 'idle',
	context: { observation: null, error: null, recentFiles: [], picked: null },
	states: {
		idle: { on: { OPEN: 'opening', LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' } } },
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
		ready: { on: { OPEN: 'opening', LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' } } },
		error: { on: { OPEN: 'opening', LOAD_REMOTE: { target: 'parsing', actions: 'assignRemotePicked' } } }
	}
});

function errText(e: unknown): string {
	return e instanceof Error ? e.message : String(e);
}
