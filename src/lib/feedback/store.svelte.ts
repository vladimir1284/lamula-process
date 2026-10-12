import { createFeedbackClient, type FeedbackClient } from './client';
import { buildContext, type FeedbackContextInput } from './context';
import type {
	FeedbackKind,
	FeedbackProfile,
	FeedbackRole,
	FeedbackSubmission,
	FeedbackThreadItem
} from './contract';
import { THIS_APP, validateSubmission } from './contract';
import { isFeedbackEnabled } from './env';
import {
	getFeedbackToken,
	loadFeedbackState,
	saveProfile,
	updateFeedbackState,
	type NudgeState
} from './identity';
import {
	dismissNudgeForever,
	markFeedbackSubmitted,
	markNudgeShown,
	shouldShowNudge,
	snoozeNudge
} from './nudge';
import { enqueue, flushQueue, pendingCount } from './queue';

/**
 * Runes-module singleton that wires the pure feedback modules to the UI, the same shape as
 * `windows/windowStore.svelte.ts`: every consumer imports this directly instead of relaying
 * state through `+page.svelte` props.
 *
 * Everything that can be decided without a DOM already lives in contract/nudge/queue/context and
 * is unit-tested there. What is left here is orchestration and view state.
 */

export type SendState = 'idle' | 'sending' | 'sent' | 'queued' | 'error';
export type DialogTab = 'send' | 'mine';

/** The page owns the app state, so it hands over a snapshot builder instead of being read. */
export type ContextProvider = () => FeedbackContextInput;

class FeedbackStore {
	readonly enabled = isFeedbackEnabled();

	dialogOpen = $state(false);
	dialogTab = $state<DialogTab>('send');
	nudgeVisible = $state(false);

	profile = $state<FeedbackProfile | null>(null);
	pending = $state(0);
	queueDropped = $state(false);

	thread = $state<FeedbackThreadItem[]>([]);
	threadLoading = $state(false);
	threadFailed = $state(false);

	sendState = $state<SendState>('idle');
	/** i18n keys from `validateSubmission`. */
	formErrors = $state<string[]>([]);
	/** Raw server text; shown as-is, never translated (repo-wide criterion). */
	serverMessage = $state<string | null>(null);

	unreadReplies = $derived(
		this.thread.reduce(
			(total, item) => total + item.replies.filter((reply) => !reply.readAt).length,
			0
		)
	);

	private client: FeedbackClient | null = null;
	private nudge: NudgeState | null = null;
	private bootedAt = Date.now();
	private shownThisSession = false;
	private productWindowClosed = false;
	private contextProvider: ContextProvider = () => ({});

	setContextProvider(provider: ContextProvider): void {
		this.contextProvider = provider;
	}

	/** Called once on mount. Everything here is best-effort: it must never block the app. */
	async init(): Promise<void> {
		if (!this.enabled) return;

		const token = await getFeedbackToken();
		this.client = createFeedbackClient({ token });

		const state = await loadFeedbackState();
		this.profile = state.profile;
		this.nudge = state.nudge;
		this.pending = state.queue.length;

		await this.flush();

		// Only ask the server for a thread if this browser has ever written to us. Someone who
		// never sent feedback has nothing to read, and would be paying a request on every boot.
		if (state.nudge.submitted || state.queue.length > 0) {
			void this.refreshThread();
		}

		if (typeof window !== 'undefined') {
			window.addEventListener('online', () => void this.flush());
		}
	}

	/** The nudge fires on closing a product window, not on session time -- see nudge.ts. */
	async onProductWindowClosed(): Promise<void> {
		this.productWindowClosed = true;
		// Evaluated on EVERY close, not just the first: if the first one happened inside the
		// 60 s floor, the nudge would otherwise never get a second chance this session.
		await this.evaluateNudge();
	}

	async evaluateNudge(): Promise<void> {
		if (!this.enabled || !this.nudge || this.dialogOpen) return;

		const show = shouldShowNudge({
			state: this.nudge,
			now: Date.now(),
			bootedAt: this.bootedAt,
			productWindowClosed: this.productWindowClosed,
			shownThisSession: this.shownThisSession
		});
		if (!show) return;

		this.shownThisSession = true;
		this.nudgeVisible = true;
		await this.mutateNudge(markNudgeShown);
	}

	acceptNudge(): void {
		this.nudgeVisible = false;
		this.openDialog('send');
	}

	async snoozeNudge(): Promise<void> {
		this.nudgeVisible = false;
		await this.mutateNudge((state) => snoozeNudge(state, Date.now()));
	}

	async dismissNudge(): Promise<void> {
		this.nudgeVisible = false;
		await this.mutateNudge(dismissNudgeForever);
	}

	openDialog(tab: DialogTab = 'send'): void {
		if (!this.enabled) return;
		this.dialogTab = tab;
		this.dialogOpen = true;
		this.nudgeVisible = false;
		this.sendState = 'idle';
		this.formErrors = [];
		this.serverMessage = null;
		void this.flush();
		if (tab === 'mine') void this.refreshThread();
	}

	closeDialog(): void {
		this.dialogOpen = false;
		this.queueDropped = false;
	}

	async refreshThread(): Promise<void> {
		if (!this.client) return;
		this.threadLoading = true;
		this.threadFailed = false;

		const result = await this.client.listMine();
		if (result.ok) {
			this.thread = result.items;
		} else {
			this.threadFailed = true;
		}
		this.threadLoading = false;
	}

	/** Clears the status-bar dot. Best-effort: a failure here is not worth a message. */
	async markThreadRead(): Promise<void> {
		if (!this.client || this.unreadReplies === 0) return;
		const stamped = new Date().toISOString();
		if (await this.client.markRepliesRead()) {
			this.thread = this.thread.map((item) => ({
				...item,
				replies: item.replies.map((reply) => ({ ...reply, readAt: reply.readAt ?? stamped }))
			}));
		}
	}

	async flush(): Promise<void> {
		if (!this.client) return;
		const result = await flushQueue(this.client);
		this.pending = result.remaining;
		if (result.sent > 0) void this.refreshThread();
	}

	/**
	 * One submit path for the dialog. Validation errors come back as i18n keys and stop here;
	 * anything retryable is queued, so the user never loses what they wrote.
	 */
	async submit(input: {
		role: FeedbackRole;
		roleOther?: string;
		kind: FeedbackKind;
		rating?: number | null;
		message: string;
		profile?: Partial<FeedbackProfile>;
	}): Promise<void> {
		if (!this.client) return;

		const profile: FeedbackProfile = {
			role: input.role,
			roleOther: input.roleOther ?? null,
			...input.profile
		};

		const body: FeedbackSubmission = {
			app: THIS_APP,
			kind: input.kind,
			rating: input.rating ?? null,
			message: input.message.trim(),
			role: input.role,
			roleOther: input.roleOther ?? null,
			profile,
			context: buildContext(this.contextProvider())
		};

		const errors = validateSubmission(body);
		if (errors.length > 0) {
			this.formErrors = errors;
			this.sendState = 'error';
			return;
		}

		this.formErrors = [];
		this.serverMessage = null;
		this.sendState = 'sending';

		const result = await this.client.submit(body);

		// Saved whatever happened: they typed it, and the next submission should not ask again.
		await saveProfile(profile);
		this.profile = profile;

		if (!result.ok && !result.retryable) {
			// The server refused the content. Nothing was sent, so the nudge is NOT silenced.
			this.sendState = 'error';
			this.serverMessage = result.serverMessage;
			return;
		}

		await this.mutateNudge(markFeedbackSubmitted);

		if (result.ok) {
			this.sendState = 'sent';
			void this.refreshThread();
			return;
		}

		const queued = await enqueue(body);
		this.pending = queued.pending;
		this.queueDropped = queued.dropped;
		this.sendState = 'queued';
	}

	async refreshPending(): Promise<void> {
		this.pending = await pendingCount();
	}

	private async mutateNudge(mutate: (state: NudgeState) => NudgeState): Promise<void> {
		const next = await updateFeedbackState((state) => ({ ...state, nudge: mutate(state.nudge) }));
		this.nudge = next.nudge;
	}
}

export const feedbackStore = new FeedbackStore();
