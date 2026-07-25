import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { beamHeightRangeM } from '$lib/geo/height';
import { columnGridDims, raysMatch, finalizeGroundScan } from './columnCommon';
import { dbzToRainRate, ZR_A_DEFAULT, ZR_B_DEFAULT } from './rainRate';
import type { ProductResult } from './types';

/**
 * Precipitation accumulation — port of `TAccumulate` / `TContributionScan`
 * (`legacy/Units/Accumulate.pas`, `ContributionScan.pas`).
 *
 *   accum_mm[cell] = Σ_obs ( Δt_hours(obs) · mean_over_beams( rainRate_mm/h ) )
 *
 * Per observation the rain rate (Z-R) of every gate in the height band `[bottomM, topM]` is
 * averaged onto its ground cell `round(R·cosθ)`, multiplied by that observation's time weight in
 * hours, and summed into the running total. The per-observation duration is
 * `Δt = min(interval, nextObsTime − obsTime)` (legacy caps at `Interval`, default 5 min, so a
 * data gap larger than the interval does not over-accumulate); the last observation uses the full
 * interval. Output unit mm.
 *
 * Pure over frames `{ timeMs, scans }` (dBZ elevation scans of one channel) so it is testable
 * without the Observation/parser stack; the UI extracts frames from a `TimeSpan`.
 */

const MS_PER_HOUR = 3_600_000;
export const DEFAULT_INTERVAL_MS = 5 * 60 * 1000;

export interface AccumFrame {
	timeMs: number;
	/** dBZ elevation scans of the chosen channel for this observation. */
	scans: Scan[];
}

export interface AccumulateOptions {
	beamWidthDeg: number;
	bottomM: number;
	topM: number;
	siteAltM?: number;
	/** Z-R coefficients. */
	zrA?: number;
	zrB?: number;
	/** Per-observation representative duration cap (ms). Default 5 min. */
	intervalMs?: number;
	/** End of accumulation window (ms). Default lastTime + interval. */
	stopTimeMs?: number;
}

export function computeAccumulate(frames: AccumFrame[], opts: AccumulateOptions): ProductResult {
	const usable = frames.filter((f) => f.scans.length > 0).sort((a, b) => a.timeMs - b.timeMs);
	if (usable.length === 0) throw new Error('computeAccumulate: no frames with scans');

	const intervalMs = opts.intervalMs ?? DEFAULT_INTERVAL_MS;
	const intervalHours = intervalMs / MS_PER_HOUR;
	const zrA = opts.zrA ?? ZR_A_DEFAULT;
	const zrB = opts.zrB ?? ZR_B_DEFAULT;
	const siteAltM = opts.siteAltM ?? 0;

	const startMs = usable[0].timeMs;
	const stopMs = opts.stopTimeMs ?? usable[usable.length - 1].timeMs + intervalMs;

	// Reference geometry from the first frame's first scan.
	const dims = columnGridDims(usable[0].scans);
	const { ref, numRays, numGates } = dims;

	const total = new Float64Array(numRays * numGates);
	const touched = new Uint8Array(numRays * numGates);
	let skipped = 0;
	let lastStopMs = startMs;

	for (let i = 0; i < usable.length; i++) {
		const t = usable[i].timeMs;
		if (t > stopMs) break;
		if (t > lastStopMs) lastStopMs = t;
		let nextStopMs = i < usable.length - 1 ? usable[i + 1].timeMs : t + intervalMs;
		if (nextStopMs > stopMs) nextStopMs = stopMs;
		let deltaHours = (nextStopMs - lastStopMs) / MS_PER_HOUR;
		if (deltaHours > intervalHours) deltaHours = intervalHours;
		lastStopMs = nextStopMs;
		if (deltaHours <= 0) continue;

		// Per-observation: mean rain rate onto each ground cell within the band.
		const sum = new Float64Array(numRays * numGates);
		const count = new Uint32Array(numRays * numGates);
		for (const s of usable[i].scans) {
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
				const groundGate = Math.round(r * cos);
				if (groundGate < 0 || groundGate >= numGates) continue;
				for (let a = 0; a < numRays; a++) {
					const srcIdx = a * s.numGates + r;
					if (s.cells.flags[srcIdx] !== CELL_FLAG_OK) continue;
					const dstIdx = a * numGates + groundGate;
					sum[dstIdx] += dbzToRainRate(s.cells.values[srcIdx], zrA, zrB);
					count[dstIdx] += 1;
				}
			}
		}
		for (let j = 0; j < total.length; j++) {
			if (count[j] > 0) {
				total[j] += deltaHours * (sum[j] / count[j]);
				touched[j] = 1;
			}
		}
	}

	const cells = createCells(numRays, numGates);
	const noData = cellFlagCode('no-data');
	for (let i = 0; i < cells.values.length; i++) {
		if (touched[i]) {
			cells.values[i] = total[i];
			cells.flags[i] = CELL_FLAG_OK;
		} else {
			cells.flags[i] = noData;
		}
	}
	return { scan: finalizeGroundScan(dims, cells), unit: 'mm', skipped };
}
