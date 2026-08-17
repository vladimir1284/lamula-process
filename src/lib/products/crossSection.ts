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
export const NO_COVERAGE_RGBA: readonly [number, number, number, number] = [70, 78, 92, 130];

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
	/** When set, render as a legacy-style MAX projection instead of the true vertical-plane slice:
	 * collapses the ENTIRE perpendicular window (site-relative metres, on the axis `line` does NOT
	 * vary along) by max value, independent of `line`'s own offset on that axis. `line` must be
	 * axis-aligned (`eastWestLine`/`northSouthLine` -- ax===bx or ay===by); its along-axis endpoints
	 * are still used for the kept axis's extent. See `rasterizeCrossSectionMax`. */
	maxProjection?: { perpMinM: number; perpMaxM: number };
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
	if (opts.maxProjection) return rasterizeCrossSectionMax(scans, palette, opts, opts.maxProjection);
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

/**
 * Legacy-style MAX projection cross-section (the `EstWst`/`NthSth` behaviour the module doc's
 * "decision 4" deviation note describes): for every (distance-along-line, height) output cell,
 * the MAX value found anywhere in the perpendicular window `perp`, instead of `sampleCrossSection`'s
 * single point on `line` itself. `line` must be axis-aligned (`eastWestLine`/`northSouthLine`): its
 * varying axis is the one kept, the other is collapsed across the full `perp` window, so unlike the
 * per-pixel raster the result no longer depends on `line`'s offset on the collapsed axis. No
 * linear-space conversion (raw MAX) -- that only applied to the general `Cut`'s averaging, per the
 * same deviation note.
 *
 * Same backward/inverse-sampling shape as `sampleCrossSection` (one query per output height row,
 * not a forward splat of source gates) so it's at least as dense as the per-pixel path -- a forward
 * splat only paints the exact ground points source gates happen to land on, leaving visible gaps
 * between rays/gates wherever the display resolution exceeds the source's. The one addition: at
 * each height row, the elevation/gate lookup (`beamElevAtGroundHeight` + `nearestScanByElev`, same
 * as `sampleCrossSection`) depends only on ground *range*, not azimuth -- so it's resolved once per
 * (height row, range bin) and then reused across every ray at that range, instead of repeating a
 * full per-pixel search for every perpendicular offset.
 *
 * Paints the same "radar cannot see here" wedge as the per-pixel path, with the same one-check-
 * per-output-cell simplicity: since there's no single `line` offset once the perpendicular axis is
 * collapsed, the wedge test uses the closest point the `perp` window actually reaches to the radar
 * (see `perpClosest` below) as a one-sided coverage bound, instead of sweeping every ray like the
 * data loop above does, and goes through the same padded `nearestScanByElev` test that loop uses
 * (not a raw `elev < loElevDeg` comparison) so it can't shade a cell the data loop could still find
 * real data for. Real data at that cell always wins over the wedge shading regardless.
 */
function rasterizeCrossSectionMax(
	scans: Scan[],
	palette: Palette,
	opts: CrossSectionRasterOptions,
	perp: { perpMinM: number; perpMaxM: number }
): CrossSectionRasterResult {
	const { widthPx: w, heightPx: h, maxHeightM, line } = opts;
	const siteAltM = opts.siteAltM ?? 0;
	const pad = opts.elevPadDeg ?? 0.75;
	const includeBelow = opts.includeBelowThreshold ?? false;
	const alongIsX = line.ay === line.by;
	if (!alongIsX && line.ax !== line.bx) {
		throw new Error('rasterizeCrossSectionMax: line must be axis-aligned (E-W or N-S)');
	}
	const alongMin = alongIsX ? line.ax : line.ay;
	const alongMax = alongIsX ? line.bx : line.by;
	const alongSpan = alongMax - alongMin;
	const stepY = maxHeightM / h;
	const metas = buildScanMeta(scans);
	if (metas.length === 0) throw new Error('rasterizeCrossSectionMax: no scans');

	// Each ray's azimuth projected onto (along, perp) directly -- `alongCoef`/`perpCoef` are sin/cos
	// pre-assigned to whichever axis `alongIsX` says is "along" for THIS line, so the hot loop below
	// never re-branches on it per ray. Precomputed once per scan, shared across every (height row,
	// range bin) pair since azimuth doesn't depend on either. Scans whose ray count doesn't match
	// the reference are skipped (same assumption `computeCappi` makes for CAPPI).
	const refNumRays = metas[0].scan.numRays;
	const rayGeom = metas.map(({ scan, azCentersDeg }) => {
		if (scan.numRays !== refNumRays) return null;
		const alongCoef = new Float64Array(scan.numRays);
		const perpCoef = new Float64Array(scan.numRays);
		for (let i = 0; i < scan.numRays; i++) {
			const azRad = azCentersDeg[i] * DEG;
			const s = Math.sin(azRad);
			const c = Math.cos(azRad);
			alongCoef[i] = alongIsX ? s : c;
			perpCoef[i] = alongIsX ? c : s;
		}
		return { alongCoef, perpCoef };
	});

	// Ground-range bins to probe, at the source's own gate resolution, bounded to [minR, maxR] --
	// the nearest/farthest distance the along x perp rectangle can put a point from the site. Range
	// bins outside that band can be skipped outright: no point in the window is ever that close or
	// that far, so every ray at such a bin would fail the along/perp check anyway. This matters most
	// for a panned view, where the window can sit well away from the site (see the coverage-wedge
	// fix above for why that's a real, common case) -- without the lower bound, the loop would still
	// probe every bin from r=0 out to the window, almost all wasted.
	const refGateLengthM = metas[0].scan.gateLengthM;
	function edgeDistM(min: number, max: number): number {
		if (0 < min) return min;
		if (0 > max) return -max;
		return 0;
	}
	const minRangeBoundM = Math.hypot(
		edgeDistM(alongMin, alongMax),
		edgeDistM(perp.perpMinM, perp.perpMaxM)
	);
	const alongBoundM = Math.max(Math.abs(alongMin), Math.abs(alongMax));
	const perpBoundM = Math.max(Math.abs(perp.perpMinM), Math.abs(perp.perpMaxM));
	const maxRangeBoundM = Math.hypot(alongBoundM, perpBoundM);
	const minRangeBinRi = Math.max(0, Math.floor(minRangeBoundM / refGateLengthM));
	const numRangeBins = Math.max(minRangeBinRi + 1, Math.ceil(maxRangeBoundM / refGateLengthM));

	let loElevDeg = Infinity;
	for (const m of metas) if (m.elevDeg < loElevDeg) loElevDeg = m.elevDeg;

	const maxVal = new Float32Array(w * h);
	const written = new Uint8Array(w * h);

	for (let py = 0; py < h; py++) {
		const height = maxHeightM - (py + 0.5) * stepY;
		for (let ri = minRangeBinRi; ri <= numRangeBins; ri++) {
			const r = ri * refGateLengthM;
			const elev = beamElevAtGroundHeight(r, height, siteAltM);
			const si = nearestScanByElev(metas, elev, pad);
			if (si < 0) continue;
			const geom = rayGeom[si];
			if (!geom) continue;
			const { scan } = metas[si];
			const slant = Math.hypot(r, height);
			const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
			if (gate < 0 || gate >= scan.numGates) continue;
			for (let ray = 0; ray < scan.numRays; ray++) {
				const along = r * geom.alongCoef[ray];
				if (along < alongMin || along >= alongMax) continue;
				const perpCoord = r * geom.perpCoef[ray];
				if (perpCoord < perp.perpMinM || perpCoord > perp.perpMaxM) continue;
				const idx = ray * scan.numGates + gate;
				const flagCode = scan.cells.flags[idx];
				if (flagCode !== CELL_FLAG_OK && !(includeBelow && flagCode === CELL_FLAG_BELOW_THRESHOLD))
					continue;
				const px = Math.floor(((along - alongMin) / alongSpan) * w);
				if (px < 0 || px >= w) continue;
				const oi = py * w + px;
				const v = scan.cells.values[idx];
				if (!written[oi] || v > maxVal[oi]) {
					maxVal[oi] = v;
					written[oi] = 1;
				}
			}
		}
	}

	// Closest achievable point to the radar within the ACTUAL perpendicular window -- 0 unless the
	// window (viewport-centred, so it shifts when the map is panned) doesn't even bracket the site,
	// in which case it's whichever edge is nearest. This is the true best case for coverage (shortest
	// range = steepest required elevation = likeliest to clear the lowest tilt): if even this best
	// case is below the lowest tilt, so is every other point in the window, so the wedge can never
	// disagree with the data loop above (which searches the whole window and would already have
	// written real data for anything this check would wrongly shade).
	const perpClosest = Math.min(perp.perpMaxM, Math.max(perp.perpMinM, 0));

	const rgba = new Uint8ClampedArray(w * h * 4);
	for (let py = 0; py < h; py++) {
		const height = maxHeightM - (py + 0.5) * stepY;
		for (let px = 0; px < w; px++) {
			const i = py * w + px;
			const o = i * 4;
			if (written[i]) {
				const [r, g, b] = colorForValue(palette, maxVal[i]);
				rgba[o] = r;
				rgba[o + 1] = g;
				rgba[o + 2] = b;
				rgba[o + 3] = 255;
				continue;
			}
			const along = alongMin + (px + 0.5) * (alongSpan / w);
			const elev = beamElevAtGroundHeight(Math.hypot(along, perpClosest), height, siteAltM);
			// Must go through the same padded `nearestScanByElev` test the data loop uses (and
			// `sampleCrossSection` uses for the per-pixel path) rather than comparing `elev` to
			// `loElevDeg` directly: a raw `elev < loElevDeg` shades a band up to `pad` degrees wide
			// that `nearestScanByElev` still tolerates as a match, so real data from the data loop
			// could legitimately land there -- shading it regardless would then paint the wedge right
			// over real returns.
			if (nearestScanByElev(metas, elev, pad) < 0 && elev < loElevDeg) {
				rgba[o] = NO_COVERAGE_RGBA[0];
				rgba[o + 1] = NO_COVERAGE_RGBA[1];
				rgba[o + 2] = NO_COVERAGE_RGBA[2];
				rgba[o + 3] = NO_COVERAGE_RGBA[3];
			}
		}
	}
	return { rgba, widthPx: w, heightPx: h, lineLengthM: alongSpan };
}
