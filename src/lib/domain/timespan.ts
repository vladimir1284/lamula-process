import type { Observation } from './types';

/**
 * TimeSpan — an ordered set of observations of the same radar, the data container behind
 * time-integrated products (accumulation). Port of `legacy/Units/TimeSpan.pas` (`TTimeSpan`),
 * pulled forward from P3 for the P2 precipitation-accumulation product. Only the container is
 * ported here; the P3 animation/playback that also consumes a TimeSpan is NOT in scope.
 *
 * Legacy enforces channel-identity across observations (`ChannelsEqual`: wave/pulse/cells/length/
 * sectors/beam) and silently drops mismatches. We keep the spirit — same radar site — and report
 * dropped observations rather than hiding them; the caller decides what to do.
 */

export interface TimeSpan {
	/** Observations sorted ascending by timestamp. */
	observations: Observation[];
}

export interface TimeSpanResult {
	span: TimeSpan;
	/** Observations dropped because they belong to a different radar than the first. */
	skipped: Observation[];
}

function timeMs(o: Observation): number {
	return Date.parse(o.timestamp);
}

/**
 * Build a TimeSpan from parsed observations. The first observation fixes the radar; observations
 * whose `site.code` differs are dropped (reported in `skipped`). The rest are sorted by time.
 */
export function createTimeSpan(observations: Observation[]): TimeSpanResult {
	if (observations.length === 0) return { span: { observations: [] }, skipped: [] };
	const base = observations[0];
	const kept: Observation[] = [];
	const skipped: Observation[] = [];
	for (const o of observations) {
		if (o === base || o.site.code === base.site.code) kept.push(o);
		else skipped.push(o);
	}
	kept.sort((a, b) => timeMs(a) - timeMs(b));
	return { span: { observations: kept }, skipped };
}

export function firstTimeMs(span: TimeSpan): number {
	if (span.observations.length === 0) throw new Error('firstTimeMs: empty TimeSpan');
	return timeMs(span.observations[0]);
}

export function lastTimeMs(span: TimeSpan): number {
	if (span.observations.length === 0) throw new Error('lastTimeMs: empty TimeSpan');
	return timeMs(span.observations[span.observations.length - 1]);
}

/** Largest gap (ms) between consecutive observations; 0 for fewer than two. */
export function maxTimeGapMs(span: TimeSpan): number {
	let max = 0;
	for (let i = 1; i < span.observations.length; i++) {
		const d = timeMs(span.observations[i]) - timeMs(span.observations[i - 1]);
		if (d > max) max = d;
	}
	return max;
}

/**
 * Parse the line list of a `.tms` file into relative observation paths. Faithful to the legacy
 * text format (one relative path per line). Resolving those paths to actual files needs a
 * filesystem backend (the deferred Tauri path); web builds a TimeSpan from in-memory observations
 * via `createTimeSpan` instead.
 */
export function parseTmsList(text: string): string[] {
	return text
		.split(/\r?\n/)
		.map((l) => l.trim())
		.filter((l) => l.length > 0);
}
