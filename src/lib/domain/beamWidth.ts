import type { Channel } from './types';

/** Fallback beam width (deg) for channels whose parser doesn't expose a real value
 * (nexrad-l2, sigmet-iris, netcdf-cfradial) -- close to a typical WSR-88D beam. */
export const DEFAULT_BEAM_WIDTH_DEG = 1.0;

export interface EffectiveBeamWidth {
	deg: number;
	/** True when the channel had no real parsed beamWidthDeg and this is the fallback. */
	inferred: boolean;
}

/** Resolve a channel's beam width, single source of truth for both the numeric fallback and
 * whether it's a guess -- so a UI warning about the fallback can never drift from the value
 * actually used in the beam-height math. */
export function effectiveBeamWidth(channel: Channel | undefined | null): EffectiveBeamWidth {
	return {
		deg: channel?.beamWidthDeg ?? DEFAULT_BEAM_WIDTH_DEG,
		inferred: channel?.beamWidthDeg == null
	};
}
