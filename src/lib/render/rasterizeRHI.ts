import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import { colorForValue } from '$lib/palette/lookup';
import { CELL_FLAG_OK, CELL_FLAG_BELOW_THRESHOLD, cellFlagFromCode } from '$lib/domain/cells';
import type { CellFlag } from '$lib/domain/types';
import { elevationForHeightM } from '$lib/geo/height';

/**
 * Rasterize an RHI scan into a range-height panel (NOT georeferenced — a standalone canvas,
 * unlike the PPI which sits on the OpenLayers map).
 *
 * Geometry: an RHI ray is an elevation; each output pixel maps to a (groundRange, height) point.
 * We invert the 4/3-earth beam-height model (`elevationForHeightM`, see geo/height.ts) to find
 * which elevation ray would pass through that point, then pick the nearest actual ray and gate —
 * a flat-earth `atan2` inverse was tried here but undercounts the beam's true height at long
 * range (e.g. a 0°-elevation beam is ~588 m above ground by 100 km, not 0), which made every cut
 * draw the beam hugging the ground instead of arcing away from it.
 *
 * The x-axis is ground range [0, maxRangeM], the y-axis is height [0, maxHeightM] with height
 * increasing upward (row 0 = top = maxHeight). The area below the lowest swept elevation's beam
 * height at a given range is geometrically unobservable (not merely missing data) and is shaded
 * distinctly — see `NO_COVERAGE_RGBA` below.
 */

/** Fill for the "radar cannot see here" wedge below the lowest swept elevation — distinct from
 * fully-transparent (true no-data within the observable region). Muted slate, semi-opaque. */
const NO_COVERAGE_RGBA: readonly [number, number, number, number] = [70, 78, 92, 130];

export interface RhiRasterOptions {
	widthPx: number;
	heightPx: number;
	maxRangeM: number;
	maxHeightM: number;
	/** Paint below-threshold gates with the lowest colour instead of transparent. Default false. */
	includeBelowThreshold?: boolean;
	/** Elevation padding (deg) beyond the swept sector before a pixel is left blank. Default 0.75. */
	elevPadDeg?: number;
	/** Radar antenna altitude above the height datum (m), for the curvature model. Default 0. */
	siteAltM?: number;
}

export interface RhiRasterResult {
	rgba: Uint8ClampedArray;
	widthPx: number;
	heightPx: number;
}

/** Per-ray centre elevation for an RHI scan (mean of the ray's elevation bounds). */
export function rayElevationsDeg(scan: Scan): Float64Array {
	const out = new Float64Array(scan.numRays);
	for (let i = 0; i < scan.numRays; i++)
		out[i] = (scan.rayStartAnglesDeg[i] + scan.rayStopAnglesDeg[i]) / 2;
	return out;
}

/** Nearest ray index to a query elevation, or -1 if beyond the swept sector + padding. */
export function nearestRayByElev(elevs: Float64Array, elevDeg: number, padDeg: number): number {
	let best = -1;
	let bestDiff = Infinity;
	let lo = Infinity;
	let hi = -Infinity;
	for (let i = 0; i < elevs.length; i++) {
		const d = Math.abs(elevs[i] - elevDeg);
		if (d < bestDiff) {
			bestDiff = d;
			best = i;
		}
		if (elevs[i] < lo) lo = elevs[i];
		if (elevs[i] > hi) hi = elevs[i];
	}
	if (elevDeg < lo - padDeg || elevDeg > hi + padDeg) return -1;
	return best;
}

export function rasterizeRHI(
	scan: Scan,
	palette: Palette,
	opts: RhiRasterOptions
): RhiRasterResult {
	const { widthPx: w, heightPx: h, maxRangeM, maxHeightM } = opts;
	const rgba = new Uint8ClampedArray(w * h * 4);
	const elevs = rayElevationsDeg(scan);
	const pad = opts.elevPadDeg ?? 0.75;
	const siteAltM = opts.siteAltM ?? 0;
	const includeBelow = opts.includeBelowThreshold ?? false;
	const { values, flags } = scan.cells;
	const numGates = scan.numGates;
	const stepX = maxRangeM / w;
	const stepY = maxHeightM / h;
	let loElev = Infinity;
	for (let i = 0; i < elevs.length; i++) if (elevs[i] < loElev) loElev = elevs[i];

	for (let py = 0; py < h; py++) {
		const height = maxHeightM - (py + 0.5) * stepY;
		const rowBase = py * w * 4;
		for (let px = 0; px < w; px++) {
			const ground = (px + 0.5) * stepX;
			const slant = Math.hypot(ground, height);
			const elev = elevationForHeightM(slant, height, siteAltM);
			const ray = nearestRayByElev(elevs, elev, pad);
			const o = rowBase + px * 4;
			if (ray < 0) {
				// Below the lowest swept elevation's curved beam height at this range: the radar
				// geometrically cannot see this point (not merely missing data at a point it could
				// otherwise observe) -- shade it distinctly instead of leaving it transparent.
				if (elev < loElev) {
					rgba[o] = NO_COVERAGE_RGBA[0];
					rgba[o + 1] = NO_COVERAGE_RGBA[1];
					rgba[o + 2] = NO_COVERAGE_RGBA[2];
					rgba[o + 3] = NO_COVERAGE_RGBA[3];
				}
				continue;
			}
			const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
			if (gate < 0 || gate >= numGates) continue;
			const idx = ray * numGates + gate;
			const flag = flags[idx];
			if (flag !== CELL_FLAG_OK && !(includeBelow && flag === CELL_FLAG_BELOW_THRESHOLD)) continue;
			const [r, g, b] = colorForValue(palette, values[idx]);
			rgba[o] = r;
			rgba[o + 1] = g;
			rgba[o + 2] = b;
			rgba[o + 3] = 255;
		}
	}
	return { rgba, widthPx: w, heightPx: h };
}

/** Readout for an RHI panel pixel-independent point (ground range + height in metres). */
export interface RhiReadout {
	rangeM: number;
	heightM: number;
	value: number | null;
	flag: CellFlag | null;
}

export function rhiReadoutAt(
	groundM: number,
	heightM: number,
	scan: Scan,
	elevs?: Float64Array,
	padDeg = 0.75,
	siteAltM = 0
): RhiReadout {
	const e = elevs ?? rayElevationsDeg(scan);
	const slant = Math.hypot(groundM, heightM);
	const elev = elevationForHeightM(slant, heightM, siteAltM);
	const ray = nearestRayByElev(e, elev, padDeg);
	const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
	if (ray < 0 || gate < 0 || gate >= scan.numGates)
		return { rangeM: groundM, heightM, value: null, flag: null };
	const idx = ray * scan.numGates + gate;
	return {
		rangeM: groundM,
		heightM,
		value: scan.cells.values[idx],
		flag: cellFlagFromCode(scan.cells.flags[idx])
	};
}
