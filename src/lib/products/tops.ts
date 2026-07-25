import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { beamHeightRangeM } from '$lib/geo/height';
import { columnGridDims, raysMatch, finalizeGroundScan } from './columnCommon';
import type { ProductResult } from './types';

/**
 * Echo tops — port of `TTopsScan.ProcessMove` (`legacy/Units/TopsScan.pas`).
 *
 * For each ground cell, the echo top is the *greatest* beam height at which reflectivity meets a
 * threshold, scanning every elevation PPI of one channel. The reported height per source gate is
 * interpolated at fraction `location` between the beam's bottom and top edge
 * (`meanH = min + location·(max−min)`, legacy `round(Min + fLocation*(Max-Min))`); the legacy
 * `Location` config is 0..100, here a 0..1 fraction (default 0.5 = beam centre).
 *
 * Threshold compare is in value space (dBZ), matching the legacy `Cell[R,A] >= Minimun` on raw
 * codes — code order is monotonic in dBZ. Layer band `[bottomM, topM]` gates which heights count
 * (legacy `continue`/`break`; break relies on beam height rising monotonically with range).
 *
 * Output cell value = echo-top height in **metres** (legacy declared `unKM` but stored metres via
 * `MeasureCode(MeanH, unM)`; we normalise to an explicit metre unit, see docs decision 4).
 */

export interface TopsOptions {
	/** Minimum reflectivity (physical, e.g. dBZ) for a gate to contribute an echo top. */
	minValue: number;
	beamWidthDeg: number;
	/** Fraction 0..1 within the beam at which to report the height. Default 0.5 (centre). */
	location?: number;
	/** Height band (metres) the top must fall within. Default [0, +∞). */
	bottomM?: number;
	topM?: number;
	siteAltM?: number;
}

export function computeTops(scans: Scan[], opts: TopsOptions): ProductResult {
	const dims = columnGridDims(scans);
	const { ref, numRays, numGates } = dims;
	const location = opts.location ?? 0.5;
	const bottomM = opts.bottomM ?? -Infinity;
	const topM = opts.topM ?? Infinity;
	const siteAltM = opts.siteAltM ?? 0;

	const height = new Float32Array(numRays * numGates).fill(NaN);
	let skipped = 0;

	for (const s of scans) {
		if (!raysMatch(ref, s)) {
			skipped++;
			continue;
		}
		const cos = Math.cos((s.angleDeg * Math.PI) / 180);
		for (let r = 0; r < s.numGates; r++) {
			const slant = s.rangeToFirstGateM + r * s.gateLengthM;
			const { min, max } = beamHeightRangeM(slant, s.angleDeg, opts.beamWidthDeg, siteAltM);
			const meanH = min + location * (max - min);
			if (meanH < bottomM) continue;
			if (meanH > topM) break; // higher gates are higher still
			const groundGate = Math.round(r * cos);
			if (groundGate < 0 || groundGate >= numGates) continue;
			for (let a = 0; a < numRays; a++) {
				const srcIdx = a * s.numGates + r;
				if (s.cells.flags[srcIdx] !== CELL_FLAG_OK) continue;
				if (s.cells.values[srcIdx] < opts.minValue) continue;
				const dstIdx = a * numGates + groundGate;
				if (Number.isNaN(height[dstIdx]) || meanH > height[dstIdx]) height[dstIdx] = meanH;
			}
		}
	}

	const cells = createCells(numRays, numGates);
	const noData = cellFlagCode('no-data');
	for (let i = 0; i < cells.values.length; i++) {
		if (Number.isNaN(height[i])) {
			cells.flags[i] = noData;
		} else {
			cells.values[i] = height[i];
			cells.flags[i] = CELL_FLAG_OK;
		}
	}
	return { scan: finalizeGroundScan(dims, cells), unit: 'm', skipped };
}
