/**
 * Build-time constants, read through functions so every caller gets the same normalisation and
 * tests can reason about one place. Values come from vite's `define` (see vite.config.ts).
 */

/** Base URL of the feedback API, no trailing slash. Empty string = feature off. */
export function feedbackApiBase(): string {
	const raw = typeof __FEEDBACK_API__ === 'string' ? __FEEDBACK_API__ : '';
	return raw.trim().replace(/\/+$/, '');
}

/** Git SHA in CI, 'dev' locally. Reported in the feedback context so a bug maps to a build. */
export function buildId(): string {
	return typeof __BUILD_ID__ === 'string' && __BUILD_ID__.length > 0 ? __BUILD_ID__ : 'dev';
}

/**
 * With no API configured the whole feature stays dark: no Help menu, no nudge, no badge.
 * That is the default in development -- there is no local server to talk to.
 */
export function isFeedbackEnabled(): boolean {
	return feedbackApiBase().length > 0;
}
