import { describe, it, expect } from 'vitest';
import { createActor, fromPromise } from 'xstate';
import type { Observation } from '$lib/domain/types';
import type { OpenedFile, RecentFileEntry } from '$lib/platform';
import { observationMachine } from './observationMachine';

// Mock actor return types must match the real actors' output exactly for .provide().
type OpenOut = (OpenedFile & { source: 'local' | 'aws'; s3Key?: string })[];
// parseFile now parses each picked file into its own independent entry (see observationMachine.ts).
type ParseFileOut = {
	entries: { observation: Observation; fileName: string }[];
	recentFiles: RecentFileEntry[];
};
// parseVolumeFile/parseAccumulateFile still merge, unlike parseFile above.
type ParseOut = { observation: Observation; recentFiles: RecentFileEntry[] };
type ResolveOut = { fileName: string; bytes: Uint8Array; source: 'local' | 'aws'; s3Key?: string };

const fakeObs: Observation = {
	id: 'obs',
	site: { name: 'X', code: 'X', lon: -77.85, lat: 21.42 },
	timestamp: '2020-01-01T00:00:00Z',
	design: 'VCP',
	movements: []
};

/** Resolve once the running actor reaches a state matching `value`. */
function waitFor(actor: ReturnType<typeof createActor>, value: string): Promise<void> {
	return new Promise((resolve) => {
		const sub = actor.subscribe((snap) => {
			if (snap.matches(value)) {
				sub.unsubscribe();
				resolve();
			}
		});
	});
}

describe('observationMachine', () => {
	it('open -> parse -> ready stores the observation', async () => {
		const machine = observationMachine.provide({
			actors: {
				openFile: fromPromise(async (): Promise<OpenOut> => [
					{ fileName: 'a.vol', bytes: new Uint8Array(), source: 'local' }
				]),
				parseFile: fromPromise(async (): Promise<ParseFileOut> => ({
					entries: [{ observation: fakeObs, fileName: 'a.vol' }],
					recentFiles: [{ label: 'a.vol', source: 'local' }]
				}))
			}
		});
		const actor = createActor(machine).start();
		actor.send({ type: 'OPEN' });
		await waitFor(actor, 'ready');
		expect(actor.getSnapshot().context.observation?.id).toBe('obs');
		expect(actor.getSnapshot().context.recentFiles).toEqual([{ label: 'a.vol', source: 'local' }]);
	});

	it('returns to idle when the picker is cancelled', async () => {
		const machine = observationMachine.provide({
			actors: {
				openFile: fromPromise(async (): Promise<OpenOut> => []),
				parseFile: fromPromise(async (): Promise<ParseFileOut> => ({
					entries: [{ observation: fakeObs, fileName: 'a.vol' }],
					recentFiles: []
				}))
			}
		});
		const actor = createActor(machine).start();
		expect(actor.getSnapshot().value).toBe('idle');
		actor.send({ type: 'OPEN' });
		expect(actor.getSnapshot().value).toBe('opening'); // synchronous transition
		// let the (null-returning) picker actor resolve, then confirm we fell back to idle
		await new Promise((r) => setTimeout(r, 10));
		expect(actor.getSnapshot().value).toBe('idle');
		expect(actor.getSnapshot().context.observation).toBeNull();
	});

	it('captures a parse error', async () => {
		const machine = observationMachine.provide({
			actors: {
				openFile: fromPromise(async (): Promise<OpenOut> => [
					{ fileName: 'bad', bytes: new Uint8Array(), source: 'local' }
				]),
				parseFile: fromPromise(async (): Promise<ParseFileOut> => {
					throw new Error('No parser recognizes file');
				})
			}
		});
		const actor = createActor(machine).start();
		actor.send({ type: 'OPEN' });
		await waitFor(actor, 'error');
		expect(actor.getSnapshot().context.error).toBe('No parser recognizes file');
	});

	it('OPEN_RECENT reopens a recent entry and lands in ready', async () => {
		const machine = observationMachine.provide({
			actors: {
				resolveRecent: fromPromise(async (): Promise<ResolveOut> => ({
					fileName: 'a.vol',
					bytes: new Uint8Array(),
					source: 'local'
				})),
				parseFile: fromPromise(async (): Promise<ParseFileOut> => ({
					entries: [{ observation: fakeObs, fileName: 'a.vol' }],
					recentFiles: [{ label: 'a.vol', source: 'local' }]
				}))
			}
		});
		const actor = createActor(machine).start();
		actor.send({ type: 'OPEN_RECENT', entry: { label: 'a.vol', source: 'local' } });
		expect(actor.getSnapshot().value).toBe('reopening'); // synchronous transition
		await waitFor(actor, 'ready');
		expect(actor.getSnapshot().context.observation?.id).toBe('obs');
	});

	it('OPEN_RECENT captures an error when the entry cannot be resolved (e.g. handle lost on reload)', async () => {
		const machine = observationMachine.provide({
			actors: {
				resolveRecent: fromPromise(async (): Promise<ResolveOut> => {
					throw new Error('No se pudo reabrir "a.vol" automáticamente -- usa "Abrir archivo".');
				})
			}
		});
		const actor = createActor(machine).start();
		actor.send({ type: 'OPEN_RECENT', entry: { label: 'a.vol', source: 'local' } });
		await waitFor(actor, 'error');
		expect(actor.getSnapshot().context.error).toMatch(/no se pudo reabrir/i);
	});

	it('LOAD_VOLUME parses+merges multiple picked files and lands in ready', async () => {
		const machine = observationMachine.provide({
			actors: {
				parseVolumeFile: fromPromise(async (): Promise<ParseOut> => ({
					observation: fakeObs,
					recentFiles: [{ label: 'sweep0.RAW0001', source: 'aws' }]
				}))
			}
		});
		const actor = createActor(machine).start();
		actor.send({
			type: 'LOAD_VOLUME',
			picked: [
				{ fileName: 'sweep0.RAW0001', bytes: new Uint8Array(), source: 'aws' as const },
				{ fileName: 'sweep1.RAW0002', bytes: new Uint8Array(), source: 'aws' as const }
			]
		});
		expect(actor.getSnapshot().value).toBe('parsingVolume'); // synchronous transition
		await waitFor(actor, 'ready');
		expect(actor.getSnapshot().context.observation?.id).toBe('obs');
		expect(actor.getSnapshot().context.recentFiles).toEqual([
			{ label: 'sweep0.RAW0001', source: 'aws' }
		]);
	});

	it('LOAD_VOLUME captures an error when merging/parsing fails', async () => {
		const machine = observationMachine.provide({
			actors: {
				parseVolumeFile: fromPromise(async (): Promise<ParseOut> => {
					throw new Error('mergeSweeps: no valid single-sweep observations for a shared site');
				})
			}
		});
		const actor = createActor(machine).start();
		actor.send({
			type: 'LOAD_VOLUME',
			picked: [{ fileName: 'sweep0.RAW0001', bytes: new Uint8Array(), source: 'aws' as const }]
		});
		await waitFor(actor, 'error');
		expect(actor.getSnapshot().context.error).toMatch(/mergeSweeps/);
	});

	it('LOAD_ACCUMULATE parses multiple picked files into a TimeSpan, leaving observation untouched', async () => {
		const machine = observationMachine.provide({
			actors: {
				parseAccumulateFile: fromPromise(
					async (): Promise<{ timeSpan: { observations: Observation[] } }> => ({
						timeSpan: { observations: [fakeObs] }
					})
				)
			}
		});
		const actor = createActor(machine).start();
		actor.send({
			type: 'LOAD_ACCUMULATE',
			picked: [
				{ fileName: 'a.obs', bytes: new Uint8Array(), source: 'local' as const },
				{ fileName: 'b.obs', bytes: new Uint8Array(), source: 'local' as const }
			]
		});
		expect(actor.getSnapshot().value).toBe('parsingAccumulate'); // synchronous transition
		await waitFor(actor, 'ready');
		expect(actor.getSnapshot().context.timeSpan?.observations).toEqual([fakeObs]);
		expect(actor.getSnapshot().context.observation).toBeNull();
	});

	it('LOAD_ACCUMULATE captures an error and leaves timeSpan null', async () => {
		const machine = observationMachine.provide({
			actors: {
				parseAccumulateFile: fromPromise(
					async (): Promise<{ timeSpan: { observations: Observation[] } }> => {
						throw new Error('createTimeSpan: nothing to merge');
					}
				)
			}
		});
		const actor = createActor(machine).start();
		actor.send({
			type: 'LOAD_ACCUMULATE',
			picked: [{ fileName: 'a.obs', bytes: new Uint8Array(), source: 'local' as const }]
		});
		await waitFor(actor, 'error');
		expect(actor.getSnapshot().context.error).toMatch(/createTimeSpan/);
		expect(actor.getSnapshot().context.timeSpan).toBeNull();
	});

	it('RECENT_FILES_LOADED hydrates recentFiles without disturbing the current state', async () => {
		const actor = createActor(observationMachine).start();
		actor.send({
			type: 'RECENT_FILES_LOADED',
			recentFiles: [{ label: 'a.vol', source: 'local' }]
		});
		expect(actor.getSnapshot().value).toBe('idle');
		expect(actor.getSnapshot().context.recentFiles).toEqual([{ label: 'a.vol', source: 'local' }]);
	});
});
