import { describe, it, expect } from 'vitest';
import { makeScan } from '$lib/render/scanFixtures';
import { buildAzimuthLUT } from '$lib/render/scanSample';
import { readoutAt } from './readout';

describe('readoutAt', () => {
	const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000 });
	const lut = buildAzimuthLUT(scan);
	const site: [number, number] = [1000, 2000];
	const scale = 2; // 2 projected units per ground metre

	it('recovers range and azimuth from a projected offset', () => {
		// 1000 ground m due north -> projected +2000 in Y
		const r = readoutAt([1000, 2000 + 2000], site, scale, scan, lut);
		expect(r.rangeM).toBeCloseTo(1000, 6);
		expect(r.azimuthDeg).toBeCloseTo(0, 6);
		expect(r.value).toBe(1); // ray 0, gate 1
		expect(r.flag).toBe('ok');
	});

	it('reads due-east as azimuth 90', () => {
		const r = readoutAt([1000 + 4000, 2000], site, scale, scan, lut); // 2000 m east
		expect(r.azimuthDeg).toBeCloseTo(90, 6);
		expect(r.value).toBe(102); // ray 1, gate 2
	});

	it('returns null value outside the disc but still a range/azimuth', () => {
		const r = readoutAt([1000, 2000 + 40_000], site, scale, scan, lut);
		expect(r.value).toBeNull();
		expect(r.flag).toBeNull();
		expect(r.rangeM).toBeCloseTo(20_000, 6);
	});
});
