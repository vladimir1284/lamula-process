import type { Scan } from '$lib/domain/types';
import { createCells } from '$lib/domain/cells';

/**
 * Synthetic RHI (Range-Height Indicator) Scan builder for tests and the RHI viewer demo.
 *
 * An RHI scan sweeps elevation at a fixed azimuth: `angleDeg` is the azimuth, and each ray's
 * start/stop angles are *elevation* bounds (see domain/types.ts). No real RHI fixture exists in
 * this project (all three parsers only carry volume PPI), so this is the only oracle available —
 * the RHI geometry is verified against data generated here, not against a real radar file.
 */
export interface MakeRhiOpts {
	/** Ray centre elevations in degrees (bottom to top). */
	elevationsDeg?: number[];
	numGates?: number;
	gateLengthM?: number;
	rangeToFirstGateM?: number;
	azimuthDeg?: number;
	fill?: (ray: number, gate: number) => number;
}

export function makeRhiScan(opts: MakeRhiOpts = {}): Scan {
	const elevs = opts.elevationsDeg ?? [0.5, 1.5, 2.5, 3.5, 5];
	const numRays = elevs.length;
	const numGates = opts.numGates ?? 100;
	const gateLengthM = opts.gateLengthM ?? 1000;
	const rangeToFirstGateM = opts.rangeToFirstGateM ?? 0;
	const azimuthDeg = opts.azimuthDeg ?? 0;
	const fill = opts.fill ?? ((ray, gate) => ray * 100 + gate);

	const rayStartAnglesDeg = new Float32Array(numRays);
	const rayStopAnglesDeg = new Float32Array(numRays);
	for (let i = 0; i < numRays; i++) {
		const lower = i === 0 ? elevs[i] - (elevs[1] - elevs[0]) / 2 : (elevs[i - 1] + elevs[i]) / 2;
		const upper =
			i === numRays - 1 ? elevs[i] + (elevs[i] - elevs[i - 1]) / 2 : (elevs[i] + elevs[i + 1]) / 2;
		rayStartAnglesDeg[i] = lower;
		rayStopAnglesDeg[i] = upper;
	}

	const cells = createCells(numRays, numGates);
	for (let r = 0; r < numRays; r++)
		for (let g = 0; g < numGates; g++) cells.values[r * numGates + g] = fill(r, g);

	return {
		id: 0,
		angleDeg: azimuthDeg,
		rangeToFirstGateM,
		gateLengthM,
		numRays,
		numGates,
		rayStartAnglesDeg,
		rayStopAnglesDeg,
		cells
	};
}
