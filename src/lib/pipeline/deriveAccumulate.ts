import type { MomentType } from '$lib/domain/types';
import type { TimeSpan } from '$lib/domain';
import { observationChannels } from './select';
import type { AccumFrame, AccumulateOptions } from '$lib/products/accumulate';

/**
 * `TimeSpan` -> `AccumFrame[]` extraction that `products/accumulate.ts`'s doc comment says the UI
 * owns (kept here, not in `deriveProduct.ts`, since accumulation needs a `TimeSpan` rather than a
 * single `Channel` -- see that file's header comment for why it's excluded there).
 */

/** The subset of `AccumulateWindowPayload` (windows/windowTypes.ts) that determines
 * `AccumulateOptions` -- structural rather than importing that type directly, same convention as
 * `MapPayloadDeriveFields` in `deriveProduct.ts`. */
export interface AccumulatePayloadDeriveFields {
	bottomKm: number;
	topKm: number;
	intervalMin: number;
	zrA: number;
	zrB: number;
}

/** One frame per observation whose channel list has a match for `moment` (by moment, not
 * positional index -- channel ordering isn't guaranteed stable across observations, same
 * convention `mergeSweeps.ts` uses). Observations missing that moment are silently dropped; an
 * empty result is a legitimate runtime state the caller (the window) handles, not an error here. */
export function buildAccumFrames(span: TimeSpan, moment: MomentType): AccumFrame[] {
	const frames: AccumFrame[] = [];
	for (const obs of span.observations) {
		const ref = observationChannels(obs).find((r) => r.channel.moment === moment);
		if (!ref) continue;
		frames.push({ timeMs: Date.parse(obs.timestamp), scans: ref.channel.scans });
	}
	return frames;
}

export function deriveAccumulateOptionsFromPayload(
	payload: AccumulatePayloadDeriveFields,
	beamWidthDeg: number,
	siteAltM: number
): AccumulateOptions {
	return {
		beamWidthDeg,
		siteAltM,
		bottomM: payload.bottomKm * 1000,
		topM: payload.topKm * 1000,
		zrA: payload.zrA,
		zrB: payload.zrB,
		intervalMs: payload.intervalMin * 60_000
	};
}
