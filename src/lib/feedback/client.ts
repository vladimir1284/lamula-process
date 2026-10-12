import type { FeedbackSubmission, FeedbackThreadItem } from './contract';
import { feedbackApiBase } from './env';

/**
 * HTTP client for the shared feedback inbox hosted by lamula-webviewer.
 *
 * Rule of the whole module: a submission NEVER throws towards the UI. Everything that can be
 * retried later (network down, CORS, timeout, 5xx, 429) comes back as `retryable: true` and the
 * caller queues it. Only a 4xx that means "what you typed is wrong" is shown to the user, and
 * that one is never queued -- retrying it would fail forever.
 *
 * This repo had no HTTP helper (src/lib/aws-explorer/s3ListObjects.ts uses bare `fetch`), so the
 * timeout lives here.
 */

export const DEFAULT_TIMEOUT_MS = 8000;

export interface FeedbackClientOptions {
	/** Defaults to the build-time value; injected in tests. */
	baseUrl?: string;
	/** Identity token; travels in `x-feedback-token`. */
	token: string;
	fetchImpl?: typeof fetch;
	timeoutMs?: number;
}

export type SubmitResult =
	| { ok: true; id: string }
	| { ok: false; retryable: true; reason: 'offline' | 'timeout' | 'server' | 'rateLimited' }
	| { ok: false; retryable: false; status: number; serverMessage: string };

export type ListResult = { ok: true; items: FeedbackThreadItem[] } | { ok: false; retryable: true };

export interface FeedbackClient {
	submit(body: FeedbackSubmission, signal?: AbortSignal): Promise<SubmitResult>;
	listMine(signal?: AbortSignal): Promise<ListResult>;
	markRepliesRead(signal?: AbortSignal): Promise<boolean>;
}

/** `AbortSignal.any` keeps the caller's own cancellation working alongside the timeout. */
function withTimeout(timeoutMs: number, signal?: AbortSignal): AbortSignal {
	const timeout = AbortSignal.timeout(timeoutMs);
	return signal ? AbortSignal.any([signal, timeout]) : timeout;
}

/** Nitro reports validation failures in `statusMessage`; it is raw server text, never translated. */
async function readServerMessage(res: Response): Promise<string> {
	try {
		const body = (await res.json()) as { statusMessage?: string; message?: string };
		return body.statusMessage ?? body.message ?? `HTTP ${res.status}`;
	} catch {
		return `HTTP ${res.status}`;
	}
}

export function createFeedbackClient(options: FeedbackClientOptions): FeedbackClient {
	const baseUrl = (options.baseUrl ?? feedbackApiBase()).replace(/\/+$/, '');
	const doFetch = options.fetchImpl ?? globalThis.fetch;
	const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;

	const headers = {
		'content-type': 'application/json',
		'x-feedback-token': options.token
	};

	async function submit(body: FeedbackSubmission, signal?: AbortSignal): Promise<SubmitResult> {
		if (!baseUrl) return { ok: false, retryable: true, reason: 'offline' };

		let res: Response;
		try {
			res = await doFetch(`${baseUrl}/feedback`, {
				method: 'POST',
				headers,
				body: JSON.stringify(body),
				signal: withTimeout(timeoutMs, signal)
			});
		} catch (err) {
			// A CORS rejection reaches us as an opaque TypeError, indistinguishable from the
			// network being down. Both are retryable, so the distinction doesn't matter here.
			const timedOut = err instanceof Error && err.name === 'TimeoutError';
			return { ok: false, retryable: true, reason: timedOut ? 'timeout' : 'offline' };
		}

		if (res.ok) {
			try {
				const payload = (await res.json()) as { id?: string };
				return { ok: true, id: payload.id ?? '' };
			} catch {
				// It was accepted; a body we can't parse doesn't make it un-sent.
				return { ok: true, id: '' };
			}
		}

		if (res.status === 429) return { ok: false, retryable: true, reason: 'rateLimited' };
		if (res.status >= 500) return { ok: false, retryable: true, reason: 'server' };

		return {
			ok: false,
			retryable: false,
			status: res.status,
			serverMessage: await readServerMessage(res)
		};
	}

	async function listMine(signal?: AbortSignal): Promise<ListResult> {
		if (!baseUrl) return { ok: false, retryable: true };

		try {
			const res = await doFetch(`${baseUrl}/feedback/mine`, {
				headers,
				signal: withTimeout(timeoutMs, signal)
			});
			if (!res.ok) return { ok: false, retryable: true };
			const items = (await res.json()) as FeedbackThreadItem[];
			return { ok: true, items: Array.isArray(items) ? items : [] };
		} catch {
			return { ok: false, retryable: true };
		}
	}

	/** Best-effort: failing to clear the dot is not worth bothering the user about. */
	async function markRepliesRead(signal?: AbortSignal): Promise<boolean> {
		if (!baseUrl) return false;

		try {
			const res = await doFetch(`${baseUrl}/feedback/mine/read`, {
				method: 'POST',
				headers,
				body: '{}',
				signal: withTimeout(timeoutMs, signal)
			});
			return res.ok;
		} catch {
			return false;
		}
	}

	return { submit, listMine, markRepliesRead };
}
