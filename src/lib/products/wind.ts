import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { columnGridDims, finalizeGroundScan } from './columnCommon';
import type { ProductResult } from './types';

/**
 * VAD wind — port of `TWindGrid.WindOnCircularArc` (`legacy/Units/WindGrid.pas`).
 *
 * At each range ring of a single Doppler PPI (moment V, m/s) the horizontal wind `(Vx, Vy)` is
 * recovered by a least-squares fit of the radial-velocity model over the azimuth arc:
 *
 *   Vr(az) = Vx·cosθ·sin(az) + Vy·cosθ·cos(az)        (θ = elevation, az from north, clockwise)
 *
 * Stacking the ring's rays gives `A·k = Vr` with `A = [cosθ·sin(az) , cosθ·cos(az)]`; the normal
 * equations `k = (AᵀA)⁻¹ Aᵀ Vr` are solved in closed form (2×2). Wind speed = `√(Vx²+Vy²)`,
 * direction = meteorological `atan2` (the compass direction the wind blows *from*).
 *
 * Deviation from legacy (documented, decision 4): the legacy code assigned NODATA rays a radial
 * velocity of 0 — flagged "NODATA Bug !!!" in the source, since it biases the fit toward zero.
 * Here NODATA/below-threshold rays are EXCLUDED from the ring's fit. A ring needs at least
 * `minSamples` valid rays (default 4) spanning enough azimuth or it is left no-data.
 *
 * Output: two co-registered ground-range scans (speed in m/s, direction in degrees). The result
 * is keyed on range ring, so the ground gate equals the source gate (no elevation projection —
 * the wind is reported at the ring, matching the legacy single-tilt VAD).
 */

const DEG = Math.PI / 180;

export interface WindOptions {
	/** Minimum valid rays in a ring to attempt a fit. Default 4. */
	minSamples?: number;
}

export interface WindResult {
	/** Wind speed, m/s. */
	speed: ProductResult;
	/** Meteorological wind direction (degrees the wind comes from). */
	direction: ProductResult;
}

/** Ring azimuth (radians, from north) for ray i using its centre angle. */
function rayAzimuthRad(scan: Scan, i: number): number {
	return ((scan.rayStartAnglesDeg[i] + scan.rayStopAnglesDeg[i]) / 2) * DEG;
}

/**
 * Solve the 2×2 VAD normal equations for one ring. Returns null if under-determined (too few
 * samples or a singular / degenerate azimuth distribution, e.g. all rays collinear in the design).
 */
export function fitRingVad(
	az: Float64Array,
	vr: Float64Array,
	cosElev: number,
	n: number
): { vx: number; vy: number } | null {
	if (n < 2) return null;
	// A columns: c1 = cosθ·sin(az), c2 = cosθ·cos(az). Build AᵀA (symmetric 2×2) and Aᵀ·vr.
	let s11 = 0;
	let s12 = 0;
	let s22 = 0;
	let b1 = 0;
	let b2 = 0;
	for (let i = 0; i < n; i++) {
		const c1 = cosElev * Math.sin(az[i]);
		const c2 = cosElev * Math.cos(az[i]);
		s11 += c1 * c1;
		s12 += c1 * c2;
		s22 += c2 * c2;
		b1 += c1 * vr[i];
		b2 += c2 * vr[i];
	}
	const det = s11 * s22 - s12 * s12;
	if (Math.abs(det) < 1e-9) return null;
	const vx = (s22 * b1 - s12 * b2) / det;
	const vy = (s11 * b2 - s12 * b1) / det;
	return { vx, vy };
}

/** Meteorological direction (deg, 0..360) the wind blows FROM, given components (east, north). */
export function windDirectionDeg(vx: number, vy: number): number {
	// wind vector points toward (vx east, vy north); "from" direction is the reciprocal
	let dir = Math.atan2(-vx, -vy) / DEG;
	if (dir < 0) dir += 360;
	return dir;
}

export function computeWind(scan: Scan, opts: WindOptions = {}): WindResult {
	const minSamples = opts.minSamples ?? 4;
	const dims = columnGridDims([scan]);
	const { numRays, numGates } = dims;
	const cosElev = Math.cos(scan.angleDeg * DEG);

	const az = new Float64Array(numRays);
	for (let i = 0; i < numRays; i++) az[i] = rayAzimuthRad(scan, i);

	const speedCells = createCells(numRays, numGates);
	const dirCells = createCells(numRays, numGates);
	const ok = cellFlagCode('ok');
	const noData = cellFlagCode('no-data');

	// Scratch buffers for a ring's valid samples.
	const ringAz = new Float64Array(numRays);
	const ringVr = new Float64Array(numRays);

	for (let g = 0; g < numGates; g++) {
		let n = 0;
		for (let a = 0; a < numRays; a++) {
			const idx = a * numGates + g;
			if (scan.cells.flags[idx] !== CELL_FLAG_OK) continue;
			ringAz[n] = az[a];
			ringVr[n] = scan.cells.values[idx];
			n++;
		}
		const fit = n >= minSamples ? fitRingVad(ringAz, ringVr, cosElev, n) : null;
		for (let a = 0; a < numRays; a++) {
			const idx = a * numGates + g;
			if (fit) {
				speedCells.values[idx] = Math.hypot(fit.vx, fit.vy);
				speedCells.flags[idx] = ok;
				dirCells.values[idx] = windDirectionDeg(fit.vx, fit.vy);
				dirCells.flags[idx] = ok;
			} else {
				speedCells.flags[idx] = noData;
				dirCells.flags[idx] = noData;
			}
		}
	}

	return {
		speed: { scan: finalizeGroundScan(dims, speedCells), unit: 'm/s', skipped: 0 },
		direction: { scan: finalizeGroundScan(dims, dirCells), unit: '°', skipped: 0 }
	};
}
