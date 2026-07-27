import { describe, it, expect } from 'vitest';
import { getCell, setCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { computeWind, windDirectionDeg, fitRingVad, vadLsf, computeVadRms, checkSymmetry } from './wind';

const DEG = Math.PI / 180;

// Synthesize a Doppler PPI whose radial velocity is exactly a uniform wind (vx east, vy north)
// at the given elevation. Ray i is centred on i·(360/numRays)° from north, clockwise.
function windScan(vx: number, vy: number, numRays: number, elevDeg: number) {
	const cosE = Math.cos(elevDeg * DEG);
	const step = 360 / numRays;
	return makeScan({
		numRays,
		numGates: 3,
		angleDeg: elevDeg,
		fill: (r) => {
			const az = r * step * DEG;
			return vx * cosE * Math.sin(az) + vy * cosE * Math.cos(az);
		}
	});
}

describe('windDirectionDeg (meteorological, wind FROM)', () => {
	it('wind blowing toward south = from north (0°)', () => {
		expect(windDirectionDeg(0, -5)).toBeCloseTo(0, 6);
	});
	it('wind blowing toward west = from east (90°)', () => {
		expect(windDirectionDeg(-5, 0)).toBeCloseTo(90, 6);
	});
	it('wind blowing toward north = from south (180°)', () => {
		expect(windDirectionDeg(0, 5)).toBeCloseTo(180, 6);
	});
});

describe('fitRingVad (NEXRAD RPG Browning & Wexler VAD)', () => {
	it('recovers seeded components and Fourier coefficients from a clean ring', () => {
		const numRays = 16;
		const az = new Float64Array(numRays);
		const vr = new Float64Array(numRays);
		const step = 360 / numRays;
		for (let i = 0; i < numRays; i++) {
			az[i] = i * step * DEG;
			vr[i] = 3 * Math.sin(az[i]) + 4 * Math.cos(az[i]); // cosElev = 1
		}
		const fit = fitRingVad(az, vr, 1, numRays)!;
		expect(fit).not.toBeNull();
		expect(fit.vx).toBeCloseTo(3, 6);
		expect(fit.vy).toBeCloseTo(4, 6);
		expect(fit.speed).toBeCloseTo(5, 6);
		expect(fit.cf1).toBeCloseTo(0, 6);
		expect(fit.cf2).toBeCloseTo(4, 6);
		expect(fit.cf3).toBeCloseTo(-3, 6);
		expect(fit.rms).toBeCloseTo(0, 6);
	});

	it('returns null when under-determined or below minSamples', () => {
		expect(fitRingVad(new Float64Array(1), new Float64Array(1), 1, 1)).toBeNull();
	});

	it('rejects fit when RMS scatter exceeds threshVelocity threshold', () => {
		const numRays = 16;
		const az = new Float64Array(numRays);
		const vr = new Float64Array(numRays);
		const step = 360 / numRays;
		for (let i = 0; i < numRays; i++) {
			az[i] = i * step * DEG;
			// Add large random-like noise to break RMS
			vr[i] = 3 * Math.sin(az[i]) + 4 * Math.cos(az[i]) + (i % 2 === 0 ? 10 : -10);
		}
		// Strict threshVelocity = 2.0 m/s
		const fit = fitRingVad(az, vr, 1, numRays, { threshVelocity: 2.0 });
		expect(fit).toBeNull();
	});

	it('rejects fit when symmetry check fails (mean offset CF1 too large)', () => {
		const numRays = 16;
		const az = new Float64Array(numRays);
		const vr = new Float64Array(numRays);
		const step = 360 / numRays;
		for (let i = 0; i < numRays; i++) {
			az[i] = i * step * DEG;
			vr[i] = 3 * Math.sin(az[i]) + 4 * Math.cos(az[i]) + 20; // Constant bias 20 m/s
		}
		// Strict symmetry threshold = 5.0 m/s
		const fit = fitRingVad(az, vr, 1, numRays, { symmetry: 5.0 });
		expect(fit).toBeNull();
	});

	it('performs fit test pass to remove low-magnitude outliers', () => {
		const numRays = 16;
		const az = new Float64Array(numRays);
		const vr = new Float64Array(numRays);
		const step = 360 / numRays;
		for (let i = 0; i < numRays; i++) {
			az[i] = i * step * DEG;
			vr[i] = 3 * Math.sin(az[i]) + 4 * Math.cos(az[i]);
		}
		// Corrupt single ray with low magnitude outlier towards zero
		vr[0] = 0.1;

		const fit = fitRingVad(az, vr, 1, numRays, { numFitTests: 2, minSamples: 4 });
		expect(fit).not.toBeNull();
		expect(fit!.vx).toBeCloseTo(3, 1);
		expect(fit!.vy).toBeCloseTo(4, 1);
	});
});

describe('computeWind', () => {
	it('recovers uniform wind speed and direction', () => {
		const scan = windScan(3, 4, 16, 0); // speed 5, wind toward (E3,N4) → from ~216.87°
		const { speed, direction } = computeWind(scan);
		expect(speed.unit).toBe('m/s');
		expect(direction.unit).toBe('°');
		expect(getCell(speed.scan.cells, 0, 1).value).toBeCloseTo(5, 4);
		expect(getCell(direction.scan.cells, 0, 1).value).toBeCloseTo(windDirectionDeg(3, 4), 3);
	});

	it('supports sector filtering (startAzimuth and endAzimuth)', () => {
		const scan = windScan(3, 4, 36, 0);
		// Compute wind only in sector 0° to 180°
		const { speed } = computeWind(scan, { startAzimuth: 0, endAzimuth: 180, minSamples: 4 });
		expect(getCell(speed.scan.cells, 0, 1).flag).toBe('ok');
	});

	it('leaves rings with too few valid rays no-data', () => {
		const scan = windScan(3, 4, 16, 0);
		// blank all but 2 rays in gate 0
		for (let a = 2; a < 16; a++) setCell(scan.cells, a, 0, 0, 'no-data');
		const { speed } = computeWind(scan, { minSamples: 4 });
		expect(getCell(speed.scan.cells, 0, 0).flag).toBe('no-data');
		// a full ring still resolves
		expect(getCell(speed.scan.cells, 0, 1).flag).toBe('ok');
	});
});

