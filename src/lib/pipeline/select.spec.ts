import { describe, it, expect } from 'vitest';
import type { Observation, Channel } from '$lib/domain/types';
import { makeScan } from '$lib/render/scanFixtures';
import { observationChannels, listElevationsDeg, pickScanByElevation, hasGeoref } from './select';

function channel(id: number, elevs: number[]): Channel {
	return {
		id,
		moment: 'dBZ',
		scans: elevs.map((e, i) => ({ ...makeScan({ angleDeg: e }), id: i }))
	};
}

const obs: Observation = {
	id: 'o',
	site: { name: 'X', code: 'X', lon: -77.85, lat: 21.42 },
	timestamp: '2020-01-01T00:00:00Z',
	design: 'VCP',
	movements: [
		{ id: 0, kind: 'PPI', channels: [channel(0, [0.5, 1.5, 2.5]), channel(1, [0.5, 1.5])] }
	]
};

describe('observationChannels', () => {
	it('flattens channels with stable indices', () => {
		const refs = observationChannels(obs);
		expect(refs.map((r) => r.index)).toEqual([0, 1]);
		expect(refs[0].channel.moment).toBe('dBZ');
	});
});

describe('listElevationsDeg', () => {
	it('returns sorted unique elevations', () => {
		expect(listElevationsDeg(channel(0, [2.5, 0.5, 1.5, 0.5]))).toEqual([0.5, 1.5, 2.5]);
	});
});

describe('pickScanByElevation', () => {
	it('picks the nearest elevation', () => {
		const c = channel(0, [0.5, 1.5, 2.5]);
		expect(pickScanByElevation(c, 1.4).angleDeg).toBe(1.5);
		expect(pickScanByElevation(c, 10).angleDeg).toBe(2.5);
	});
	it('throws on an empty channel', () => {
		expect(() => pickScanByElevation(channel(0, []), 1)).toThrow();
	});
});

describe('hasGeoref', () => {
	it('is true when the site has a position', () => {
		expect(hasGeoref(obs)).toBe(true);
	});
	it('is false when the site lacks lon/lat (e.g. NEXRAD L2 msg-31)', () => {
		expect(hasGeoref({ ...obs, site: { name: 'X', code: 'X' } })).toBe(false);
	});
});
