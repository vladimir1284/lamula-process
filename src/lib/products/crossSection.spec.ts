import { describe, it, expect } from 'vitest';
import { makeScan } from '$lib/render/scanFixtures';
import {
	buildScanMeta,
	sampleCrossSection,
	nearestRayByAzimuth,
	nearestScanByElev,
	eastWestLine,
	northSouthLine
} from './crossSection';

const DEG = Math.PI / 180;

describe('cross-section helpers', () => {
	it('nearestRayByAzimuth handles the 0/360 seam', () => {
		const centers = new Float64Array([0, 90, 180, 270]);
		expect(nearestRayByAzimuth(centers, 5)).toBe(0);
		expect(nearestRayByAzimuth(centers, 355)).toBe(0); // wraps to ray at 0°
		expect(nearestRayByAzimuth(centers, 100)).toBe(1);
	});

	it('nearestScanByElev returns -1 beyond the swept sector + pad', () => {
		const metas = buildScanMeta([makeScan({ angleDeg: 0 }), makeScan({ angleDeg: 10 })]);
		expect(nearestScanByElev(metas, 0.5, 0.75)).toBe(0);
		expect(nearestScanByElev(metas, 9.5, 0.75)).toBe(1);
		expect(nearestScanByElev(metas, 30, 0.75)).toBe(-1);
	});

	it('line presets are axis-aligned and centred', () => {
		expect(eastWestLine(1000, 50000)).toEqual({ ax: -50000, ay: 1000, bx: 50000, by: 1000 });
		expect(northSouthLine(2000, 50000)).toEqual({ ax: 2000, ay: -50000, bx: 2000, by: 50000 });
	});
});

describe('sampleCrossSection', () => {
	// scan0 (elev 0): value = ray*100 + gate; scan1 (elev 10): constant 77
	const scans = [
		makeScan({
			numRays: 4,
			numGates: 6,
			gateLengthM: 1000,
			angleDeg: 0,
			fill: (r, g) => r * 100 + g
		}),
		makeScan({ numRays: 4, numGates: 6, gateLengthM: 1000, angleDeg: 10, fill: () => 77 })
	];
	const metas = buildScanMeta(scans);

	it('samples the low tilt for a near-surface point due north', () => {
		// north point at range 3000 m, height 0 → elev≈0 → scan0, ray0 (north), gate 3
		const s = sampleCrossSection(metas, 0, 3000, 0)!;
		expect(s.flag).toBe('ok');
		expect(s.value).toBe(3); // ray0*100 + gate3
	});

	it('resolves azimuth: a point due east hits the 90° ray', () => {
		const s = sampleCrossSection(metas, 3000, 0, 0)!;
		expect(s.value).toBe(103); // ray1 (90°)*100 + gate3
	});

	it('picks the higher tilt when the point is elevated', () => {
		// north, range 3000, height ≈ 3000·tan10° → elev≈10° → scan1
		const h = 3000 * Math.tan(10 * DEG);
		const s = sampleCrossSection(metas, 0, 3000, h)!;
		expect(s.value).toBe(77);
	});

	it('returns null past the last gate', () => {
		expect(sampleCrossSection(metas, 0, 99_000, 0)).toBeNull();
	});
});
