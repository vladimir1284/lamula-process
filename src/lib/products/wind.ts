import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { columnGridDims, finalizeGroundScan } from './columnCommon';
import type { ProductResult } from './types';

/**
 * VAD wind — Port of NEXRAD WSR-88D RPG VAD (Velocity Azimuth Display) algorithm
 * (`vwindpro_alg.c` / `vwindpro.h`).
 *
 * Estimates horizontal wind vector (Vx, Vy), speed, direction, RMS error and Fourier coefficients
 * (CF1, CF2, CF3) via Browning & Wexler (1968) Fourier least-squares fitting over azimuth rings.
 *
 * Features:
 * 1. Browning & Wexler Fourier least squares fit (`vadLsf` / `A317h2_vad_lsf`).
 * 2. Iterative outlier filtering (`vadFitTest` / `A317j2_fit_test`) rejecting data > 1 RMS toward zero.
 * 3. RMS error computation (`computeVadRms` / `A317i2_vad_rms`).
 * 4. Symmetry check (`checkSymmetry` / `A317k2_sym_chk`) validating mean offset vs amplitude.
 * 5. Quality thresholds (RMS threshold `threshVelocity`, `minSamples`, `symmetry`).
 * 6. Sector filtering (`startAzimuth`, `endAzimuth`).
 */

const DEG = Math.PI / 180;

export interface WindOptions {
	/** Minimum valid rays in a ring to attempt a fit [NPTS]. Default 4. */
	minSamples?: number;
	/** RMS Threshold [THV] in m/s. Fit is rejected if RMS >= threshVelocity. Default 5.0. */
	threshVelocity?: number;
	/** Number of passes through data [FT] (throwing out anomalous points). Default 2. */
	numFitTests?: number;
	/** Symmetry threshold [THY] in m/s. Default 7.0. */
	symmetry?: number;
	/** Beginning azimuth angle for sector filtering (degrees, 0..360). Default 0. */
	startAzimuth?: number;
	/** Ending azimuth angle for sector filtering (degrees, 0..360). Default 0. */
	endAzimuth?: number;
}

export interface WindResult {
	/** Wind speed, m/s. */
	speed: ProductResult;
	/** Meteorological wind direction (degrees the wind comes from). */
	direction: ProductResult;
}

export interface FitRingVadResult {
	vx: number;
	vy: number;
	speed: number;
	direction: number;
	rms: number;
	cf1: number;
	cf2: number;
	cf3: number;
	npt: number;
}

interface Complex {
	real: number;
	img: number;
}

function cmplxDiv(a: Complex, b: Complex): Complex {
	const denom = b.real * b.real + b.img * b.img;
	if (denom === 0) return { real: 0, img: 0 };
	return {
		real: (a.real * b.real + a.img * b.img) / denom,
		img: (a.img * b.real - a.real * b.img) / denom
	};
}

function cmplxMult(a: Complex, b: Complex): Complex {
	return {
		real: a.real * b.real - a.img * b.img,
		img: a.real * b.img + a.img * b.real
	};
}

function cmplxAbs(a: Complex): number {
	return Math.hypot(a.real, a.img);
}

/**
 * Browning & Wexler (1968) Fourier least-squares fit (`A317h2_vad_lsf` from NEXRAD RPG).
 * Computes Fourier coefficients CF1 (constant/vertical bias), CF2 (cos harmonic), CF3 (sin harmonic).
 */
export function vadLsf(
	azRad: Float64Array,
	ve: Float64Array,
	validFlags: boolean[],
	nradials: number
): { cf1: number; cf2: number; cf3: number; npt: number } | null {
	let npt = 0;
	let sumQ0r = 0;
	let sumQ5r = 0;
	let sumQ5i = 0;
	let sumQ4r = 0;
	let sumQ4i = 0;
	let sumQ3r = 0;
	let sumQ3i = 0;

	for (let i = 0; i < nradials; i++) {
		if (validFlags[i]) {
			const aRad = azRad[i];
			const v = ve[i];
			const sinAz = Math.sin(aRad);
			const cosAz = Math.cos(aRad);

			npt++;
			sumQ0r += v;
			sumQ5r += Math.cos(aRad * 2.0);
			sumQ5i += Math.sin(aRad * 2.0);
			sumQ4r += cosAz;
			sumQ4i += sinAz;
			sumQ3r += v * cosAz;
			sumQ3i += v * sinAz;
		}
	}

	if (npt === 0) return null;

	const q4MagSq = (sumQ4r * sumQ4r + sumQ4i * sumQ4i) / (4 * npt * npt);

	// If Q4 is virtually zero (symmetric / uniform azimuth distribution around 360°),
	// the normal equations simplify directly.
	if (q4MagSq < 1e-12) {
		const cf1 = sumQ0r / npt;
		const cf2 = (2.0 * sumQ3r) / npt;
		const cf3 = (-2.0 * sumQ3i) / npt;
		return { cf1, cf2, cf3, npt };
	}

	const twoN = npt * 2;
	const q0: Complex = { real: sumQ0r / npt, img: 0.0 };
	const q5: Complex = { real: sumQ5r / twoN, img: -sumQ5i / twoN };
	const q4: Complex = { real: sumQ4r / twoN, img: sumQ4i / twoN };
	const q3: Complex = { real: sumQ3r / npt, img: -sumQ3i / npt };

	const ccjQ4: Complex = { real: q4.real, img: -q4.img };

	const temp1: Complex = { real: 4.0 * ccjQ4.real, img: 4.0 * ccjQ4.img };
	const temp2 = cmplxDiv({ real: 1.0, img: 0.0 }, temp1);
	const qq: Complex = { real: q4.real - temp2.real, img: q4.img - temp2.img };

	if (qq.real === 0 && qq.img === 0) return null;

	const temp0_2q4: Complex = { real: 2.0 * ccjQ4.real, img: 2.0 * ccjQ4.img };

	const divQ5 = cmplxDiv(q5, temp0_2q4);
	const temp2_q2 = { real: ccjQ4.real - divQ5.real, img: ccjQ4.img - divQ5.img };
	const q2 = cmplxDiv(temp2_q2, qq);

	const divQ3 = cmplxDiv(q3, temp0_2q4);
	const temp2_q1 = { real: q0.real - divQ3.real, img: q0.img - divQ3.img };
	const q1 = cmplxDiv(temp2_q1, qq);

	const absQ2 = cmplxAbs(q2);
	const qqInt: Complex = { real: 1.0 - absQ2 * absQ2, img: 0.0 };

	if (qqInt.real === 0 && qqInt.img === 0) return null;

	const conjQ1: Complex = { real: q1.real, img: -q1.img };
	const multQ2Q1 = cmplxMult(q2, conjQ1);
	const temp2_coeff = { real: q1.real - multQ2Q1.real, img: q1.img - multQ2Q1.img };
	const intCoeff = cmplxDiv(temp2_coeff, qqInt);

	const cf3 = intCoeff.img;
	const cf2 = intCoeff.real;

	const multIntQ4 = cmplxMult(intCoeff, q4);
	const cf1 = q0.real - 2.0 * multIntQ4.real;

	return { cf1, cf2, cf3, npt };
}

/** Computes RMS scatter around fitted VAD curve (`A317i2_vad_rms`). */
export function computeVadRms(
	azRad: Float64Array,
	ve: Float64Array,
	validFlags: boolean[],
	nradials: number,
	hwdDeg: number,
	cf1: number,
	cf2: number,
	cf3: number
): number {
	const speed = Math.hypot(cf2, cf3);
	let sumDev = 0;
	let dnpt = 0;
	const hwdRad = hwdDeg * DEG;

	for (let i = 0; i < nradials; i++) {
		if (validFlags[i]) {
			const az = azRad[i];
			const dev = -Math.cos(az - hwdRad) * speed + cf1 - ve[i];
			sumDev += dev * dev;
			dnpt++;
		}
	}

	if (dnpt > 0) {
		return Math.sqrt(sumDev / dnpt);
	}
	return Infinity;
}

/** Removes outliers > 1 RMS away from curve towards zero line (`A317j2_fit_test`). */
export function vadFitTest(
	azRad: Float64Array,
	ve: Float64Array,
	validFlags: boolean[],
	nradials: number,
	hwdDeg: number,
	cf1: number,
	cf2: number,
	cf3: number,
	rms: number
): void {
	const speed = Math.hypot(cf2, cf3);
	const hwdRad = hwdDeg * DEG;
	const threshold = Math.max(rms, 1e-6);

	for (let i = 0; i < nradials; i++) {
		if (validFlags[i]) {
			const az = azRad[i];
			const fit = -Math.cos(az - hwdRad) * speed + cf1;
			const v = ve[i];

			if (fit > 0) {
				if (fit - v > threshold) {
					validFlags[i] = false;
				}
			} else {
				if (v - fit > threshold) {
					validFlags[i] = false;
				}
			}
		}
	}
}

/** Symmetry check (`A317k2_sym_chk`). */
export function checkSymmetry(cf1: number, cf2: number, cf3: number, tsmy: number): boolean {
	const speed = Math.hypot(cf2, cf3);
	return Math.abs(cf1) < tsmy && Math.abs(cf1) - speed <= 0;
}

/** Meteorological direction (deg, 0..360) the wind blows FROM, given components (east, north). */
export function windDirectionDeg(vx: number, vy: number): number {
	let dir = Math.atan2(-vx, -vy) / DEG;
	if (dir < 0) dir += 360;
	return dir;
}

/** Ring azimuth (radians, from north) for ray i using its centre angle. */
function rayAzimuthRad(scan: Scan, i: number): number {
	return ((scan.rayStartAnglesDeg[i] + scan.rayStopAnglesDeg[i]) / 2) * DEG;
}

/**
 * Solve VAD Fourier equations for one ring. Returns null if under-determined or rejected by thresholds.
 */
export function fitRingVad(
	az: Float64Array,
	vr: Float64Array,
	cosElev: number,
	n: number,
	opts: WindOptions = {}
): FitRingVadResult | null {
	const minSamples = opts.minSamples ?? 4;
	const threshVelocity = opts.threshVelocity ?? 5.0;
	const numFitTests = opts.numFitTests ?? 2;
	const symmetry = opts.symmetry ?? 7.0;

	if (n < minSamples) return null;

	const validFlags = new Array<boolean>(n);
	for (let i = 0; i < n; i++) {
		validFlags[i] = true;
	}

	let lastFit: { cf1: number; cf2: number; cf3: number; npt: number } | null = null;
	let lastHwdDeg: number;
	let lastRms = Infinity;

	for (let pass = 0; pass < numFitTests; pass++) {
		const fit = vadLsf(az, vr, validFlags, n);
		if (!fit || fit.npt < minSamples) return null;

		lastFit = fit;

		if (fit.cf3 !== 0 || fit.cf2 !== 0) {
			let hwd = Math.PI - Math.atan2(fit.cf3, fit.cf2);
			if (hwd < 0) hwd += 2 * Math.PI;
			lastHwdDeg = hwd / DEG;
		} else {
			lastHwdDeg = 0;
		}

		lastRms = computeVadRms(az, vr, validFlags, n, lastHwdDeg, fit.cf1, fit.cf2, fit.cf3);

		if (pass < numFitTests - 1) {
			vadFitTest(az, vr, validFlags, n, lastHwdDeg, fit.cf1, fit.cf2, fit.cf3, lastRms);
		}
	}

	if (!lastFit) return null;

	const sym = checkSymmetry(lastFit.cf1, lastFit.cf2, lastFit.cf3, symmetry);
	if (!sym || lastRms >= threshVelocity) {
		return null;
	}

	const speed = Math.hypot(lastFit.cf2, lastFit.cf3) / cosElev;
	const vx = -lastFit.cf3 / cosElev;
	const vy = lastFit.cf2 / cosElev;
	const direction = windDirectionDeg(vx, vy);

	return {
		vx,
		vy,
		speed,
		direction,
		rms: lastRms,
		cf1: lastFit.cf1,
		cf2: lastFit.cf2,
		cf3: lastFit.cf3,
		npt: lastFit.npt
	};
}

export function computeWind(scan: Scan, opts: WindOptions = {}): WindResult {
	const minSamples = opts.minSamples ?? 4;
	const startAz = opts.startAzimuth ?? 0;
	const endAz = opts.endAzimuth ?? 0;
	const dims = columnGridDims([scan]);
	const { numRays, numGates } = dims;
	const cosElev = Math.cos(scan.angleDeg * DEG);

	const az = new Float64Array(numRays);
	const azDeg = new Float64Array(numRays);
	for (let i = 0; i < numRays; i++) {
		az[i] = rayAzimuthRad(scan, i);
		azDeg[i] = az[i] / DEG;
	}

	const speedCells = createCells(numRays, numGates);
	const dirCells = createCells(numRays, numGates);
	const ok = cellFlagCode('ok');
	const noData = cellFlagCode('no-data');

	const ringAz = new Float64Array(numRays);
	const ringVr = new Float64Array(numRays);

	const hasSectorFilter = startAz !== endAz;

	for (let g = 0; g < numGates; g++) {
		let n = 0;
		for (let a = 0; a < numRays; a++) {
			const idx = a * numGates + g;
			if (scan.cells.flags[idx] !== CELL_FLAG_OK) continue;

			if (hasSectorFilter) {
				const inSector =
					startAz < endAz ? aDeg >= startAz && aDeg <= endAz : aDeg >= startAz || aDeg <= endAz;
				if (!inSector) continue;
			}

			ringAz[n] = az[a];
			ringVr[n] = scan.cells.values[idx];
			n++;
		}
		const fit = n >= minSamples ? fitRingVad(ringAz, ringVr, cosElev, n, opts) : null;
		for (let a = 0; a < numRays; a++) {
			const idx = a * numGates + g;
			if (fit) {
				speedCells.values[idx] = fit.speed;
				speedCells.flags[idx] = ok;
				dirCells.values[idx] = fit.direction;
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
