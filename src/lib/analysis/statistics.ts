import type { Scan, MomentType } from '$lib/domain/types';
import { CELL_FLAG_OK } from '$lib/domain/cells';
import { toLinear, fromLinear, isReflectivity } from '$lib/products/measure';
import { regionContains, type Region } from './region';

/**
 * Region statistics — port of the statistics engine in `legacy/Units/Report.pas` (`Statistics.pas`
 * and `Result.pas` are empty stubs in the legacy tree; all the math is in Report). Computed over
 * the cells of a ground-range product scan whose centre falls inside a region.
 *
 * Faithful to legacy semantics: averaging is done in linear measure space for reflectivity
 * (dBZ → Z → mean → dBZ), `coating` is the fraction of valid cells above the threshold, `mean`
 * ("promedio en el área cubierta") is over only the above-threshold cells.
 *
 * DEVIATIONS (documented, decision 4): area and volume are weighted by each cell's true
 * annular-sector ground area (`r·Δrange·Δaz`) rather than a single fixed cartesian cell size, so
 * they are correct on the native polar grid without a resample. `stdDev` is the sample standard
 * deviation of the native values (the legacy dB-wrapped-linear form is a quirk we drop). `median`
 * is the standard median of above-threshold values (legacy's odd/even branch is swapped from the
 * usual convention).
 */

export interface RegionStats {
	region: string;
	unit: string;
	threshold: number;
	/** Valid (ok) cells inside the region. */
	count: number;
	/** True ground area of those cells (km²). */
	areaKm2: number;
	/** Percent of valid cells above the threshold. */
	coatingPct: number;
	max: number | null;
	min: number | null;
	/** Mean over all valid cells (linear space for reflectivity). */
	meanAll: number | null;
	/** Mean over above-threshold cells only. */
	meanCovered: number | null;
	/** Median of above-threshold values. */
	median: number | null;
	/** Σ(cellArea·linearValue) over above-threshold cells, in millions of m³. */
	volumeMm3: number | null;
	/** Sample standard deviation of valid native values. */
	stdDev: number | null;
}

const DEG = Math.PI / 180;

export interface StatisticsOptions {
	region: Region;
	moment: MomentType;
	unit: string;
	/** Cells with value strictly greater than this count toward coverage. */
	threshold: number;
}

export function computeStatistics(scan: Scan, opts: StatisticsOptions): RegionStats {
	const { region, moment, threshold } = opts;
	const refl = isReflectivity(moment);

	let count = 0;
	let sumL = 0;
	let areaSumM2 = 0;
	let max = -Infinity;
	let min = Infinity;
	let sumNative = 0;
	let sumNativeSq = 0;

	let tagged = 0;
	let tagSumL = 0;
	let tagVolAccM2 = 0; // Σ(area·L) over tagged
	const taggedVals: number[] = [];

	for (let a = 0; a < scan.numRays; a++) {
		const azMid = ((scan.rayStartAnglesDeg[a] + scan.rayStopAnglesDeg[a]) / 2) * DEG;
		let dAz = Math.abs(scan.rayStopAnglesDeg[a] - scan.rayStartAnglesDeg[a]) * DEG;
		if (dAz === 0) dAz = (2 * Math.PI) / scan.numRays; // fallback if bounds coincide
		const sinAz = Math.sin(azMid);
		const cosAz = Math.cos(azMid);
		for (let g = 0; g < scan.numGates; g++) {
			const idx = a * scan.numGates + g;
			if (scan.cells.flags[idx] !== CELL_FLAG_OK) continue;
			const range = scan.rangeToFirstGateM + g * scan.gateLengthM;
			const x = range * sinAz;
			const y = range * cosAz;
			if (!regionContains(region, x, y)) continue;
			const v = scan.cells.values[idx];
			const areaM2 = Math.max(0, range) * scan.gateLengthM * dAz;
			const L = toLinear(v, moment);
			count++;
			sumL += L;
			areaSumM2 += areaM2;
			sumNative += v;
			sumNativeSq += v * v;
			if (v > max) max = v;
			if (v < min) min = v;
			if (v > threshold) {
				tagged++;
				tagSumL += L;
				tagVolAccM2 += areaM2 * L;
				taggedVals.push(v);
			}
		}
	}

	const meanAll = count > 0 ? (refl ? fromLinear(sumL / count, moment) : sumL / count) : null;
	const meanCovered =
		tagged > 0 ? (refl ? fromLinear(tagSumL / tagged, moment) : tagSumL / tagged) : null;

	let median: number | null = null;
	if (taggedVals.length > 0) {
		taggedVals.sort((p, q) => p - q);
		const n = taggedVals.length;
		const mid = n >> 1;
		median = n % 2 === 1 ? taggedVals[mid] : (taggedVals[mid - 1] + taggedVals[mid]) / 2;
	}

	let stdDev: number | null = null;
	if (count > 1) {
		const variance = (sumNativeSq - (sumNative * sumNative) / count) / (count - 1);
		stdDev = Math.sqrt(Math.max(0, variance));
	} else if (count === 1) {
		stdDev = 0;
	}

	return {
		region: region.name,
		unit: opts.unit,
		threshold,
		count,
		areaKm2: areaSumM2 / 1e6,
		coatingPct: count > 0 ? (100 * tagged) / count : 0,
		max: count > 0 ? max : null,
		min: count > 0 ? min : null,
		meanAll,
		meanCovered,
		median,
		volumeMm3: tagged > 0 ? tagVolAccM2 / 1e9 : null,
		stdDev
	};
}
