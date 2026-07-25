import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { beamHeightRangeM } from '$lib/geo/height';
import { columnGridDims, raysMatch, finalizeGroundScan } from './columnCommon';
import type { ProductResult } from './types';

/**
 * Column maximum — port of `TMaxsScan.ProcessMove` (`legacy/Units/MaxsScan.pas`).
 *
 * Scans every elevation PPI of one channel and, per ground cell, tracks the greatest reflectivity
 * seen in the column and the beam-centre height at which it occurred. Legacy `MaxsScan` reports
 * only the height (a `unKM`-tagged-but-metres scan); the P2 scope item is worded "column max
 * reflectivity", so this returns BOTH: `height` (metres, matching legacy) and `columnMax` (the
 * max reflectivity value itself, the more common product). One pass produces both.
 *
 * Height per gate = beam centre `min + (max−min)/2` (legacy hard-codes the midpoint, i.e. tops
 * with location 0.5). Comparison is in value space (raw dBZ code order in legacy). Band
 * `[bottomM, topM]` gates which heights count.
 */

export interface MaxsOptions {
	beamWidthDeg: number;
	bottomM?: number;
	topM?: number;
	siteAltM?: number;
	/** Unit label for the columnMax value (e.g. 'dBZ'). Default 'dBZ'. */
	valueUnit?: string;
}

export interface MaxsResult {
	/** Height (metres) of the column-max reflectivity. */
	height: ProductResult;
	/** The column-max reflectivity value itself. */
	columnMax: ProductResult;
}

export function computeMaxs(scans: Scan[], opts: MaxsOptions): MaxsResult {
	const dims = columnGridDims(scans);
	const { ref, numRays, numGates } = dims;
	const bottomM = opts.bottomM ?? -Infinity;
	const topM = opts.topM ?? Infinity;
	const siteAltM = opts.siteAltM ?? 0;

	const maxVal = new Float32Array(numRays * numGates).fill(NaN);
	const maxHeight = new Float32Array(numRays * numGates);
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
			const meanH = min + (max - min) / 2;
			if (meanH < bottomM) continue;
			if (meanH > topM) break;
			const groundGate = Math.round(r * cos);
			if (groundGate < 0 || groundGate >= numGates) continue;
			for (let a = 0; a < numRays; a++) {
				const srcIdx = a * s.numGates + r;
				if (s.cells.flags[srcIdx] !== CELL_FLAG_OK) continue;
				const v = s.cells.values[srcIdx];
				const dstIdx = a * numGates + groundGate;
				if (Number.isNaN(maxVal[dstIdx]) || v > maxVal[dstIdx]) {
					maxVal[dstIdx] = v;
					maxHeight[dstIdx] = meanH;
				}
			}
		}
	}

	const heightCells = createCells(numRays, numGates);
	const valueCells = createCells(numRays, numGates);
	const noData = cellFlagCode('no-data');
	for (let i = 0; i < maxVal.length; i++) {
		if (Number.isNaN(maxVal[i])) {
			heightCells.flags[i] = noData;
			valueCells.flags[i] = noData;
		} else {
			heightCells.values[i] = maxHeight[i];
			heightCells.flags[i] = CELL_FLAG_OK;
			valueCells.values[i] = maxVal[i];
			valueCells.flags[i] = CELL_FLAG_OK;
		}
	}
	return {
		height: { scan: finalizeGroundScan(dims, heightCells), unit: 'm', skipped },
		columnMax: {
			scan: finalizeGroundScan(dims, valueCells),
			unit: opts.valueUnit ?? 'dBZ',
			skipped
		}
	};
}
