import { describe, it, expect } from 'vitest';
import { getCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { computeCappi } from './cappi';

const WIDE = { bottomM: -100_000, topM: 100_000, beamWidthDeg: 1, moment: 'dBZ' as const };

describe('computeCappi', () => {
	it('produces a ground-range scan (elevation 0) with inherited rays', () => {
		const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0 });
		const { scan: cappi } = computeCappi([scan], WIDE);
		expect(cappi.angleDeg).toBe(0);
		expect(cappi.numRays).toBe(4);
		expect(cappi.numGates).toBe(3);
	});

	it('reduces a single elevation-0 scan to itself within a wide slab', () => {
		// cos0 = 1 so ground gate == source gate; single sample round-trips through linear space
		const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0 });
		const { scan: cappi } = computeCappi([scan], WIDE);
		// cell (ray 1, gate 2) had value 1*100+2 = 102
		expect(getCell(cappi.cells, 1, 2).value).toBeCloseTo(102, 4);
		expect(getCell(cappi.cells, 1, 2).flag).toBe('ok');
	});

	it('averages overlapping cells in linear Z space, not dB space', () => {
		const a = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 20 });
		const b = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 40 });
		const { scan: cappi } = computeCappi([a, b], WIDE);
		// (Z20 + Z40)/2 = (100 + 10000)/2 = 5050 -> 10*log10(5050) ≈ 37.03 dBZ (NOT (20+40)/2=30)
		expect(getCell(cappi.cells, 0, 1).value).toBeCloseTo(37.03, 2);
	});

	it('marks cells outside the altitude slab as no-data', () => {
		const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0 });
		const { scan: cappi } = computeCappi([scan], {
			bottomM: 50_000,
			topM: 60_000, // 50-60 km altitude: no low-elevation gate reaches it
			beamWidthDeg: 1,
			moment: 'dBZ'
		});
		for (let r = 0; r < cappi.numRays; r++)
			for (let g = 0; g < cappi.numGates; g++)
				expect(getCell(cappi.cells, r, g).flag).toBe('no-data');
	});

	it('skips scans whose ray count does not align', () => {
		const a = makeScan({ numRays: 4, numGates: 3, angleDeg: 0 });
		const b = makeScan({ numRays: 8, numGates: 3, angleDeg: 1 });
		const { skipped } = computeCappi([a, b], WIDE);
		expect(skipped).toBe(1);
	});
});
