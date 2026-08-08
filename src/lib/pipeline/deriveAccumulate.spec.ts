import { describe, it, expect } from 'vitest';
import type { Observation, Channel } from '$lib/domain/types';
import type { TimeSpan } from '$lib/domain';
import { makeScan } from '$lib/render/scanFixtures';
import { buildAccumFrames, deriveAccumulateOptionsFromPayload } from './deriveAccumulate';

function channel(moment: Channel['moment'], id = 0): Channel {
	return { id, moment, scans: [makeScan({ angleDeg: 0.5 })] };
}

function obs(timestamp: string, channels: Channel[]): Observation {
	return {
		id: timestamp,
		site: { name: 'X', code: 'X' },
		timestamp,
		design: 'VCP',
		movements: [{ id: 0, kind: 'PPI', channels }]
	};
}

describe('buildAccumFrames', () => {
	it('extracts one frame per observation with a matching-moment channel', () => {
		const span: TimeSpan = {
			observations: [
				obs('2020-01-01T00:00:00Z', [channel('dBZ')]),
				obs('2020-01-01T00:05:00Z', [channel('dBZ')])
			]
		};
		const frames = buildAccumFrames(span, 'dBZ');
		expect(frames).toHaveLength(2);
		expect(frames[0].timeMs).toBe(Date.parse('2020-01-01T00:00:00Z'));
		expect(frames[0].scans).toBe(span.observations[0].movements[0].channels[0].scans);
	});

	it('drops observations lacking the requested moment', () => {
		const span: TimeSpan = {
			observations: [
				obs('2020-01-01T00:00:00Z', [channel('dBZ')]),
				obs('2020-01-01T00:05:00Z', [channel('V')])
			]
		};
		expect(buildAccumFrames(span, 'dBZ')).toHaveLength(1);
	});

	it('returns an empty array, not a throw, when nothing matches', () => {
		const span: TimeSpan = { observations: [obs('2020-01-01T00:00:00Z', [channel('V')])] };
		expect(buildAccumFrames(span, 'dBZ')).toEqual([]);
	});
});

describe('deriveAccumulateOptionsFromPayload', () => {
	it('converts km to m and minutes to ms', () => {
		const opts = deriveAccumulateOptionsFromPayload(
			{ bottomKm: 1, topKm: 3, intervalMin: 5, zrA: 300, zrB: 1.4 },
			1.0,
			120
		);
		expect(opts).toEqual({
			beamWidthDeg: 1.0,
			siteAltM: 120,
			bottomM: 1000,
			topM: 3000,
			zrA: 300,
			zrB: 1.4,
			intervalMs: 300_000
		});
	});
});
