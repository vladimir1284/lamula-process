import type { Scan } from '$lib/domain/types';
import { CELL_FLAG_OK } from '$lib/domain/cells';
import { beamHeightRangeM } from '$lib/geo/height';
import { buildScanMeta, nearestRayByAzimuth } from './crossSection';
import { buildSpline, evalSpline } from '$lib/math/spline';

/**
 * Vertical profile at a single ground point — port of `TProfile`/`TProfileVector`
 * (`legacy/Units/Profile.pas`, `ProfileVector.pas`).
 *
 * One sample per elevation: at the point's ground range and azimuth, sample each elevation scan
 * (slant range = groundRange / cosθ) and record the beam-centre height `(min+max)/2` and the
 * value. The vertical axis is then filled by a natural cubic spline over those (height, value)
 * samples, with a fixed anchor of value 0 at `topM` (legacy anchors 0 at 20 km). Below the lowest
 * sample the profile is flat (spline evaluation clamps to the endpoints).
 *
 * Point is given in site-relative ground metres (x east, y north), matching crossSection.ts.
 */

export interface ProfileOptions {
	xEastM: number;
	yNorthM: number;
	beamWidthDeg: number;
	/** Top of the profile (metres); also the height of the fixed 0-value anchor. Default 20000. */
	topM?: number;
	/** Vertical sample spacing (metres). Default 250. */
	cellHeightM?: number;
	siteAltM?: number;
}

export interface ProfileSample {
	heightM: number;
	value: number;
}

export interface ProfileResult {
	/** Output heights (metres), ascending. */
	heightsM: Float64Array;
	/** Spline-interpolated value at each height. */
	values: Float64Array;
	/** The raw per-elevation samples (ascending height), for markers/debugging. */
	samples: ProfileSample[];
}

const DEG = Math.PI / 180;

export function computeProfile(scans: Scan[], opts: ProfileOptions): ProfileResult {
	const topM = opts.topM ?? 20000;
	const cellHeightM = opts.cellHeightM ?? 250;
	const siteAltM = opts.siteAltM ?? 0;
	const metas = buildScanMeta(scans);
	const rangeM = Math.hypot(opts.xEastM, opts.yNorthM);
	let azDeg = Math.atan2(opts.xEastM, opts.yNorthM) / DEG;
	if (azDeg < 0) azDeg += 360;

	const samples: ProfileSample[] = [];
	for (const meta of metas) {
		const scan = meta.scan;
		const cos = Math.cos(scan.angleDeg * DEG);
		if (cos <= 0) continue;
		const slant = rangeM / cos;
		const gate = Math.round((slant - scan.rangeToFirstGateM) / scan.gateLengthM);
		if (gate < 0 || gate >= scan.numGates) continue;
		const ray = nearestRayByAzimuth(meta.azCentersDeg, azDeg);
		const idx = ray * scan.numGates + gate;
		if (scan.cells.flags[idx] !== CELL_FLAG_OK) continue;
		const { min, max } = beamHeightRangeM(slant, scan.angleDeg, opts.beamWidthDeg, siteAltM);
		samples.push({ heightM: (min + max) / 2, value: scan.cells.values[idx] });
	}
	samples.sort((a, b) => a.heightM - b.heightM);

	// Deduplicate equal heights (spline requires strictly increasing x); keep the last.
	const knotH: number[] = [];
	const knotV: number[] = [];
	for (const s of samples) {
		if (knotH.length > 0 && s.heightM - knotH[knotH.length - 1] < 1e-6) {
			knotV[knotV.length - 1] = s.value;
		} else {
			knotH.push(s.heightM);
			knotV.push(s.value);
		}
	}
	// Fixed top anchor: value 0 at topM (only if above the highest sample).
	if (knotH.length === 0 || topM - knotH[knotH.length - 1] > 1e-6) {
		knotH.push(topM);
		knotV.push(0);
	}

	const nRows = Math.max(1, Math.floor(topM / cellHeightM) + 1);
	const heightsM = new Float64Array(nRows);
	const values = new Float64Array(nRows);
	const spline = buildSpline(knotH, knotV);
	for (let i = 0; i < nRows; i++) {
		const hM = i * cellHeightM;
		heightsM[i] = hM;
		values[i] = evalSpline(spline, hM);
	}
	return { heightsM, values, samples };
}
