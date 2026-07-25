import { describe, it, expect } from 'vitest';
import { beamHeightM, beamHeightRangeM, EFFECTIVE_EARTH_RADIUS_M, EARTH_RADIUS_M } from './height';

// Independent oracle: the closed-form 4/3-earth beam height
//   h = sqrt(r² + ae² + 2·r·ae·sin θ) − ae   (+ site altitude datum)
// derived separately from the legacy law-of-cosines port, so agreement cross-checks both.
function oracle(r: number, elevDeg: number, alt = 0): number {
	const ae = EFFECTIVE_EARTH_RADIUS_M + alt;
	const s = Math.sin((elevDeg * Math.PI) / 180);
	return Math.sqrt(r * r + ae * ae + 2 * r * ae * s) - EFFECTIVE_EARTH_RADIUS_M;
}

describe('beamHeightM (4/3 earth)', () => {
	it('uses the legacy earth radius and refraction factor', () => {
		expect(EARTH_RADIUS_M).toBe(6_378_160);
		expect(EFFECTIVE_EARTH_RADIUS_M).toBeCloseTo((4 / 3) * 6_378_160, 3);
	});

	it('matches the small-angle approximation h ≈ r²/(2·ae) at 0° elevation', () => {
		const r = 100_000; // 100 km
		const approx = (r * r) / (2 * EFFECTIVE_EARTH_RADIUS_M);
		expect(beamHeightM(r, 0)).toBeCloseTo(approx, 0); // ~588 m
		expect(beamHeightM(r, 0)).toBeGreaterThan(580);
		expect(beamHeightM(r, 0)).toBeLessThan(595);
	});

	it('agrees with the independent closed-form oracle across ranges and elevations', () => {
		for (const r of [1_000, 25_000, 100_000, 250_000]) {
			for (const e of [0, 0.5, 1.5, 5, 19.5]) {
				expect(beamHeightM(r, e)).toBeCloseTo(oracle(r, e), 3);
			}
		}
	});

	it('is monotonically increasing in elevation at fixed range', () => {
		const r = 120_000;
		expect(beamHeightM(r, 0)).toBeLessThan(beamHeightM(r, 1));
		expect(beamHeightM(r, 1)).toBeLessThan(beamHeightM(r, 5));
	});

	it('offsets by site altitude', () => {
		expect(beamHeightM(80_000, 2, 500)).toBeCloseTo(oracle(80_000, 2, 500), 2);
		// altitude datum shift is close to (but not exactly) linear near the surface
		expect(beamHeightM(80_000, 2, 500) - beamHeightM(80_000, 2, 0)).toBeGreaterThan(490);
	});

	it('returns 0 at zero range regardless of angle', () => {
		expect(beamHeightM(0, 0)).toBeCloseTo(0, 6);
		expect(beamHeightM(0, 10)).toBeCloseTo(0, 6);
	});
});

describe('beamHeightRangeM', () => {
	it('brackets the centre height by the beam half-width', () => {
		const r = 150_000;
		const centre = beamHeightM(r, 2);
		const { min, max } = beamHeightRangeM(r, 2, 1); // ±0.5°
		expect(min).toBeLessThan(centre);
		expect(max).toBeGreaterThan(centre);
		expect(min).toBeCloseTo(beamHeightM(r, 1.5), 6);
		expect(max).toBeCloseTo(beamHeightM(r, 2.5), 6);
	});
});
