import type { Channel, Scan } from '$lib/domain/types';
import { fitRingVad, type WindOptions, type FitRingVadResult } from './wind';
import { beamHeightM } from '$lib/geo/height';

const DEG = Math.PI / 180;
const MPS_TO_KTS = 1.94384;

export interface VadProfileLevel {
	elevationDeg: number;
	gateIndex: number;
	slantRangeM: number;
	heightM: number;
	heightKft: number;
	vx: number;
	vy: number;
	speedMs: number;
	speedKts: number;
	directionDeg: number;
	cardinalDir: string;
	rmsMs: number;
	cf1: number;
	cf2: number;
	cf3: number;
	npt: number;
}

export interface VadProfileResult {
	levels: VadProfileLevel[];
	siteAltM: number;
	maxSpeedMs: number;
	maxHeightM: number;
}

export function getCardinalDirection(deg: number): string {
	const cardinals = [
		'N',
		'NNE',
		'NE',
		'ENE',
		'E',
		'ESE',
		'SE',
		'SSE',
		'S',
		'SSW',
		'SW',
		'WSW',
		'W',
		'WNW',
		'NW',
		'NNW'
	];
	const idx = Math.round((deg % 360) / 22.5) % 16;
	return cardinals[(idx + 16) % 16];
}

/** Ring azimuth (radians, from north) for ray i using its centre angle. */
function rayAzimuthRad(scan: Scan, i: number): number {
	return ((scan.rayStartAnglesDeg[i] + scan.rayStopAnglesDeg[i]) / 2) * DEG;
}

/**
 * Computes a vertical VAD profile across all elevation cuts and range rings in a channel.
 */
export function computeVadProfile(
	channel: Channel,
	opts: WindOptions = {},
	siteAltM = 0
): VadProfileResult {
	const levels: VadProfileLevel[] = [];
	let maxSpeedMs = 0;
	let maxHeightM = 0;

	for (const scan of channel.scans) {
		const { numRays, numGates, rangeToFirstGateM, gateLengthM, angleDeg } = scan;
		const cosElev = Math.cos(angleDeg * DEG);

		const az = new Float64Array(numRays);
		for (let i = 0; i < numRays; i++) {
			az[i] = rayAzimuthRad(scan, i);
		}

		const ringAz = new Float64Array(numRays);
		const ringVr = new Float64Array(numRays);

		for (let g = 0; g < numGates; g++) {
			let n = 0;
			for (let a = 0; a < numRays; a++) {
				const idx = a * numGates + g;
				if (scan.cells.flags[idx] !== 0) continue; // CELL_FLAG_OK
				ringAz[n] = az[a];
				ringVr[n] = scan.cells.values[idx];
				n++;
			}

			if (n < (opts.minSamples ?? 4)) continue;

			const fit: FitRingVadResult | null = fitRingVad(ringAz, ringVr, cosElev, n, opts);
			if (!fit) continue;

			const slantRangeM = rangeToFirstGateM + g * gateLengthM;
			const heightAGLM = beamHeightM(slantRangeM, angleDeg, 0);
			const heightMSLM = heightAGLM + siteAltM;
			const heightKft = (heightMSLM * 3.28084) / 1000;

			const speedKts = fit.speed * MPS_TO_KTS;
			const cardinalDir = getCardinalDirection(fit.direction);

			if (fit.speed > maxSpeedMs) maxSpeedMs = fit.speed;
			if (heightMSLM > maxHeightM) maxHeightM = heightMSLM;

			levels.push({
				elevationDeg: angleDeg,
				gateIndex: g,
				slantRangeM,
				heightM: heightMSLM,
				heightKft,
				vx: fit.vx,
				vy: fit.vy,
				speedMs: fit.speed,
				speedKts,
				directionDeg: fit.direction,
				cardinalDir,
				rmsMs: fit.rms,
				cf1: fit.cf1,
				cf2: fit.cf2,
				cf3: fit.cf3,
				npt: fit.npt
			});
		}
	}

	levels.sort((a, b) => a.heightM - b.heightM);

	return {
		levels,
		siteAltM,
		maxSpeedMs,
		maxHeightM
	};
}
