import { describe, it, expect } from 'vitest';
import { getCell, setCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { computeRainRate, dbzToRainRate, kdpToRainRate } from './rainRate';

describe('Z-R / KDP formulas', () => {
	it('Z-R: R = (Z/A)^(1/B) with defaults A=300 B=1.4', () => {
		// dBZ 30 → Z=1000 → (1000/300)^(1/1.4)
		expect(dbzToRainRate(30)).toBeCloseTo(Math.pow(1000 / 300, 1 / 1.4), 8);
	});
	it('Z-R honours custom coefficients', () => {
		expect(dbzToRainRate(40, 200, 1.6)).toBeCloseTo(Math.pow(10000 / 200, 1 / 1.6), 8);
	});
	it('KDP: sign-preserving R = A·|K|^B', () => {
		expect(kdpToRainRate(2)).toBeCloseTo(40.7 * Math.pow(2, 0.866), 8);
		expect(kdpToRainRate(-2)).toBeCloseTo(-40.7 * Math.pow(2, 0.866), 8);
	});
});

describe('computeRainRate', () => {
	it('maps a dBZ scan to mm/h, preserving geometry', () => {
		const s = makeScan({
			numRays: 4,
			numGates: 3,
			gateLengthM: 500,
			angleDeg: 1.5,
			fill: () => 30
		});
		const { scan, unit } = computeRainRate(s);
		expect(unit).toBe('mm/h');
		expect(scan.angleDeg).toBe(1.5);
		expect(scan.gateLengthM).toBe(500);
		expect(getCell(scan.cells, 0, 0).value).toBeCloseTo(dbzToRainRate(30), 4);
	});

	it('passes non-ok cells through as their flag with no rain', () => {
		const s = makeScan({ numRays: 4, numGates: 3, angleDeg: 0, fill: () => 30 });
		setCell(s.cells, 1, 1, 0, 'no-data');
		const { scan } = computeRainRate(s);
		expect(getCell(scan.cells, 1, 1).flag).toBe('no-data');
	});
});
