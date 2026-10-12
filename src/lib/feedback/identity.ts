import type { FeedbackProfile, FeedbackSubmission } from './contract';

/**
 * Identity without accounts, plus everything else the feedback feature has to remember.
 *
 * Same scheme as lamula-webviewer's `composables/useFeedbackIdentity.ts`: a 32-byte random token
 * in local storage, sent in `x-feedback-token`; the server only ever stores its sha256. Losing
 * the token orphans the user's thread (they can still send, but past replies become invisible),
 * so every recovery path below keeps a usable token when it can.
 *
 * Its own key, NOT merged into `lamula-process:config` / `:settings` / `:palette-book`: those
 * have their own validation schemas and mixing them would make three files harder to reason
 * about. Unlike those, this one carries `v` -- the profile and the queue will change shape well
 * before display preferences do.
 *
 * Tauri: `platform/config.ts` throws on the desktop path. Not here -- a throw during feedback
 * boot would take the whole desktop app down. The Tauri webview has local storage, so both
 * targets use it; moving to `@tauri-apps/plugin-store` is work for the day a Rust toolchain
 * exists.
 */

export const FEEDBACK_STORAGE_KEY = 'lamula-process:feedback';
export const STATE_VERSION = 1;
export const MAX_QUEUE = 20;
const TOKEN_BYTES = 32;
const MIN_TOKEN_LENGTH = 10;

export interface QueuedSubmission {
	/** Also travels in `context.clientId`, so a duplicate can be spotted in the inbox later. */
	clientId: string;
	body: FeedbackSubmission;
	queuedAt: number;
	attempts: number;
	lastError?: string;
}

export interface NudgeState {
	shownCount: number;
	/** Epoch ms; the nudge stays hidden until then. */
	snoozeUntil: number | null;
	submitted: boolean;
	/** "No, thanks" is permanent here, unlike the webviewer's 7-day snooze. */
	dismissedForever: boolean;
}

export interface FeedbackState {
	v: number;
	token: string;
	profile: FeedbackProfile | null;
	nudge: NudgeState;
	queue: QueuedSubmission[];
}

export function defaultNudgeState(): NudgeState {
	return { shownCount: 0, snoozeUntil: null, submitted: false, dismissedForever: false };
}

export function newToken(): string {
	const bytes = new Uint8Array(TOKEN_BYTES);
	crypto.getRandomValues(bytes);
	return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

function defaultState(): FeedbackState {
	return {
		v: STATE_VERSION,
		token: newToken(),
		profile: null,
		nudge: defaultNudgeState(),
		queue: []
	};
}

/**
 * In-memory fallback for when local storage is missing or throws (private mode, a locked-down
 * kiosk). The feature keeps working for the session instead of silently dropping messages.
 */
let memoryState: FeedbackState | null = null;
/** Once a read or a write has failed, local storage is not to be trusted for this session. */
let usingMemory = false;

function storage(): Storage | null {
	try {
		return typeof localStorage === 'undefined' ? null : localStorage;
	} catch {
		return null;
	}
}

function isQueuedSubmission(v: unknown): v is QueuedSubmission {
	if (typeof v !== 'object' || v === null) return false;
	const entry = v as QueuedSubmission;
	return (
		typeof entry.clientId === 'string' &&
		typeof entry.body === 'object' &&
		entry.body !== null &&
		typeof entry.body.message === 'string' &&
		typeof entry.queuedAt === 'number'
	);
}

function readNudge(v: unknown): NudgeState {
	const base = defaultNudgeState();
	if (typeof v !== 'object' || v === null) return base;
	const n = v as Partial<NudgeState>;
	return {
		shownCount: typeof n.shownCount === 'number' && n.shownCount >= 0 ? n.shownCount : 0,
		snoozeUntil: typeof n.snoozeUntil === 'number' ? n.snoozeUntil : null,
		submitted: n.submitted === true,
		dismissedForever: n.dismissedForever === true
	};
}

function readProfile(v: unknown): FeedbackProfile | null {
	if (typeof v !== 'object' || v === null) return null;
	const p = v as FeedbackProfile;
	return typeof p.role === 'string' ? p : null;
}

export async function loadFeedbackState(): Promise<FeedbackState> {
	const store = storage();
	if (!store || usingMemory) {
		usingMemory = true;
		memoryState ??= defaultState();
		return memoryState;
	}

	let raw: string | null;
	try {
		raw = store.getItem(FEEDBACK_STORAGE_KEY);
	} catch {
		usingMemory = true;
		memoryState ??= defaultState();
		return memoryState;
	}
	if (!raw) return defaultState();

	try {
		const parsed = JSON.parse(raw) as Partial<FeedbackState>;
		const token =
			typeof parsed.token === 'string' && parsed.token.length >= MIN_TOKEN_LENGTH
				? parsed.token
				: newToken();

		// An unknown version means a shape we can't read. Start over but KEEP the token: the
		// thread on the server hangs off it and there is no way to get it back.
		if (parsed.v !== STATE_VERSION) {
			return { ...defaultState(), token };
		}

		const queue = Array.isArray(parsed.queue) ? parsed.queue.filter(isQueuedSubmission) : [];
		return {
			v: STATE_VERSION,
			token,
			profile: readProfile(parsed.profile),
			nudge: readNudge(parsed.nudge),
			queue: queue.slice(-MAX_QUEUE)
		};
	} catch {
		return defaultState();
	}
}

export async function saveFeedbackState(state: FeedbackState): Promise<void> {
	const store = storage();
	if (!store || usingMemory) {
		usingMemory = true;
		memoryState = state;
		return;
	}
	try {
		store.setItem(FEEDBACK_STORAGE_KEY, JSON.stringify(state));
	} catch {
		// Quota or a locked-down browser. Fall back to memory for the rest of the session --
		// otherwise the next read would go back to storage and quietly lose this write.
		usingMemory = true;
		memoryState = state;
	}
}

/** Read-modify-write. Everything that mutates the stored state goes through here. */
export async function updateFeedbackState(
	mutate: (state: FeedbackState) => FeedbackState
): Promise<FeedbackState> {
	const next = mutate(await loadFeedbackState());
	await saveFeedbackState(next);
	return next;
}

/** The token is minted on first use and never changes afterwards. */
export async function getFeedbackToken(): Promise<string> {
	const state = await loadFeedbackState();
	await saveFeedbackState(state);
	return state.token;
}

export async function loadProfile(): Promise<FeedbackProfile | null> {
	return (await loadFeedbackState()).profile;
}

/** From the second submission on, the user only has to write the message. */
export async function saveProfile(profile: FeedbackProfile): Promise<void> {
	await updateFeedbackState((state) => ({ ...state, profile }));
}

/** Test seam: drops the in-memory fallback. */
export function resetMemoryState(): void {
	memoryState = null;
	usingMemory = false;
}
