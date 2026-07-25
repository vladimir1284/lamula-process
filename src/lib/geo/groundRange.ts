/**
 * Slant range → horizontal ground range projection.
 *
 * The legacy CAPPI accumulator (`TCAPPIScan.ProcessMove`, `legacy/Units/CAPPIScan.pas`)
 * projects each gate onto the ground plane with `Radius := round(R * cos(elevation))`.
 * Ground range is thus simply the slant range times the cosine of the elevation angle —
 * the small-angle flattening the legacy renderer uses for horizontal placement.
 *
 * (The 4/3-earth curvature correction lives in `beamHeightM`; horizontal placement stays
 * on this flat cosine projection, exactly as the original.)
 */

const DEG = Math.PI / 180;

export function groundRangeM(slantRangeM: number, elevDeg: number): number {
	return slantRangeM * Math.cos(elevDeg * DEG);
}
