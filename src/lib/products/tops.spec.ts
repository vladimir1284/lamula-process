import { describe, it, expect } from 'vitest';
import { getCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { beamHeightRangeM } from '$lib/geo/height';
import { computeTops } from './tops';

const BW = 1;

// beam-centre height (location 0.5) at a given slant/elevation — independent of the product code
function centreH(slantM: number, elevDeg: number): number {
	const { min, max } = beamHeightRangeM(slantM, elevDeg, BW);
	return (min + max) / 2;
}

describe('computeTops', () => {
	it('emits a ground-range scan (elevation 0, metres) with inherited rays', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan, unit } = computeTops([s], { minValue: 20, beamWidthDeg: BW });
		expect(scan.angleDeg).toBe(0);
		expect(scan.numRays).toBe(4);
		expect(unit).toBe('m');
	});

	it('keeps the greatest beam height above threshold across elevations', () => {
		// two low tilts so round(r·cosθ)=r for r≤2; higher tilt wins the top height
		const lo = makeScan({
			numRays: 4,
			numGates: 3,
			gateLengthM: 1000,
			angleDeg: 1,
			fill: () => 30
		});
		const hi = makeScan({
			numRays: 4,
			numGates: 3,
			gateLengthM: 1000,
			angleDeg: 2,
			fill: () => 30
		});
		const { scan } = computeTops([lo, hi], { minValue: 20, beamWidthDeg: BW });
		// gate 2, slant 2000 m, winner = elevation 2°
		expect(getCell(scan.cells, 0, 2).value).toBeCloseTo(centreH(2000, 2), 3);
		expect(getCell(scan.cells, 0, 2).flag).toBe('ok');
	});

	it('drops gates below the reflectivity threshold to no-data', () => {
		// value = gate*10 → gate 0:0, 1:10, 2:20; threshold 15 keeps only gate 2
		const s = makeScan({
			numRays: 4,
			numGates: 3,
			gateLengthM: 1000,
			angleDeg: 0,
			fill: (_r, g) => g * 10
		});
		const { scan } = computeTops([s], { minValue: 15, beamWidthDeg: BW });
		expect(getCell(scan.cells, 0, 0).flag).toBe('no-data');
		expect(getCell(scan.cells, 0, 1).flag).toBe('no-data');
		expect(getCell(scan.cells, 0, 2).flag).toBe('ok');
	});

	it('respects the height band', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan } = computeTops([s], {
			minValue: 20,
			beamWidthDeg: BW,
			bottomM: 50_000,
			topM: 60_000
		});
		for (let r = 0; r < scan.numRays; r++)
			for (let g = 0; g < scan.numGates; g++)
				expect(getCell(scan.cells, r, g).flag).toBe('no-data');
	});

	it('reports height at the requested beam fraction', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { min, max } = beamHeightRangeM(2000, 0, BW);
		const top = computeTops([s], { minValue: 20, beamWidthDeg: BW, location: 1 });
		const bot = computeTops([s], { minValue: 20, beamWidthDeg: BW, location: 0 });
		expect(getCell(top.scan.cells, 0, 2).value).toBeCloseTo(max, 3);
		expect(getCell(bot.scan.cells, 0, 2).value).toBeCloseTo(min, 3);
	});

	it('skips scans whose ray count does not align', () => {
		const a = makeScan({ numRays: 4, numGates: 3, angleDeg: 0, fill: () => 30 });
		const b = makeScan({ numRays: 8, numGates: 3, angleDeg: 1, fill: () => 30 });
		expect(computeTops([a, b], { minValue: 20, beamWidthDeg: BW }).skipped).toBe(1);
	});
});
