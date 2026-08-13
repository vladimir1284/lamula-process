import { describe, it, expect } from 'vitest';
import { effectiveBeamWidth, DEFAULT_BEAM_WIDTH_DEG } from './beamWidth';
import type { Channel } from './types';

function channelWith(beamWidthDeg: number | undefined): Channel {
	return { moment: 'dBZ', scans: [], beamWidthDeg } as unknown as Channel;
}

describe('effectiveBeamWidth', () => {
	it('flags the fallback as inferred when the channel has no real beam width', () => {
		expect(effectiveBeamWidth(channelWith(undefined))).toEqual({
			deg: DEFAULT_BEAM_WIDTH_DEG,
			inferred: true
		});
	});

	it('flags the fallback as inferred when there is no channel at all', () => {
		expect(effectiveBeamWidth(undefined)).toEqual({ deg: DEFAULT_BEAM_WIDTH_DEG, inferred: true });
		expect(effectiveBeamWidth(null)).toEqual({ deg: DEFAULT_BEAM_WIDTH_DEG, inferred: true });
	});

	it('uses the real value and is not inferred when the channel has one', () => {
		expect(effectiveBeamWidth(channelWith(1.5))).toEqual({ deg: 1.5, inferred: false });
	});
});
