import type { Scan, CellFlag } from '$lib/domain/types';
import { cellFlagFromCode } from '$lib/domain/cells';
import { groundRangeM } from '$lib/geo/groundRange';

/**
 * Inverse-mapping polar sampler for rendering a Scan to a Cartesian raster.
 *
 * NOTE ON APPROACH — this deliberately differs from the legacy `TScanGrid.RenderScan`
 * (`legacy/Units/ScanGrid.pas`). The original scatters every polar cell forward into a grid,
 * averaging overlapping cells in *linear measure space* (`CodeLineal`/`LinealCode`) and then
 * back-filling empty grid cells with the nearest polar sample. That forward-scatter+average
 * predates cheap per-pixel inverse mapping. For the OpenLayers georeferenced-raster path we
 * instead do the modern thing: for each output pixel, map back to (range, azimuth) and take
 * the nearest ray/gate. This is hole-free by construction and needs no measure-space
 * averaging, at the cost of not box-averaging several near-range cells into one coarse pixel
 * (negligible at display resolutions >= the polar grid). Documented, not accidental.
 *
 * Azimuth convention: meteorological — 0° = North, increasing clockwise. In the ground plane
 * we use x = East, y = North, so azimuth = atan2(x, y).
 */

export interface SampleResult {
	value: number;
	flag: CellFlag;
}

const DEG = Math.PI / 180;

/** Normalize an angle to [0, 360). */
export function normDeg(a: number): number {
	let x = a % 360;
	if (x < 0) x += 360;
	return x;
}

/** Per-ray centre azimuth (deg, [0,360)), handling the start/stop wraparound at 360/0. */
export function rayCentersDeg(scan: Scan): Float64Array {
	const { rayStartAnglesDeg: s, rayStopAnglesDeg: e, numRays } = scan;
	const out = new Float64Array(numRays);
	for (let i = 0; i < numRays; i++) {
		let span = e[i] - s[i];
		if (span < -180) span += 360; // stop wrapped past 360
		if (span > 180) span -= 360;
		out[i] = normDeg(s[i] + span / 2);
	}
	return out;
}

/** Smallest absolute circular difference between two azimuths (deg, 0..180). */
export function circularDiffDeg(a: number, b: number): number {
	let d = Math.abs(normDeg(a) - normDeg(b));
	if (d > 180) d = 360 - d;
	return d;
}

/**
 * Precomputed azimuth → ray-index lookup. `binsPerDeg` bins across 360°, each mapping to the
 * ray whose centre is angularly nearest that bin. Built once per scan, O(bins·rays); queried
 * O(1) per output pixel.
 */
export interface AzimuthLUT {
	binsPerDeg: number;
	rayIndex: Int32Array;
}

export function buildAzimuthLUT(scan: Scan, binsPerDeg = 10): AzimuthLUT {
	const centers = rayCentersDeg(scan);
	const bins = Math.round(360 * binsPerDeg);
	const rayIndex = new Int32Array(bins);
	for (let b = 0; b < bins; b++) {
		const az = (b + 0.5) / binsPerDeg;
		let best = -1;
		let bestDiff = Infinity;
		for (let i = 0; i < centers.length; i++) {
			const d = circularDiffDeg(az, centers[i]);
			if (d < bestDiff) {
				bestDiff = d;
				best = i;
			}
		}
		rayIndex[b] = best;
	}
	return { binsPerDeg, rayIndex };
}

export function rayIndexForAzimuth(lut: AzimuthLUT, azimuthDeg: number): number {
	const bins = lut.rayIndex.length;
	let b = Math.floor(normDeg(azimuthDeg) * lut.binsPerDeg);
	if (b >= bins) b = bins - 1;
	return lut.rayIndex[b];
}

/**
 * Gate index for a given ground range at this scan's elevation. The pixel's ground range is
 * projected back to slant range (`slant = ground / cos(elev)`, inverse of `groundRangeM`)
 * before indexing gates. Returns -1 if outside the gated range.
 */
export function gateForGroundRange(scan: Scan, groundRange: number): number {
	const cos = Math.cos(scan.angleDeg * DEG);
	if (cos <= 0) return -1;
	const slant = groundRange / cos;
	const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
	if (gate < 0 || gate >= scan.numGates) return -1;
	return gate;
}

/** Maximum ground range (m) covered by this scan's outermost gate. */
export function maxGroundRangeM(scan: Scan): number {
	const maxSlant = scan.rangeToFirstGateM + (scan.numGates - 1) * scan.gateLengthM;
	return groundRangeM(maxSlant, scan.angleDeg);
}

/**
 * Sample the scan at a ground-plane point (metres, x=East y=North relative to the site).
 * Returns null when the point falls outside the scan's gated disc.
 */
export function sampleGround(
	scan: Scan,
	lut: AzimuthLUT,
	x: number,
	y: number
): SampleResult | null {
	const range = Math.hypot(x, y);
	const gate = gateForGroundRange(scan, range);
	if (gate < 0) return null;
	const az = normDeg(Math.atan2(x, y) / DEG);
	const ray = rayIndexForAzimuth(lut, az);
	if (ray < 0) return null;
	const idx = ray * scan.numGates + gate;
	return { value: scan.cells.values[idx], flag: cellFlagFromCode(scan.cells.flags[idx]) };
}
