import { describe, it, expect } from 'vitest';
import type { Palette } from '$lib/palette/types';
import { makeScan } from '$lib/render/scanFixtures';
import {
	buildScanMeta,
	sampleCrossSection,
	nearestRayByAzimuth,
	nearestScanByElev,
	eastWestLine,
	northSouthLine,
	rasterizeCrossSection,
	NO_COVERAGE_RGBA
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

describe('rasterizeCrossSection maxProjection', () => {
	// Single elevation (10°), 4 rays (N/E/S/W), gate length 1000 m. Same range/height pairing as
	// the "picks the higher tilt" test above (range 3000 m, height = 3000*tan(10°)) -- proven to
	// resolve to this scan within the default elevPad. At that (range, height), every ray's ground
	// point is at range 3000 regardless of azimuth: N/S rays land at (along=0, perp=+-3000) --
	// exactly the axis an E-W max-projection cut collapses -- while E/W rays land at
	// (along=+-3000, perp=0), the axis it keeps. Gate 3 is the one that range/height pair resolves
	// to (see the assertion below); every other gate is filler (0) since no probed range bin
	// reaches them.
	const h = 3000 * Math.tan(10 * DEG);
	const scans = [
		makeScan({
			numRays: 4,
			numGates: 6,
			gateLengthM: 1000,
			angleDeg: 10,
			fill: (ray, gate) => {
				if (gate !== 3) return 0;
				return [50, 1, 80, 2][ray]; // north, east, south, west
			}
		})
	];
	const palette: Palette = {
		name: 'test',
		smooth: false,
		stops: [0, 1, 2, 50, 80].map((v) => ({
			value: v,
			color: [v, v, v] as const,
			caption: String(v)
		}))
	};
	// along axis: -6000..6000 over 12 columns -> 1000 m/column, so along=0/+-3000 land on distinct
	// column boundaries (6, 9, 3).
	const line = eastWestLine(0, 6000);
	const rasterOpts = { widthPx: 12, heightPx: 1, maxHeightM: 2 * h, line };

	it('collapses the full perpendicular window by MAX (north/south both reachable)', () => {
		const r = rasterizeCrossSection(scans, palette, {
			...rasterOpts,
			maxProjection: { perpMinM: -5000, perpMaxM: 5000 }
		});
		// column 6 (along=0) gets both the north (50, perp=+3000) and south (80, perp=-3000) rays --
		// MAX wins with 80.
		expect(r.rgba[6 * 4]).toBe(80);
		// column 9 (east, along=+3000) and column 3 (west, along=-3000) are untouched.
		expect(r.rgba[9 * 4]).toBe(1);
		expect(r.rgba[3 * 4]).toBe(2);
	});

	it('clips contributions outside the perpendicular window', () => {
		// South sits at perp=-3000; narrowing the window to [-2500, 5000] excludes it, so only the
		// north ray (perp=+3000, still inside) survives -> MAX flips from 80 to 50.
		const r = rasterizeCrossSection(scans, palette, {
			...rasterOpts,
			maxProjection: { perpMinM: -2500, perpMaxM: 5000 }
		});
		expect(r.rgba[6 * 4]).toBe(50);
	});

	it('is independent of the line position on the collapsed axis', () => {
		const opts = { ...rasterOpts, maxProjection: { perpMinM: -5000, perpMaxM: 5000 } };
		const a = rasterizeCrossSection(scans, palette, { ...opts, line: eastWestLine(0, 6000) });
		const b = rasterizeCrossSection(scans, palette, { ...opts, line: eastWestLine(12_345, 6000) });
		expect(Array.from(b.rgba)).toEqual(Array.from(a.rgba));
	});

	it('rejects a non-axis-aligned line', () => {
		expect(() =>
			rasterizeCrossSection(scans, palette, {
				...rasterOpts,
				line: { ax: 0, ay: 0, bx: 1000, by: 1000 },
				maxProjection: { perpMinM: -5000, perpMaxM: 5000 }
			})
		).toThrow(/axis-aligned/);
	});

	it('shades the below-lowest-tilt wedge, same as the per-pixel path', () => {
		// The fixture's only scan is at 10°; querying a height of 5 m needs an elevation near 0° at
		// every probed range (1000, 2000, ... m) -- well below that 10° tilt, so column 6 (along=0,
		// reached by both the north and south rays) can never resolve to real data and should be
		// shaded as unobservable instead of left blank.
		const r = rasterizeCrossSection(scans, palette, {
			widthPx: 12,
			heightPx: 1,
			maxHeightM: 10,
			line,
			maxProjection: { perpMinM: -5000, perpMaxM: 5000 }
		});
		expect(Array.from(r.rgba.slice(6 * 4, 6 * 4 + 4))).toEqual(Array.from(NO_COVERAGE_RGBA));
	});

	it('bounds the wedge test to the actual perpendicular window, not a hardcoded perp=0', () => {
		// The window is [1000, 2000] -- it does NOT bracket the site (perp=0), which happens once the
		// map is panned so the docked strip's collapsed window no longer straddles it. The wedge test
		// must use the window's own closest point (1000) as its one-sided range bound, not pretend
		// perp=0 is reachable: at along=0, height=5 m, range=0 would read as a steep (near-90°, well
		// above the 10° tilt) elevation and wrongly skip the shading, while the true bound (range
		// 1000 m) reads as ~0.3°, correctly below the 10° tilt.
		const r = rasterizeCrossSection(scans, palette, {
			widthPx: 12,
			heightPx: 1,
			maxHeightM: 10,
			line,
			maxProjection: { perpMinM: 1000, perpMaxM: 2000 }
		});
		expect(Array.from(r.rgba.slice(6 * 4, 6 * 4 + 4))).toEqual(Array.from(NO_COVERAGE_RGBA));
	});

	it('does not shade inside the elevPad tolerance the data loop still matches', () => {
		// range 3000 m, height = 3000*tan(9.5°): elevation ~9.5°, i.e. 0.5° below the fixture's only
		// (10°) tilt -- inside the default 0.75° pad, so `nearestScanByElev` still matches it (real
		// data at this exact (range, height) combination would be written, not excluded). A raw
		// `elev < loElevDeg` comparison would shade this regardless of the pad and could paint the
		// wedge directly over data the loop above legitimately found.
		const height2 = 3000 * Math.tan(9.5 * DEG);
		const r = rasterizeCrossSection(scans, palette, {
			widthPx: 12,
			heightPx: 1,
			maxHeightM: 2 * height2,
			line,
			maxProjection: { perpMinM: -5000, perpMaxM: 5000 }
		});
		// column 9 (east, along=+3000, perp=0 -- reachable since the window brackets 0).
		expect(Array.from(r.rgba.slice(9 * 4, 9 * 4 + 4))).not.toEqual(Array.from(NO_COVERAGE_RGBA));
	});
});
