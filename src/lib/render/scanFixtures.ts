import type { Scan } from '$lib/domain/types';
import { createCells } from '$lib/domain/cells';

/**
 * Synthetic Scan builders for tests. Rays are laid out uniformly around the compass; unless a
 * `fill` is given, each cell's value is `ray * 100 + gate` so a sample can be traced back to a
 * specific (ray, gate). Angle convention matches the renderer: ray 0 centred on North (0°),
 * increasing clockwise.
 */
export interface MakeScanOpts {
	numRays?: number;
	numGates?: number;
	gateLengthM?: number;
	rangeToFirstGateM?: number;
	angleDeg?: number; // elevation for a PPI scan
	fill?: (ray: number, gate: number) => number;
}

export function makeScan(opts: MakeScanOpts = {}): Scan {
	const numRays = opts.numRays ?? 4;
	const numGates = opts.numGates ?? 3;
	const gateLengthM = opts.gateLengthM ?? 1000;
	const rangeToFirstGateM = opts.rangeToFirstGateM ?? 0;
	const angleDeg = opts.angleDeg ?? 0;
	const fill = opts.fill ?? ((ray, gate) => ray * 100 + gate);

	const step = 360 / numRays;
	const rayStartAnglesDeg = new Float32Array(numRays);
	const rayStopAnglesDeg = new Float32Array(numRays);
	for (let i = 0; i < numRays; i++) {
		const center = i * step;
		rayStartAnglesDeg[i] = center - step / 2;
		rayStopAnglesDeg[i] = center + step / 2;
	}

	const cells = createCells(numRays, numGates);
	for (let r = 0; r < numRays; r++) {
		for (let g = 0; g < numGates; g++) {
			cells.values[r * numGates + g] = fill(r, g);
			// all 'ok' (flag 0) by default
		}
	}

	return {
		id: 0,
		angleDeg,
		rangeToFirstGateM,
		gateLengthM,
		numRays,
		numGates,
		rayStartAnglesDeg,
		rayStopAnglesDeg,
		cells
	};
}
