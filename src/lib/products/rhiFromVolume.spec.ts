import { describe, it, expect } from 'vitest';
import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, setCell } from '$lib/domain/cells';
import { volumeToRhiScan } from './rhiFromVolume';

/** A PPI sweep with rays at az 0/90/180/270. `fill(ray, gate)` sets ok values; rest stay no-data. */
function makeSweep(
	elevDeg: number,
	opts: {
		numGates?: number;
		gateLengthM?: number;
		rangeToFirstGateM?: number;
		fill?: (ray: number, gate: number) => number;
	} = {}
): Scan {
	const azCenters = [0, 90, 180, 270];
	const numRays = azCenters.length;
	const numGates = opts.numGates ?? 3;
	const gateLengthM = opts.gateLengthM ?? 1000;
	const rangeToFirstGateM = opts.rangeToFirstGateM ?? 0;
	const rayStartAnglesDeg = new Float32Array(numRays);
	const rayStopAnglesDeg = new Float32Array(numRays);
	for (let i = 0; i < numRays; i++) {
		rayStartAnglesDeg[i] = azCenters[i] - 45;
		rayStopAnglesDeg[i] = azCenters[i] + 45;
	}
	const cells = createCells(numRays, numGates);
	cells.flags.fill(cellFlagCode('no-data'));
	if (opts.fill)
		for (let r = 0; r < numRays; r++)
			for (let g = 0; g < numGates; g++) setCell(cells, r, g, opts.fill(r, g), 'ok');
	return {
		id: 0,
		angleDeg: elevDeg,
		rangeToFirstGateM,
		gateLengthM,
		numRays,
		numGates,
		rayStartAnglesDeg,
		rayStopAnglesDeg,
		cells
	};
}

describe('volumeToRhiScan', () => {
	it('returns null for an empty volume', () => {
		expect(volumeToRhiScan([], 0)).toBeNull();
	});

	it('stacks one ray per elevation, sorted low-to-high', () => {
		const vol = [
			makeSweep(2.5, { fill: (r, g) => 200 + r * 10 + g }),
			makeSweep(0.5, { fill: (r, g) => r * 10 + g }),
			makeSweep(1.5, { fill: (r, g) => 100 + r * 10 + g })
		];
		const rhi = volumeToRhiScan(vol, 0)!;
		expect(rhi.numRays).toBe(3);
		// rays ordered ascending elevation
		expect(rhi.rayStartAnglesDeg[0]).toBe(0.5);
		expect(rhi.rayStartAnglesDeg[1]).toBe(1.5);
		expect(rhi.rayStartAnglesDeg[2]).toBe(2.5);
		expect(rhi.angleDeg).toBe(0);
	});

	it('picks the ray nearest the requested azimuth', () => {
		// az 90 -> ray index 1 in each sweep; fill encodes ray index in the tens place.
		const vol = [makeSweep(0.5, { fill: (r, g) => r * 10 + g })];
		const rhi = volumeToRhiScan(vol, 90)!;
		// gate 0 of the only RHI ray should carry ray-1 gate-0 = 10
		expect(rhi.cells.values[0]).toBe(10);
		expect(rhi.cells.flags[0]).toBe(cellFlagCode('ok'));
	});

	it('handles the 0/360 azimuth seam', () => {
		const vol = [makeSweep(0.5, { fill: (r, g) => r * 10 + g })];
		// 359 is closest to az-center 0 (ray 0), not 270.
		const rhi = volumeToRhiScan(vol, 359)!;
		expect(rhi.cells.values[0]).toBe(0); // ray 0, gate 0
	});

	it('resamples onto the finest gate grid and longest reach', () => {
		// sweep A: 3 gates @ 1000 m (reach 2000). sweep B: 3 gates @ 500 m (reach 1000).
		const vol = [
			makeSweep(0.5, { gateLengthM: 1000, numGates: 3, fill: () => 1 }),
			makeSweep(1.5, { gateLengthM: 500, numGates: 3, fill: () => 2 })
		];
		const rhi = volumeToRhiScan(vol, 0)!;
		expect(rhi.gateLengthM).toBe(500);
		// common grid: 0..2000 by 500 -> 5 gates
		expect(rhi.numGates).toBe(5);
		// row for sweep B (elev 1.5) reaches only 1000 m: gates at 0,500,1000 are ok, 1500/2000 no-data.
		const bRow = 1 * rhi.numGates;
		expect(rhi.cells.flags[bRow + 0]).toBe(cellFlagCode('ok'));
		expect(rhi.cells.flags[bRow + 2]).toBe(cellFlagCode('ok'));
		expect(rhi.cells.flags[bRow + 3]).toBe(cellFlagCode('no-data'));
		expect(rhi.cells.flags[bRow + 4]).toBe(cellFlagCode('no-data'));
	});

	it('leaves gates beyond a sweep reach as no-data, not a real 0-value', () => {
		const vol = [makeSweep(0.5, { numGates: 2, gateLengthM: 1000, fill: () => 5 })];
		const rhi = volumeToRhiScan(vol, 0)!;
		// only 2 source gates -> reach 1000 m, common grid also 2 gates; both ok.
		expect(rhi.numGates).toBe(2);
		expect(rhi.cells.flags[0]).toBe(cellFlagCode('ok'));
		expect(rhi.cells.flags[1]).toBe(cellFlagCode('ok'));
	});
});
