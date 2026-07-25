import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { finalizeGroundScan, columnGridDims } from './columnCommon';
import type { ProductResult } from './types';

/**
 * Rain rate — port of the Z-R / KDP lookup in `legacy/Units/RainTable.pas`.
 *
 * Z-R (`Create_ZR`): `R = (Z/A)^(1/B)` with `Z = 10^(dBZ/10)`. The legacy default coefficients
 * (`legacy/Units/Configuration.pas`) are `A = 300`, `B = 1.4` (Marshall-Palmer-ish for this
 * build), both config-editable — NOT hard-coded, so exposed as options.
 *
 * KDP-R (`Create_KDP`): `R = A·|K|^B`, sign-preserving (`R<0` when `K<0`). Defaults `A = 40.7`,
 * `B = 0.866`.
 *
 * Output unit is mm/h. Cells that are not `ok` pass their flag through unchanged (legacy leaves
 * zero/no-data codes untouched — no rain where there is no echo).
 */

export const ZR_A_DEFAULT = 300;
export const ZR_B_DEFAULT = 1.4;
export const KDP_A_DEFAULT = 40.7;
export const KDP_B_DEFAULT = 0.866;

export function dbzToRainRate(dBZ: number, a = ZR_A_DEFAULT, b = ZR_B_DEFAULT): number {
	const z = Math.pow(10, dBZ / 10);
	return Math.pow(z / a, 1 / b);
}

export function kdpToRainRate(kdp: number, a = KDP_A_DEFAULT, b = KDP_B_DEFAULT): number {
	return kdp >= 0 ? a * Math.pow(kdp, b) : -a * Math.pow(-kdp, b);
}

export interface RainRateOptions {
	/** Source moment: 'dBZ'/'dBuZ' → Z-R, anything else treated as KDP. Default Z-R. */
	kind?: 'zr' | 'kdp';
	a?: number;
	b?: number;
}

/**
 * Transform one polar scan (same geometry, NOT ground-projected) into a rain-rate scan in mm/h.
 * Used directly for an instantaneous rate display and internally by accumulation.
 */
export function computeRainRate(scan: Scan, opts: RainRateOptions = {}): ProductResult {
	const kind = opts.kind ?? 'zr';
	const convert =
		kind === 'zr'
			? (v: number) => dbzToRainRate(v, opts.a ?? ZR_A_DEFAULT, opts.b ?? ZR_B_DEFAULT)
			: (v: number) => kdpToRainRate(v, opts.a ?? KDP_A_DEFAULT, opts.b ?? KDP_B_DEFAULT);

	const cells = createCells(scan.numRays, scan.numGates);
	const okCode = cellFlagCode('ok');
	for (let i = 0; i < cells.values.length; i++) {
		if (scan.cells.flags[i] === CELL_FLAG_OK) {
			cells.values[i] = convert(scan.cells.values[i]);
			cells.flags[i] = okCode;
		} else {
			cells.flags[i] = scan.cells.flags[i];
		}
	}
	// Reuse the ground-scan wrapper but keep this scan's own geometry (it is not projected).
	const dims = columnGridDims([scan]);
	const out = finalizeGroundScan(dims, cells);
	out.angleDeg = scan.angleDeg;
	out.gateLengthM = scan.gateLengthM;
	out.rangeToFirstGateM = scan.rangeToFirstGateM;
	return { scan: out, unit: 'mm/h', skipped: 0 };
}
