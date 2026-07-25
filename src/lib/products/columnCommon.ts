import type { Scan } from '$lib/domain/types';

/**
 * Shared scaffolding for the "column" derived products (echo tops, column max, VIL): all consume
 * every elevation PPI of one channel and collapse it, per ground-range gate, into a single
 * ground-range polar scan. This is the same projection CAPPI does (`round(R·cosθ)`), factored out
 * so tops/maxs/vil don't each re-derive the grid dimensions and output-scan boilerplate.
 */

export interface ColumnGridDims {
	/** First scan, used as the ray/geometry reference. */
	ref: Scan;
	numRays: number;
	/** Widest gate count across elevations; every ground gate (≤ source gate) has a home. */
	numGates: number;
}

export function columnGridDims(scans: Scan[]): ColumnGridDims {
	if (scans.length === 0) throw new Error('column product: no scans');
	const ref = scans[0];
	const numGates = scans.reduce((m, s) => Math.max(m, s.numGates), 0);
	return { ref, numRays: ref.numRays, numGates };
}

/** True when a source scan shares the reference ray structure (else it must be skipped). */
export function raysMatch(ref: Scan, s: Scan): boolean {
	return s.numRays === ref.numRays;
}

/**
 * Wrap a filled `Cells` grid into a ground-range output scan. `angleDeg` is 0: the gate index is
 * already ground range, so the raster path must not re-project by an elevation cosine.
 */
export function finalizeGroundScan(dims: ColumnGridDims, cells: Scan['cells']): Scan {
	const { ref, numRays, numGates } = dims;
	return {
		id: ref.id,
		angleDeg: 0,
		rangeToFirstGateM: ref.rangeToFirstGateM,
		gateLengthM: ref.gateLengthM,
		numRays,
		numGates,
		rayStartAnglesDeg: ref.rayStartAnglesDeg.slice(),
		rayStopAnglesDeg: ref.rayStopAnglesDeg.slice(),
		cells
	};
}
