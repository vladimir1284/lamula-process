import { describe, it, expect } from 'vitest';
import { getCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { beamHeightRangeM } from '$lib/geo/height';
import { computeVil, VIL_C1_DEFAULT, VIL_C2_DEFAULT } from './vil';

const BW = 1;
const WIDE = { bottomM: -100_000, topM: 100_000, beamWidthDeg: BW };

// independent VIL of a single beam layer at slant/elev with reflectivity dBZ
function singleLayerVil(
	slantM: number,
	elevDeg: number,
	dBZ: number,
	c1 = VIL_C1_DEFAULT,
	c2 = VIL_C2_DEFAULT
): number {
	const { min, max } = beamHeightRangeM(slantM, elevDeg, BW);
	const thicknessKm = (max - min) / 1000;
	const z = Math.pow(10, dBZ / 10);
	return c1 * Math.pow(z, c2) * thicknessKm;
}

describe('computeVil', () => {
	it('emits a ground-range scan in kg/m²', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan, unit } = computeVil([s], WIDE);
		expect(scan.angleDeg).toBe(0);
		expect(unit).toBe('kg/m²');
	});

	it('integrates one beam layer to C1·Z^C2·thickness_km', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan } = computeVil([s], WIDE);
		// gate 1, slant 1000 m, single elevation-0 layer
		expect(getCell(scan.cells, 0, 1).value).toBeCloseTo(singleLayerVil(1000, 0, 30), 8);
	});

	it('sums linearly across elevation layers in the same column', () => {
		const a = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const b = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan } = computeVil([a, b], WIDE);
		// identical layers → double the single-layer VIL (same ground gate, cos0=1)
		expect(getCell(scan.cells, 0, 1).value).toBeCloseTo(2 * singleLayerVil(1000, 0, 30), 8);
	});

	it('honours configurable C1/C2', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan } = computeVil([s], { ...WIDE, c1: 0.01, c2: 0.5 });
		expect(getCell(scan.cells, 0, 1).value).toBeCloseTo(singleLayerVil(1000, 0, 30, 0.01, 0.5), 8);
	});

	it('marks columns with no data as no-data', () => {
		const s = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const { scan } = computeVil([s], { bottomM: 50_000, topM: 60_000, beamWidthDeg: BW });
		expect(getCell(scan.cells, 0, 1).flag).toBe('no-data');
	});
});
