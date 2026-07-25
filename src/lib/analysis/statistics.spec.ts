import { describe, it, expect } from 'vitest';
import { setCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { computeStatistics } from './statistics';
import type { Region } from './region';

describe('computeStatistics', () => {
	it('counts region cells and weights area by annular sector', () => {
		// 4 rays (N/E/S/W), gates at range 0/1000/2000 m; uniform 30 dBZ
		const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 });
		const region: Region = { kind: 'circle', name: 'r15', cxM: 0, cyM: 0, radiusM: 1500 };
		const s = computeStatistics(scan, { region, moment: 'dBZ', unit: 'dBZ', threshold: 20 });

		// gate 0 (r=0) + gate 1 (r=1000) inside for all 4 rays; gate 2 (r=2000) outside
		expect(s.count).toBe(8);
		expect(s.coatingPct).toBe(100); // all above 20
		expect(s.max).toBe(30);
		expect(s.min).toBe(30);
		expect(s.meanAll).toBeCloseTo(30, 6);
		expect(s.stdDev).toBeCloseTo(0, 6);
		// area: only gate-1 cells have area (gate 0 is at range 0). 4 · 1000·1000·(π/2) m²
		const perCellKm2 = (1000 * 1000 * (Math.PI / 2)) / 1e6;
		expect(s.areaKm2).toBeCloseTo(4 * perCellKm2, 4);
		// volume: Σ area·Z /1e9, Z(30 dBZ)=1000
		expect(s.volumeMm3).toBeCloseTo((4 * 1000 * 1000 * (Math.PI / 2) * 1000) / 1e9, 4);
	});

	it('averages reflectivity in linear Z space, not dB', () => {
		// 2 rays (N,S); blank gate 0, put 20 dBZ north gate1 and 40 dBZ south gate1
		const scan = makeScan({ numRays: 2, numGates: 2, gateLengthM: 1000, angleDeg: 0, fill: () => 0 });
		setCell(scan.cells, 0, 0, 0, 'no-data');
		setCell(scan.cells, 1, 0, 0, 'no-data');
		setCell(scan.cells, 0, 1, 20, 'ok');
		setCell(scan.cells, 1, 1, 40, 'ok');
		const region: Region = { kind: 'rectangle', name: 'box', minXM: -100, minYM: -3000, maxXM: 100, maxYM: 3000 };
		const s = computeStatistics(scan, { region, moment: 'dBZ', unit: 'dBZ', threshold: 0 });
		expect(s.count).toBe(2);
		// (Z20 + Z40)/2 = 5050 → 10·log10 ≈ 37.03 dBZ, not (20+40)/2 = 30
		expect(s.meanAll).toBeCloseTo(37.03, 2);
		expect(s.median).toBe(30); // median of native [20,40]
	});

	it('coating is the fraction above threshold', () => {
		const scan = makeScan({ numRays: 4, numGates: 2, gateLengthM: 1000, angleDeg: 0, fill: () => 0 });
		// half the ring above threshold at gate 1
		setCell(scan.cells, 0, 1, 30, 'ok');
		setCell(scan.cells, 1, 1, 30, 'ok');
		setCell(scan.cells, 2, 1, 5, 'ok');
		setCell(scan.cells, 3, 1, 5, 'ok');
		const region: Region = { kind: 'circle', name: 'r', cxM: 0, cyM: 0, radiusM: 1500 };
		const s = computeStatistics(scan, { region, moment: 'dBZ', unit: 'dBZ', threshold: 20 });
		// gate 0 (range 0) all four + gate 1 all four = 8 cells; 2 above 20 → 25%
		expect(s.count).toBe(8);
		expect(s.coatingPct).toBe(25);
	});
});
