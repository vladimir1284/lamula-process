/**
 * Beam geometry under the 4/3-earth refraction model.
 *
 * Direct port of `THeightTable.AddRay` (the active, non-commented version) in
 * `legacy/Units/HeightTable.pas`. The original stored heights in grid Y-cell units
 * (`… / LY2KM`) and worked in km; here we keep SI metres throughout and only fold the
 * per-cell iteration out into per-(range,angle) pure functions.
 *
 * Faithful to the legacy law-of-cosines form:
 *   Ralt   = Rref + siteAlt
 *   height = sqrt(Ralt² + r² − 2·Ralt·r·cos(π/2 + elev)) − Rref
 * with cos(π/2 + elev) = −sin(elev), i.e. the standard
 *   h = sqrt(r² + ae² + 2·r·ae·sin θ) − ae   (ae = k·Re, radar height folded into Ralt).
 */

/** Earth radius used by the legacy source (km → m). */
export const EARTH_RADIUS_M = 6_378_160;
/** Effective-earth refraction factor (standard 4/3 atmosphere). */
export const REFRACTION_INDEX = 4 / 3;
/** Effective earth radius, ae = k·Re. */
export const EFFECTIVE_EARTH_RADIUS_M = REFRACTION_INDEX * EARTH_RADIUS_M;

const DEG = Math.PI / 180;

/**
 * Height (metres, above the radar's own altitude datum) of the beam centre at a given
 * slant range and elevation angle. `siteAltM` is the radar antenna altitude above the
 * height datum; it shifts `Ralt` exactly as the legacy `Altitude` term does.
 */
export function beamHeightM(slantRangeM: number, elevDeg: number, siteAltM = 0): number {
	const rref = EFFECTIVE_EARTH_RADIUS_M;
	const ralt = rref + siteAltM;
	const cosTerm = Math.cos(Math.PI / 2 + elevDeg * DEG);
	return (
		Math.sqrt(ralt * ralt + slantRangeM * slantRangeM - 2 * ralt * slantRangeM * cosTerm) - rref
	);
}

/**
 * Min/max beam height across the beam's angular width (elev ± beamWidth/2), matching how
 * the legacy height table brackets each cell with `MinCos`/`MaxCos`. `min` uses the lower
 * edge (elev − beam/2), `max` the upper edge (elev + beam/2).
 */
export function beamHeightRangeM(
	slantRangeM: number,
	elevDeg: number,
	beamWidthDeg: number,
	siteAltM = 0
): { min: number; max: number } {
	const half = beamWidthDeg / 2;
	return {
		min: beamHeightM(slantRangeM, elevDeg - half, siteAltM),
		max: beamHeightM(slantRangeM, elevDeg + half, siteAltM)
	};
}
