import type { Scan, CellFlag } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import { colorForValue } from '$lib/palette/lookup';
import { CELL_FLAG_OK, CELL_FLAG_BELOW_THRESHOLD, cellFlagFromCode } from '$lib/domain/cells';
import { elevationForHeightM } from '$lib/geo/height';

/**
 * Vertical cross-section along an arbitrary ground line — the P2 "cortes" family (EstWst / NthSth
 * / Cut in `legacy/Units/`). One display: a height × distance-along-line panel, NOT georeferenced
 * (standalone canvas like the RHI panel).
 *
 * DEVIATION (documented, decision 4): the legacy EstWst/NthSth collapse a perpendicular slab by
 * MAX projection and Cut averages contributing elevations in linear space. This port instead uses
 * the same **inverse per-pixel sampling** P1 chose for PPI/RHI (see render/scanSample.ts): each
 * output pixel maps back to a single (ground range, azimuth, height) point and samples the nearest
 * elevation beam. Hole-free, invertible, and consistent with the rest of the viewer; it renders a
 * true vertical plane rather than a slab projection. The axis-aligned E-W / N-S cuts are just this
 * general cut with the endpoints set by `eastWestLine` / `northSouthLine`.
 *
 * Coordinate frame: site-relative ground metres, x = east, y = north. Azimuth is measured from
 * north, clockwise (matching the scan ray convention). Beam elevation for a (range, height) point
 * is found via the 4/3-earth inverse `elevationForHeightM` (geo/height.ts) rather than the flat
 * `atan2(height, range)` — a flat inverse understates how far a low-elevation beam climbs away
 * from the ground at long range (curvature), which drew every 0°-elevation beam hugging y=0
 * regardless of range.
 */

const DEG = Math.PI / 180;

/** Fill for the "radar cannot see here" wedge below the lowest swept elevation at this range —
 * distinct from fully-transparent (true no-data within the observable region). Matches
 * render/rasterizeRHI.ts's NO_COVERAGE_RGBA so both cut styles read the same. */
const NO_COVERAGE_RGBA: readonly [number, number, number, number] = [70, 78, 92, 130];

export interface CutLine {
	/** Endpoint A, site-relative metres (x east, y north). */
	ax: number;
	ay: number;
	/** Endpoint B, site-relative metres. */
	bx: number;
	by: number;
}

/** E-W cut at a north offset, spanning ±halfExtentM east-west. */
export function eastWestLine(northOffsetM: number, halfExtentM: number): CutLine {
	return { ax: -halfExtentM, ay: northOffsetM, bx: halfExtentM, by: northOffsetM };
}

/** N-S cut at an east offset, spanning ±halfExtentM north-south. */
export function northSouthLine(eastOffsetM: number, halfExtentM: number): CutLine {
	return { ax: eastOffsetM, ay: -halfExtentM, bx: eastOffsetM, by: halfExtentM };
}

/** Per-scan geometry cache: elevation and ray centre azimuths (degrees, 0..360). */
export interface ScanMeta {
	scan: Scan;
	elevDeg: number;
	azCentersDeg: Float64Array;
}

export function buildScanMeta(scans: Scan[]): ScanMeta[] {
	return scans.map((scan) => {
		const azCentersDeg = new Float64Array(scan.numRays);
		for (let i = 0; i < scan.numRays; i++) {
			let c = (scan.rayStartAnglesDeg[i] + scan.rayStopAnglesDeg[i]) / 2;
			c = ((c % 360) + 360) % 360;
			azCentersDeg[i] = c;
		}
		return { scan, elevDeg: scan.angleDeg, azCentersDeg };
	});
}

/** Nearest scan index to an elevation, or -1 if beyond the swept elevations + padding. */
export function nearestScanByElev(metas: ScanMeta[], elevDeg: number, padDeg: number): number {
	let best = -1;
	let bestDiff = Infinity;
	let lo = Infinity;
	let hi = -Infinity;
	for (let i = 0; i < metas.length; i++) {
		const e = metas[i].elevDeg;
		const d = Math.abs(e - elevDeg);
		if (d < bestDiff) {
			bestDiff = d;
			best = i;
		}
		if (e < lo) lo = e;
		if (e > hi) hi = e;
	}
	if (elevDeg < lo - padDeg || elevDeg > hi + padDeg) return -1;
	return best;
}

/** Nearest ray index to an azimuth, using circular distance (handles the 0/360 seam). */
export function nearestRayByAzimuth(azCentersDeg: Float64Array, azDeg: number): number {
	let best = -1;
	let bestDiff = Infinity;
	for (let i = 0; i < azCentersDeg.length; i++) {
		let d = Math.abs(azCentersDeg[i] - azDeg);
		if (d > 180) d = 360 - d;
		if (d < bestDiff) {
			bestDiff = d;
			best = i;
		}
	}
	return best;
}

export interface CrossSample {
	value: number;
	flag: CellFlag;
}

/** Elevation (deg) whose 4/3-earth beam-height curve passes through a ground point + height,
 * given as horizontal ground distance rather than slant range (see geo/height.ts). */
export function beamElevAtGroundHeight(rangeM: number, heightM: number, siteAltM = 0): number {
	const slant = Math.hypot(rangeM, heightM);
	return elevationForHeightM(slant, heightM, siteAltM);
}

/**
 * Sample the volume at a site-relative ground point (metres) and height (metres): pick the beam
 * elevation that passes through it, the ray nearest its azimuth, and the gate nearest its slant
 * range. Returns null when no beam covers the point.
 */
export function sampleCrossSection(
	metas: ScanMeta[],
	xEastM: number,
	yNorthM: number,
	heightM: number,
	elevPadDeg = 0.75,
	siteAltM = 0
): CrossSample | null {
	const rangeM = Math.hypot(xEastM, yNorthM);
	if (rangeM === 0 && heightM === 0) return null;
	const elev = beamElevAtGroundHeight(rangeM, heightM, siteAltM);
	const si = nearestScanByElev(metas, elev, elevPadDeg);
	if (si < 0) return null;
	const meta = metas[si];
	const scan = meta.scan;
	const slant = Math.hypot(rangeM, heightM);
	const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
	if (gate < 0 || gate >= scan.numGates) return null;
	let azDeg = Math.atan2(xEastM, yNorthM) / DEG;
	if (azDeg < 0) azDeg += 360;
	const ray = nearestRayByAzimuth(meta.azCentersDeg, azDeg);
	if (ray < 0) return null;
	const idx = ray * scan.numGates + gate;
	return { value: scan.cells.values[idx], flag: cellFlagFromCode(scan.cells.flags[idx]) };
}

export interface CrossSectionRasterOptions {
	widthPx: number;
	heightPx: number;
	maxHeightM: number;
	line: CutLine;
	includeBelowThreshold?: boolean;
	elevPadDeg?: number;
	/** Radar antenna altitude above the height datum (m), for the curvature model. Default 0. */
	siteAltM?: number;
}

export interface CrossSectionRasterResult {
	rgba: Uint8ClampedArray;
	widthPx: number;
	heightPx: number;
	/** Length of the cut line (metres) — the x-axis extent. */
	lineLengthM: number;
}

export function rasterizeCrossSection(
	scans: Scan[],
	palette: Palette,
	opts: CrossSectionRasterOptions
): CrossSectionRasterResult {
	const { widthPx: w, heightPx: h, maxHeightM, line } = opts;
	const rgba = new Uint8ClampedArray(w * h * 4);
	const metas = buildScanMeta(scans);
	const pad = opts.elevPadDeg ?? 0.75;
	const siteAltM = opts.siteAltM ?? 0;
	const includeBelow = opts.includeBelowThreshold ?? false;
	const dx = line.bx - line.ax;
	const dy = line.by - line.ay;
	const lineLengthM = Math.hypot(dx, dy);
	const stepY = maxHeightM / h;
	let loElevDeg = Infinity;
	for (const m of metas) if (m.elevDeg < loElevDeg) loElevDeg = m.elevDeg;

	for (let py = 0; py < h; py++) {
		const height = maxHeightM - (py + 0.5) * stepY;
		const rowBase = py * w * 4;
		for (let px = 0; px < w; px++) {
			const t = (px + 0.5) / w;
			const x = line.ax + t * dx;
			const y = line.ay + t * dy;
			const o = rowBase + px * 4;
			const s = sampleCrossSection(metas, x, y, height, pad, siteAltM);
			if (!s) {
				// Below the lowest swept elevation's curved beam height at this range: the radar
				// geometrically cannot see this point -- shade it distinctly instead of leaving it
				// transparent (which reads as "no data" within an otherwise-observable area).
				const rangeM = Math.hypot(x, y);
				const elev = beamElevAtGroundHeight(rangeM, height, siteAltM);
				if (elev < loElevDeg) {
					rgba[o] = NO_COVERAGE_RGBA[0];
					rgba[o + 1] = NO_COVERAGE_RGBA[1];
					rgba[o + 2] = NO_COVERAGE_RGBA[2];
					rgba[o + 3] = NO_COVERAGE_RGBA[3];
				}
				continue;
			}
			const flagCode =
				s.flag === 'ok'
					? CELL_FLAG_OK
					: s.flag === 'below-threshold'
						? CELL_FLAG_BELOW_THRESHOLD
						: -1;
			if (flagCode !== CELL_FLAG_OK && !(includeBelow && flagCode === CELL_FLAG_BELOW_THRESHOLD))
				continue;
			const [r, g, b] = colorForValue(palette, s.value);
			rgba[o] = r;
			rgba[o + 1] = g;
			rgba[o + 2] = b;
			rgba[o + 3] = 255;
		}
	}
	return { rgba, widthPx: w, heightPx: h, lineLengthM };
}
