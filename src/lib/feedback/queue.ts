import type { FeedbackClient, SubmitResult } from './client';
import type { FeedbackSubmission } from './contract';
import {
	MAX_QUEUE,
	loadFeedbackState,
	saveFeedbackState,
	updateFeedbackState,
	type QueuedSubmission
} from './identity';

/**
 * Offline queue. This is what lamula-process has and lamula-webviewer doesn't: the webviewer is
 * a web page you only open when you have a network, this is an offline-first tool a meteorologist
 * runs on a workstation that may not reach the internet for hours. Without the queue their
 * feedback would be lost silently, which is worse than not offering the feature.
 */

export interface EnqueueResult {
	clientId: string;
	pending: number;
	/** True when the cap kicked in and the OLDEST entry was dropped. The dialog says so. */
	dropped: boolean;
}

export interface FlushResult {
	sent: number;
	/** Entries thrown away because the server will never accept them (4xx validation). */
	rejected: number;
	remaining: number;
}

function newClientId(): string {
	return crypto.randomUUID();
}

/** Keeps the id that the context builder already put in, so it matches what the server saw. */
function clientIdOf(body: FeedbackSubmission): string {
	const fromContext = body.context?.clientId;
	return typeof fromContext === 'string' && fromContext.length > 0 ? fromContext : newClientId();
}

export async function enqueue(body: FeedbackSubmission): Promise<EnqueueResult> {
	const clientId = clientIdOf(body);
	const entry: QueuedSubmission = {
		clientId,
		body: { ...body, context: { ...(body.context ?? {}), clientId } },
		queuedAt: Date.now(),
		attempts: 0
	};

	let dropped = false;
	const state = await updateFeedbackState((current) => {
		const queue = [...current.queue, entry];
		// Drop from the FRONT: the oldest message is the one most likely to be stale.
		dropped = queue.length > MAX_QUEUE;
		return { ...current, queue: queue.slice(-MAX_QUEUE) };
	});

	return { clientId, pending: state.queue.length, dropped };
}

export async function pendingCount(): Promise<number> {
	return (await loadFeedbackState()).queue.length;
}

/**
 * Drains the queue oldest first, one at a time.
 *
 * Sequential on purpose: the server allows 5 submissions per hour per `${ip}:${token}`, so firing
 * the whole queue in parallel would just turn the tail into 429s. A retryable failure stops the
 * run and leaves the rest for next time; a 4xx means the server will never take that entry, so
 * it is dropped instead of retried forever.
 */
export async function flushQueue(client: FeedbackClient): Promise<FlushResult> {
	const state = await loadFeedbackState();
	if (state.queue.length === 0) return { sent: 0, rejected: 0, remaining: 0 };

	const queue = [...state.queue];
	let sent = 0;
	let rejected = 0;

	while (queue.length > 0) {
		const entry = queue[0];
		let result: SubmitResult;
		try {
			result = await client.submit(entry.body);
		} catch {
			// The client is documented not to throw; if it ever does, treat it as retryable
			// rather than losing the message.
			break;
		}

		if (result.ok) {
			queue.shift();
			sent += 1;
			continue;
		}

		if (result.retryable) {
			entry.attempts += 1;
			entry.lastError = result.reason;
			break;
		}

		queue.shift();
		rejected += 1;
	}

	// Re-read: the user may have queued something else while this ran.
	const latest = await loadFeedbackState();
	const handled = new Set(
		state.queue.slice(0, state.queue.length - queue.length).map((e) => e.clientId)
	);
	const remainingQueue = latest.queue
		.filter((e) => !handled.has(e.clientId))
		.map((e) => {
			const attempted = queue.find((q) => q.clientId === e.clientId);
			return attempted ? { ...e, attempts: attempted.attempts, lastError: attempted.lastError } : e;
		});

	await saveFeedbackState({ ...latest, queue: remainingQueue });

	return { sent, rejected, remaining: remainingQueue.length };
}
