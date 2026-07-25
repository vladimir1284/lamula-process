import { describe, it, expect } from 'vitest';
import type { Palette } from '$lib/palette/types';
import { makeRhiScan } from './rhiFixtures';
import { rayElevationsDeg, nearestRayByElev, rasterizeRHI, rhiReadoutAt } from './rasterizeRHI';

const palette: Palette = {
	name: 'test',
	smooth: false,
	stops: [
		{ value: 0, color: [10, 10, 10], caption: 'a' },
		{ value: 1, color: [20, 20, 20], caption: 'b' },
		{ value: 2, color: [30, 30, 30], caption: 'c' },
		{ value: 100, color: [255, 0, 0], caption: 'd' }
	]
};

describe('rayElevationsDeg', () => {
	it('returns each ray centre elevation', () => {
		const scan = makeRhiScan({ elevationsDeg: [0.5, 1.5, 2.5] });
		expect(Array.from(rayElevationsDeg(scan))).toEqual([0.5, 1.5, 2.5]);
	});
});

describe('nearestRayByElev', () => {
	const elevs = new Float64Array([0.5, 1.5, 2.5]);
	it('picks the nearest ray inside the sector', () => {
		expect(nearestRayByElev(elevs, 1.4, 0.75)).toBe(1);
		expect(nearestRayByElev(elevs, 0.4, 0.75)).toBe(0); // within pad below the lowest
	});
	it('rejects elevations beyond the swept sector + pad', () => {
		expect(nearestRayByElev(elevs, 10, 0.75)).toBe(-1);
		expect(nearestRayByElev(elevs, -2, 0.75)).toBe(-1);
	});
});

describe('rasterizeRHI', () => {
	it('maps low pixels to low elevation rays (ground up)', () => {
		// value = ray index; ray 0 -> colour [10,10,10]
		const scan = makeRhiScan({
			elevationsDeg: [0.5, 1.5, 2.5, 3.5, 5],
			numGates: 100,
			gateLengthM: 1000,
			fill: (ray) => ray
		});
		const r = rasterizeRHI(scan, palette, {
			widthPx: 100,
			heightPx: 100,
			maxRangeM: 100_000,
			maxHeightM: 10_000
		});
		// column at 50 km, bottom-most row -> lowest elevation -> ray 0 -> colour [10,10,10]
		const px = 50;
		const py = 99; // bottom row (near height 0)
		const o = (py * r.widthPx + px) * 4;
		expect(r.rgba[o + 3]).toBe(255);
		expect([r.rgba[o], r.rgba[o + 1], r.rgba[o + 2]]).toEqual([10, 10, 10]);
	});

	it('leaves pixels above the top elevation blank', () => {
		const scan = makeRhiScan({ elevationsDeg: [0.5, 1.5], numGates: 100, gateLengthM: 1000 });
		const r = rasterizeRHI(scan, palette, {
			widthPx: 40,
			heightPx: 40,
			maxRangeM: 100_000,
			maxHeightM: 40_000
		});
		// top-left: very high elevation at short range -> beyond 1.5° sector -> transparent
		expect(r.rgba[(0 * r.widthPx + 0) * 4 + 3]).toBe(0);
	});
});

describe('rhiReadoutAt', () => {
	it('reads range/height/value at a ground point', () => {
		const scan = makeRhiScan({
			elevationsDeg: [0.5, 1.5, 2.5],
			numGates: 100,
			gateLengthM: 1000,
			fill: (ray, gate) => ray * 1000 + gate
		});
		// ground 50 km at the 0.5° beam height -> ray 0, gate ~50
		const heightAtHalfDeg = 50_000 * Math.tan((0.5 * Math.PI) / 180);
		const ro = rhiReadoutAt(50_000, heightAtHalfDeg, scan);
		expect(ro.value).not.toBeNull();
		expect(ro.value! < 1000).toBe(true); // ray 0 band (0..99)
		expect(ro.flag).toBe('ok');
	});

	it('returns null value outside the gated range', () => {
		const scan = makeRhiScan({ elevationsDeg: [0.5, 1.5], numGates: 10, gateLengthM: 1000 });
		const ro = rhiReadoutAt(500_000, 1000, scan);
		expect(ro.value).toBeNull();
	});
});
