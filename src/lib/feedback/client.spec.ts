import { describe, expect, it, vi } from 'vitest';
import { createFeedbackClient } from './client';
import { THIS_APP, type FeedbackSubmission } from './contract';

const BASE = 'https://webviewer.ladetec.com/api';
const TOKEN = 'a'.repeat(64);

const BODY: FeedbackSubmission = {
	app: THIS_APP,
	kind: 'bug',
	message: 'El RHI se ve cortado.',
	role: 'meteorologo'
};

function jsonResponse(status: number, payload: unknown): Response {
	return new Response(JSON.stringify(payload), {
		status,
		headers: { 'content-type': 'application/json' }
	});
}

function clientWith(fetchImpl: typeof fetch, baseUrl = BASE) {
	return createFeedbackClient({ baseUrl, token: TOKEN, fetchImpl });
}

describe('createFeedbackClient.submit', () => {
	it('hace POST a /feedback con la cabecera de identidad', async () => {
		const fetchImpl = vi.fn(async () => jsonResponse(201, { id: '42' })) as unknown as typeof fetch;
		const result = await clientWith(fetchImpl).submit(BODY);

		expect(result).toEqual({ ok: true, id: '42' });

		const [url, init] = vi.mocked(fetchImpl).mock.calls[0] as [string, RequestInit];
		expect(url).toBe(`${BASE}/feedback`);
		expect(init.method).toBe('POST');
		expect((init.headers as Record<string, string>)['x-feedback-token']).toBe(TOKEN);
		expect((init.headers as Record<string, string>)['content-type']).toBe('application/json');
		expect(JSON.parse(init.body as string)).toEqual(BODY);
	});

	it('normaliza la barra final de la base', async () => {
		const fetchImpl = vi.fn(async () => jsonResponse(201, { id: '1' })) as unknown as typeof fetch;
		await clientWith(fetchImpl, `${BASE}/`).submit(BODY);
		expect(vi.mocked(fetchImpl).mock.calls[0][0]).toBe(`${BASE}/feedback`);
	});

	it('con base vacía no llama a la red y marca reintentable', async () => {
		const fetchImpl = vi.fn() as unknown as typeof fetch;
		const result = await clientWith(fetchImpl, '').submit(BODY);

		expect(result).toEqual({ ok: false, retryable: true, reason: 'offline' });
		expect(fetchImpl).not.toHaveBeenCalled();
	});

	it('trata red caída y CORS como reintentables', async () => {
		// Un rechazo de CORS llega como TypeError opaco, igual que la red caída.
		const fetchImpl = vi.fn(async () => {
			throw new TypeError('Failed to fetch');
		}) as unknown as typeof fetch;

		expect(await clientWith(fetchImpl).submit(BODY)).toEqual({
			ok: false,
			retryable: true,
			reason: 'offline'
		});
	});

	it('distingue el timeout', async () => {
		const fetchImpl = vi.fn(async () => {
			const err = new Error('timed out');
			err.name = 'TimeoutError';
			throw err;
		}) as unknown as typeof fetch;

		expect(await clientWith(fetchImpl).submit(BODY)).toEqual({
			ok: false,
			retryable: true,
			reason: 'timeout'
		});
	});

	it('429 y 5xx son reintentables; el 4xx de validación no', async () => {
		const rate = vi.fn(async () => jsonResponse(429, {})) as unknown as typeof fetch;
		expect(await clientWith(rate).submit(BODY)).toEqual({
			ok: false,
			retryable: true,
			reason: 'rateLimited'
		});

		const boom = vi.fn(async () => jsonResponse(503, {})) as unknown as typeof fetch;
		expect(await clientWith(boom).submit(BODY)).toEqual({
			ok: false,
			retryable: true,
			reason: 'server'
		});

		const bad = vi.fn(async () =>
			jsonResponse(400, { statusMessage: 'message: El mensaje no puede estar vacío' })
		) as unknown as typeof fetch;
		expect(await clientWith(bad).submit(BODY)).toEqual({
			ok: false,
			retryable: false,
			status: 400,
			serverMessage: 'message: El mensaje no puede estar vacío'
		});
	});

	it('un 201 con cuerpo ilegible sigue siendo un envío hecho', async () => {
		const fetchImpl = vi.fn(
			async () => new Response('no json', { status: 201 })
		) as unknown as typeof fetch;
		expect(await clientWith(fetchImpl).submit(BODY)).toEqual({ ok: true, id: '' });
	});

	it('aborta cuando el timeout vence', async () => {
		const fetchImpl = vi.fn(
			(_url: string, init: RequestInit) =>
				new Promise<Response>((_resolve, reject) => {
					init.signal?.addEventListener('abort', () => reject(init.signal?.reason));
				})
		) as unknown as typeof fetch;

		const client = createFeedbackClient({ baseUrl: BASE, token: TOKEN, fetchImpl, timeoutMs: 5 });
		const result = await client.submit(BODY);
		expect(result).toEqual({ ok: false, retryable: true, reason: 'timeout' });
	});

	it('respeta el AbortSignal de quien llama', async () => {
		const fetchImpl = vi.fn(
			(_url: string, init: RequestInit) =>
				new Promise<Response>((_resolve, reject) => {
					init.signal?.addEventListener('abort', () => reject(new TypeError('aborted')));
				})
		) as unknown as typeof fetch;

		const controller = new AbortController();
		const promise = clientWith(fetchImpl).submit(BODY, controller.signal);
		controller.abort();

		expect(await promise).toEqual({ ok: false, retryable: true, reason: 'offline' });
	});
});

describe('createFeedbackClient.listMine / markRepliesRead', () => {
	it('devuelve el hilo', async () => {
		const items = [{ id: '1', kind: 'bug', message: 'x', status: 'nuevo', replies: [] }];
		const fetchImpl = vi.fn(async () => jsonResponse(200, items)) as unknown as typeof fetch;

		const result = await clientWith(fetchImpl).listMine();
		expect(result).toEqual({ ok: true, items });
		expect(vi.mocked(fetchImpl).mock.calls[0][0]).toBe(`${BASE}/feedback/mine`);
	});

	it('un cuerpo que no es lista no revienta la UI', async () => {
		const fetchImpl = vi.fn(async () =>
			jsonResponse(200, { oops: true })
		) as unknown as typeof fetch;
		expect(await clientWith(fetchImpl).listMine()).toEqual({ ok: true, items: [] });
	});

	it('cualquier fallo al listar es reintentable, nunca una excepción', async () => {
		const fetchImpl = vi.fn(async () => {
			throw new TypeError('Failed to fetch');
		}) as unknown as typeof fetch;
		expect(await clientWith(fetchImpl).listMine()).toEqual({ ok: false, retryable: true });
	});

	it('marcar como leído es best-effort', async () => {
		const ok = vi.fn(async () => jsonResponse(200, { ok: true })) as unknown as typeof fetch;
		expect(await clientWith(ok).markRepliesRead()).toBe(true);
		expect(vi.mocked(ok).mock.calls[0][0]).toBe(`${BASE}/feedback/mine/read`);

		const down = vi.fn(async () => {
			throw new TypeError('Failed to fetch');
		}) as unknown as typeof fetch;
		expect(await clientWith(down).markRepliesRead()).toBe(false);
	});
});
