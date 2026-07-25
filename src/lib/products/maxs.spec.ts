import { describe, it, expect } from 'vitest';
import { getCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { beamHeightRangeM } from '$lib/geo/height';
import { computeMaxs } from './maxs';

const BW = 1;

function centreH(slantM: number, elevDeg: number): number {
	const { min, max } = beamHeightRangeM(slantM, elevDeg, BW);
	return (min + max) / 2;
}

describe('computeMaxs', () => {
	it('returns both column-max value (dBZ) and its height (m)', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { height, columnMax } = computeMaxs([s], { beamWidthDeg: BW });
		expect(height.unit).toBe('m');
		expect(columnMax.unit).toBe('dBZ');
	});

	it('picks the elevation with the largest reflectivity and reports its beam-centre height', () => {
		// lower tilt has the stronger echo → columnMax comes from it, at its (lower) height
		const lo = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 1, fill: () => 40 });
		const hi = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 2, fill: () => 20 });
		const { height, columnMax } = computeMaxs([lo, hi], { beamWidthDeg: BW });
		expect(getCell(columnMax.scan.cells, 0, 2).value).toBeCloseTo(40, 6);
		expect(getCell(height.scan.cells, 0, 2).value).toBeCloseTo(centreH(2000, 1), 3);
	});

	it('marks empty columns no-data in both outputs', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { height, columnMax } = computeMaxs([s], {
			beamWidthDeg: BW,
			bottomM: 50_000,
			topM: 60_000
		});
		expect(getCell(height.scan.cells, 0, 1).flag).toBe('no-data');
		expect(getCell(columnMax.scan.cells, 0, 1).flag).toBe('no-data');
	});
});
