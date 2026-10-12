import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { FeedbackClient, SubmitResult } from './client';
import type { FeedbackSubmission } from './contract';
import { loadFeedbackState, MAX_QUEUE, resetMemoryState } from './identity';
import { enqueue, flushQueue, pendingCount } from './queue';

function body(message: string, context?: Record<string, unknown>): FeedbackSubmission {
	return { app: 'process', kind: 'bug', message, role: 'meteorologo', context };
}

/** Client stub: hands back a scripted result per call, defaulting to success. */
function stubClient(
	results: SubmitResult[] = []
): FeedbackClient & { calls: FeedbackSubmission[] } {
	const calls: FeedbackSubmission[] = [];
	return {
		calls,
		submit: vi.fn(async (b: FeedbackSubmission) => {
			calls.push(b);
			return results.shift() ?? ({ ok: true, id: String(calls.length) } as SubmitResult);
		}),
		listMine: vi.fn(async () => ({ ok: true as const, items: [] })),
		markRepliesRead: vi.fn(async () => true)
	};
}

beforeEach(() => {
	resetMemoryState();
	vi.stubGlobal('localStorage', undefined);
});

afterEach(() => {
	vi.unstubAllGlobals();
	resetMemoryState();
});

describe('enqueue', () => {
	it('guarda el envío y le pone un clientId', async () => {
		const result = await enqueue(body('sin internet'));
		expect(result.pending).toBe(1);
		expect(result.dropped).toBe(false);
		expect(result.clientId).toMatch(/[0-9a-f-]{36}/);

		const [entry] = (await loadFeedbackState()).queue;
		expect(entry.body.context?.clientId).toBe(result.clientId);
	});

	it('respeta el clientId que ya venía en el contexto', async () => {
		const result = await enqueue(body('x', { clientId: 'ya-existente', platform: 'web' }));
		expect(result.clientId).toBe('ya-existente');
		const [entry] = (await loadFeedbackState()).queue;
		expect(entry.body.context).toEqual({ clientId: 'ya-existente', platform: 'web' });
	});

	it('al llenarse descarta la MÁS VIEJA y avisa', async () => {
		for (let i = 0; i < MAX_QUEUE; i++) {
			expect((await enqueue(body(`m${i}`))).dropped).toBe(false);
		}
		const overflow = await enqueue(body('la que desborda'));

		expect(overflow.dropped).toBe(true);
		expect(overflow.pending).toBe(MAX_QUEUE);

		const queue = (await loadFeedbackState()).queue;
		expect(queue[0].body.message).toBe('m1');
		expect(queue[queue.length - 1].body.message).toBe('la que desborda');
	});
});

describe('flushQueue', () => {
	it('con la cola vacía no llama a la red', async () => {
		const client = stubClient();
		expect(await flushQueue(client)).toEqual({ sent: 0, rejected: 0, remaining: 0 });
		expect(client.submit).not.toHaveBeenCalled();
	});

	it('vacía la cola en orden y secuencialmente', async () => {
		await enqueue(body('primero'));
		await enqueue(body('segundo'));

		const client = stubClient();
		expect(await flushQueue(client)).toEqual({ sent: 2, rejected: 0, remaining: 0 });
		expect(client.calls.map((c) => c.message)).toEqual(['primero', 'segundo']);
		expect(await pendingCount()).toBe(0);
	});

	// El límite del servidor es 5/h por `${ip}:${token}`: seguir tras un 429 solo gana más 429.
	it('se detiene en el primer fallo reintentable y conserva el resto', async () => {
		await enqueue(body('primero'));
		await enqueue(body('segundo'));
		await enqueue(body('tercero'));

		const client = stubClient([
			{ ok: true, id: '1' },
			{ ok: false, retryable: true, reason: 'rateLimited' }
		]);

		expect(await flushQueue(client)).toEqual({ sent: 1, rejected: 0, remaining: 2 });
		expect(client.submit).toHaveBeenCalledTimes(2);

		const queue = (await loadFeedbackState()).queue;
		expect(queue.map((e) => e.body.message)).toEqual(['segundo', 'tercero']);
		expect(queue[0].attempts).toBe(1);
		expect(queue[0].lastError).toBe('rateLimited');
	});

	it('un 4xx de validación se descarta en vez de reintentarse para siempre', async () => {
		await enqueue(body('invalido'));
		await enqueue(body('bueno'));

		const client = stubClient([
			{ ok: false, retryable: false, status: 400, serverMessage: 'message: vacío' }
		]);

		expect(await flushQueue(client)).toEqual({ sent: 1, rejected: 1, remaining: 0 });
		expect(await pendingCount()).toBe(0);
	});

	// Dos flush seguidos (arranque + evento 'online') no deben mandar lo mismo dos veces.
	it('reintentar no duplica lo ya enviado', async () => {
		await enqueue(body('uno'));
		const client = stubClient();

		await flushQueue(client);
		await flushQueue(client);

		expect(client.submit).toHaveBeenCalledTimes(1);
		expect(await pendingCount()).toBe(0);
	});

	it('lo encolado durante el flush no se pierde', async () => {
		await enqueue(body('viejo'));

		const client = stubClient();
		vi.mocked(client.submit).mockImplementationOnce(async () => {
			await enqueue(body('llegó mientras enviaba'));
			return { ok: true, id: '1' };
		});

		const result = await flushQueue(client);
		expect(result.sent).toBe(1);
		expect(result.remaining).toBe(1);
		expect((await loadFeedbackState()).queue[0].body.message).toBe('llegó mientras enviaba');
	});

	it('si el cliente lanza (no debería), el mensaje no se pierde', async () => {
		await enqueue(body('frágil'));
		const client = stubClient();
		vi.mocked(client.submit).mockRejectedValueOnce(new Error('boom'));

		expect(await flushQueue(client)).toEqual({ sent: 0, rejected: 0, remaining: 1 });
		expect(await pendingCount()).toBe(1);
	});
});
