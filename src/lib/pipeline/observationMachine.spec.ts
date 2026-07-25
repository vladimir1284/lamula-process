import { describe, it, expect } from 'vitest';
import { createActor, fromPromise } from 'xstate';
import type { Observation } from '$lib/domain/types';
import type { OpenedFile } from '$lib/platform';
import { observationMachine } from './observationMachine';

// Mock actor return types must match the real actors' output exactly for .provide().
type OpenOut = OpenedFile | null;
type ParseOut = { observation: Observation; recentFiles: string[] };

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
				openFile: fromPromise(async (): Promise<OpenOut> => ({
					fileName: 'a.vol',
					bytes: new Uint8Array()
				})),
				parseFile: fromPromise(async (): Promise<ParseOut> => ({
					observation: fakeObs,
					recentFiles: ['a.vol']
				}))
			}
		});
		const actor = createActor(machine).start();
		actor.send({ type: 'OPEN' });
		await waitFor(actor, 'ready');
		expect(actor.getSnapshot().context.observation?.id).toBe('obs');
		expect(actor.getSnapshot().context.recentFiles).toEqual(['a.vol']);
	});

	it('returns to idle when the picker is cancelled', async () => {
		const machine = observationMachine.provide({
			actors: {
				openFile: fromPromise(async (): Promise<OpenOut> => null),
				parseFile: fromPromise(async (): Promise<ParseOut> => ({
					observation: fakeObs,
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
				openFile: fromPromise(async (): Promise<OpenOut> => ({
					fileName: 'bad',
					bytes: new Uint8Array()
				})),
				parseFile: fromPromise(async (): Promise<ParseOut> => {
					throw new Error('No parser recognizes file');
				})
			}
		});
		const actor = createActor(machine).start();
		actor.send({ type: 'OPEN' });
		await waitFor(actor, 'error');
		expect(actor.getSnapshot().context.error).toBe('No parser recognizes file');
	});
});
