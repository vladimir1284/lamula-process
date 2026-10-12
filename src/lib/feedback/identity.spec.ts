import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
	FEEDBACK_STORAGE_KEY,
	MAX_QUEUE,
	STATE_VERSION,
	getFeedbackToken,
	loadFeedbackState,
	newToken,
	resetMemoryState,
	saveFeedbackState,
	saveProfile
} from './identity';

/** Minimal in-memory Storage; node has no localStorage. */
function fakeStorage(seed: Record<string, string> = {}) {
	const map = new Map(Object.entries(seed));
	return {
		getItem: (k: string) => map.get(k) ?? null,
		setItem: (k: string, v: string) => void map.set(k, v),
		removeItem: (k: string) => void map.delete(k),
		clear: () => map.clear(),
		key: (i: number) => [...map.keys()][i] ?? null,
		get length() {
			return map.size;
		}
	} as Storage;
}

function install(storage: Storage | undefined) {
	resetMemoryState();
	vi.stubGlobal('localStorage', storage);
}

afterEach(() => {
	vi.unstubAllGlobals();
	resetMemoryState();
});

describe('token de identidad', () => {
	beforeEach(() => install(fakeStorage()));

	it('son 32 bytes en hex', () => {
		expect(newToken()).toMatch(/^[0-9a-f]{64}$/);
		expect(newToken()).not.toBe(newToken());
	});

	it('es estable entre cargas', async () => {
		const first = await getFeedbackToken();
		expect(await getFeedbackToken()).toBe(first);
		expect((await loadFeedbackState()).token).toBe(first);
	});
});

describe('lectura defensiva del estado guardado', () => {
	it('JSON corrupto cae a un estado por defecto usable', async () => {
		install(fakeStorage({ [FEEDBACK_STORAGE_KEY]: '{no json' }));
		const state = await loadFeedbackState();
		expect(state.token).toMatch(/^[0-9a-f]{64}$/);
		expect(state.queue).toEqual([]);
		expect(state.nudge.shownCount).toBe(0);
	});

	// Perder el token huérfana el hilo del usuario en el servidor: no se puede recuperar.
	it('una versión desconocida descarta la forma pero CONSERVA el token', async () => {
		const token = 'f'.repeat(64);
		install(
			fakeStorage({
				[FEEDBACK_STORAGE_KEY]: JSON.stringify({
					v: 99,
					token,
					nudge: { shownCount: 3, dismissedForever: true },
					queue: [{ clientId: 'x', body: { message: 'hola' }, queuedAt: 1 }]
				})
			})
		);

		const state = await loadFeedbackState();
		expect(state.token).toBe(token);
		expect(state.v).toBe(STATE_VERSION);
		expect(state.nudge.shownCount).toBe(0);
		expect(state.queue).toEqual([]);
	});

	it('descarta entradas de cola con forma inválida y respeta el tope', async () => {
		const good = (i: number) => ({
			clientId: `c${i}`,
			body: { app: 'process', kind: 'bug', message: `m${i}`, role: 'otro' },
			queuedAt: i,
			attempts: 0
		});
		install(
			fakeStorage({
				[FEEDBACK_STORAGE_KEY]: JSON.stringify({
					v: STATE_VERSION,
					token: 'a'.repeat(64),
					queue: [...Array.from({ length: MAX_QUEUE + 5 }, (_, i) => good(i)), { junk: true }, null]
				})
			})
		);

		const state = await loadFeedbackState();
		expect(state.queue).toHaveLength(MAX_QUEUE);
		// Se queda con las MÁS NUEVAS.
		expect(state.queue[state.queue.length - 1].clientId).toBe(`c${MAX_QUEUE + 4}`);
	});

	it('un token demasiado corto se reemplaza', async () => {
		install(fakeStorage({ [FEEDBACK_STORAGE_KEY]: JSON.stringify({ v: 1, token: 'ab' }) }));
		expect((await loadFeedbackState()).token).toMatch(/^[0-9a-f]{64}$/);
	});

	it('un perfil sin ocupación no se conserva', async () => {
		install(
			fakeStorage({
				[FEEDBACK_STORAGE_KEY]: JSON.stringify({
					v: STATE_VERSION,
					token: 'a'.repeat(64),
					profile: { displayName: 'Pepe' }
				})
			})
		);
		expect((await loadFeedbackState()).profile).toBeNull();
	});
});

describe('sin almacenamiento utilizable', () => {
	it('sigue funcionando en memoria cuando no hay localStorage', async () => {
		install(undefined);
		const token = await getFeedbackToken();
		expect(token).toMatch(/^[0-9a-f]{64}$/);
		await saveProfile({ role: 'estudiante' });
		expect((await loadFeedbackState()).profile).toEqual({ role: 'estudiante' });
		expect((await loadFeedbackState()).token).toBe(token);
	});

	it('un setItem que lanza no rompe el envío', async () => {
		const throwing = {
			...fakeStorage(),
			setItem: () => {
				throw new Error('QuotaExceededError');
			}
		} as unknown as Storage;
		install(throwing);

		const state = await loadFeedbackState();
		await expect(
			saveFeedbackState({ ...state, profile: { role: 'profesor' } })
		).resolves.toBeUndefined();
		expect((await loadFeedbackState()).profile).toEqual({ role: 'profesor' });
	});
});
