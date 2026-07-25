import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import { colorForValue } from '$lib/palette/lookup';
import { CELL_FLAG_OK, CELL_FLAG_BELOW_THRESHOLD, cellFlagFromCode } from '$lib/domain/cells';
import type { CellFlag } from '$lib/domain/types';

/**
 * Rasterize an RHI scan into a range-height panel (NOT georeferenced — a standalone canvas,
 * unlike the PPI which sits on the OpenLayers map).
 *
 * Geometry: an RHI ray is an elevation; each output pixel maps to a (groundRange, height) point.
 * We use the flat-earth inverse (elev = atan2(height, groundRange), slant = hypot) to pick the
 * nearest elevation ray and gate — the same display-resolution simplification the PPI path
 * makes. (The 4/3-earth curvature affects the absolute height axis at long range; for the
 * bounded ranges an RHI panel shows, the flat inverse is visually indistinguishable and keeps
 * the mapping invertible. Documented, not accidental — see geo/height.ts for the exact model.)
 *
 * The x-axis is ground range [0, maxRangeM], the y-axis is height [0, maxHeightM] with height
 * increasing upward (row 0 = top = maxHeight).
 */

const DEG = Math.PI / 180;

export interface RhiRasterOptions {
	widthPx: number;
	heightPx: number;
	maxRangeM: number;
	maxHeightM: number;
	/** Paint below-threshold gates with the lowest colour instead of transparent. Default false. */
	includeBelowThreshold?: boolean;
	/** Elevation padding (deg) beyond the swept sector before a pixel is left blank. Default 0.75. */
	elevPadDeg?: number;
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
	const includeBelow = opts.includeBelowThreshold ?? false;
	const { values, flags } = scan.cells;
	const numGates = scan.numGates;
	const stepX = maxRangeM / w;
	const stepY = maxHeightM / h;

	for (let py = 0; py < h; py++) {
		const height = maxHeightM - (py + 0.5) * stepY;
		const rowBase = py * w * 4;
		for (let px = 0; px < w; px++) {
			const ground = (px + 0.5) * stepX;
			const elev = Math.atan2(height, ground) / DEG;
			const ray = nearestRayByElev(elevs, elev, pad);
			if (ray < 0) continue;
			const slant = Math.hypot(ground, height);
			const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
			if (gate < 0 || gate >= numGates) continue;
			const idx = ray * numGates + gate;
			const flag = flags[idx];
			if (flag !== CELL_FLAG_OK && !(includeBelow && flag === CELL_FLAG_BELOW_THRESHOLD)) continue;
			const [r, g, b] = colorForValue(palette, values[idx]);
			const o = rowBase + px * 4;
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
	padDeg = 0.75
): RhiReadout {
	const e = elevs ?? rayElevationsDeg(scan);
	const elev = Math.atan2(heightM, groundM) / DEG;
	const ray = nearestRayByElev(e, elev, padDeg);
	const slant = Math.hypot(groundM, heightM);
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
