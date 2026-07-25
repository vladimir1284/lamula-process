import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { beamHeightRangeM } from '$lib/geo/height';
import { columnGridDims, raysMatch, finalizeGroundScan } from './columnCommon';
import type { ProductResult } from './types';

/**
 * VIL — Vertically Integrated Liquid. Port of `TVILScan` (`legacy/Units/VILScan.pas`).
 *
 *   VIL = C1 · Σ_layers ( Z^C2 · thickness_km ),   Z = 10^(dBZ/10)
 *
 * Constants are the legacy build's settings defaults `C1 = 0.00524`, `C2 = 0.57143` (≈ 4/7, the
 * classic Z^(4/7)); both configurable. Per elevation PPI, a gate contributes if its beam overlaps
 * the height band `[bottomM, topM]` (legacy `if Max<=Bottom continue; if Min>=Top break`), using
 * the **full** beam thickness `(max−min)` (not clamped to the band — faithful to legacy), in km.
 * Values summed in linear Z per `10^(dBZ/10)`. Output unit kg/m².
 *
 * Input moment must be reflectivity (legacy forces `unDBZ`); values are treated as dBZ.
 */

export const VIL_C1_DEFAULT = 0.00524;
export const VIL_C2_DEFAULT = 0.57143;

export interface VilOptions {
	beamWidthDeg: number;
	bottomM: number;
	topM: number;
	c1?: number;
	c2?: number;
	siteAltM?: number;
}

export function computeVil(scans: Scan[], opts: VilOptions): ProductResult {
	const dims = columnGridDims(scans);
	const { ref, numRays, numGates } = dims;
	const c1 = opts.c1 ?? VIL_C1_DEFAULT;
	const c2 = opts.c2 ?? VIL_C2_DEFAULT;
	const siteAltM = opts.siteAltM ?? 0;

	const sum = new Float64Array(numRays * numGates);
	const touched = new Uint8Array(numRays * numGates);
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
			if (max <= opts.bottomM) continue;
			if (min >= opts.topM) break;
			const thicknessKm = (max - min) / 1000;
			const groundGate = Math.round(r * cos);
			if (groundGate < 0 || groundGate >= numGates) continue;
			for (let a = 0; a < numRays; a++) {
				const srcIdx = a * s.numGates + r;
				if (s.cells.flags[srcIdx] !== CELL_FLAG_OK) continue;
				const z = Math.pow(10, s.cells.values[srcIdx] / 10);
				const dstIdx = a * numGates + groundGate;
				sum[dstIdx] += Math.pow(z, c2) * thicknessKm;
				touched[dstIdx] = 1;
			}
		}
	}

	const cells = createCells(numRays, numGates);
	const noData = cellFlagCode('no-data');
	for (let i = 0; i < cells.values.length; i++) {
		if (touched[i]) {
			cells.values[i] = c1 * sum[i];
			cells.flags[i] = CELL_FLAG_OK;
		} else {
			cells.flags[i] = noData;
		}
	}
	return { scan: finalizeGroundScan(dims, cells), unit: 'kg/m²', skipped };
}
