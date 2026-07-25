import { describe, it, expect } from 'vitest';
import { getCell, setCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { computeWind, windDirectionDeg, fitRingVad } from './wind';

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

describe('fitRingVad', () => {
	it('recovers seeded components from a clean ring', () => {
		const numRays = 16;
		const az = new Float64Array(numRays);
		const vr = new Float64Array(numRays);
		const step = 360 / numRays;
		for (let i = 0; i < numRays; i++) {
			az[i] = i * step * DEG;
			vr[i] = 3 * Math.sin(az[i]) + 4 * Math.cos(az[i]); // cosElev = 1
		}
		const fit = fitRingVad(az, vr, 1, numRays)!;
		expect(fit.vx).toBeCloseTo(3, 6);
		expect(fit.vy).toBeCloseTo(4, 6);
	});
	it('returns null when under-determined', () => {
		expect(fitRingVad(new Float64Array(1), new Float64Array(1), 1, 1)).toBeNull();
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
