import type { NudgeState } from './identity';

/**
 * When to offer the feedback card. Pure functions with the clock injected, like
 * lamula-webviewer's `utils/feedback/nudge.ts`, with two deliberate differences.
 *
 * 1. The trigger is NOT session time. The webviewer nudges after 90 seconds of looking at a map.
 *    This app doesn't give value by being looked at: it gives value when something is processed.
 *    So the trigger is "the user closed the first product window they generated this session",
 *    with a floor of 60 seconds since boot so a quick open-and-close doesn't fire it.
 * 2. "No, thanks" is permanent. In the webviewer `calcSnoozeUntil('never')` returns 7 days,
 *    which contradicts the button's own label.
 */

export const MIN_UPTIME_MS = 60_000;
export const MAX_SHOWS = 3;
export const SNOOZE_MS = 3 * 24 * 60 * 60 * 1000;

export interface NudgeDecisionInput {
	state: NudgeState;
	/** Epoch ms. */
	now: number;
	/** Epoch ms of app boot. */
	bootedAt: number;
	/** The user has closed at least one product window this session. */
	productWindowClosed: boolean;
	/** Already on screen, or shown and dismissed earlier in this same session. */
	shownThisSession: boolean;
}

export function shouldShowNudge(input: NudgeDecisionInput): boolean {
	const { state, now, bootedAt, productWindowClosed, shownThisSession } = input;

	if (state.dismissedForever || state.submitted) return false;
	if (shownThisSession) return false;
	if (state.shownCount >= MAX_SHOWS) return false;
	if (state.snoozeUntil !== null && now < state.snoozeUntil) return false;
	if (!productWindowClosed) return false;

	return now - bootedAt >= MIN_UPTIME_MS;
}

export function markNudgeShown(state: NudgeState): NudgeState {
	return { ...state, shownCount: state.shownCount + 1 };
}

/** "Later": back in three days. */
export function snoozeNudge(state: NudgeState, now: number): NudgeState {
	return { ...state, snoozeUntil: now + SNOOZE_MS };
}

/** "No, thanks": never again, and we mean it. */
export function dismissNudgeForever(state: NudgeState): NudgeState {
	return { ...state, dismissedForever: true };
}

/** Someone who already wrote to us does not get asked again. */
export function markFeedbackSubmitted(state: NudgeState): NudgeState {
	return { ...state, submitted: true };
}
