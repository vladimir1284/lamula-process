import { describe, it, expect } from 'vitest';
import { setCell } from '$lib/domain/cells';
import { makeScan } from './scanFixtures';
import {
	normDeg,
	rayCentersDeg,
	circularDiffDeg,
	buildAzimuthLUT,
	rayIndexForAzimuth,
	gateForGroundRange,
	maxGroundRangeM,
	sampleGround
} from './scanSample';

describe('angle helpers', () => {
	it('normDeg wraps into [0,360)', () => {
		expect(normDeg(0)).toBe(0);
		expect(normDeg(360)).toBe(0);
		expect(normDeg(-90)).toBe(270);
		expect(normDeg(450)).toBe(90);
	});

	it('circularDiffDeg takes the short way around', () => {
		expect(circularDiffDeg(350, 10)).toBeCloseTo(20, 6);
		expect(circularDiffDeg(10, 350)).toBeCloseTo(20, 6);
		expect(circularDiffDeg(0, 180)).toBeCloseTo(180, 6);
	});
});

describe('rayCentersDeg', () => {
	it('centres ray 0 on North and spaces uniformly, handling wrap', () => {
		const c = rayCentersDeg(makeScan({ numRays: 4 }));
		expect(Array.from(c)).toEqual([0, 90, 180, 270]);
	});
});

describe('azimuth LUT', () => {
	it('maps each cardinal azimuth to the nearest ray', () => {
		const scan = makeScan({ numRays: 4 });
		const lut = buildAzimuthLUT(scan);
		expect(rayIndexForAzimuth(lut, 0)).toBe(0); // N
		expect(rayIndexForAzimuth(lut, 90)).toBe(1); // E
		expect(rayIndexForAzimuth(lut, 180)).toBe(2); // S
		expect(rayIndexForAzimuth(lut, 270)).toBe(3); // W
		expect(rayIndexForAzimuth(lut, 359)).toBe(0); // wraps back to N
	});
});

describe('gateForGroundRange', () => {
	it('indexes gates by ground range at 0° elevation', () => {
		const scan = makeScan({ numGates: 3, gateLengthM: 1000, rangeToFirstGateM: 0 });
		expect(gateForGroundRange(scan, 0)).toBe(0);
		expect(gateForGroundRange(scan, 1000)).toBe(1);
		expect(gateForGroundRange(scan, 2000)).toBe(2);
		expect(gateForGroundRange(scan, 5000)).toBe(-1); // beyond last gate
	});

	it('projects ground->slant by elevation before indexing', () => {
		const scan = makeScan({ numGates: 5, gateLengthM: 1000, angleDeg: 60 });
		// cos60 = 0.5, so ground 1000 -> slant 2000 -> gate 2
		expect(gateForGroundRange(scan, 1000)).toBe(2);
	});
});

describe('maxGroundRangeM', () => {
	it('is the outermost gate slant range projected to ground', () => {
		const scan = makeScan({ numGates: 3, gateLengthM: 1000, rangeToFirstGateM: 0, angleDeg: 0 });
		expect(maxGroundRangeM(scan)).toBeCloseTo(2000, 6); // gate index 2 -> 2000 m
	});
});

describe('sampleGround', () => {
	it('reads the (ray,gate) a ground point falls in', () => {
		const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000 });
		const lut = buildAzimuthLUT(scan);
		// due North, range 1000 -> ray 0, gate 1 -> value 0*100+1 = 1
		expect(sampleGround(scan, lut, 0, 1000)).toEqual({ value: 1, flag: 'ok' });
		// due East, range 2000 -> ray 1, gate 2 -> value 1*100+2 = 102
		expect(sampleGround(scan, lut, 2000, 0)).toEqual({ value: 102, flag: 'ok' });
		// due South, range 1000 -> ray 2, gate 1 -> value 201
		expect(sampleGround(scan, lut, 0, -1000)).toEqual({ value: 201, flag: 'ok' });
	});

	it('returns null outside the gated disc', () => {
		const scan = makeScan({ numGates: 3, gateLengthM: 1000 });
		const lut = buildAzimuthLUT(scan);
		expect(sampleGround(scan, lut, 10_000, 0)).toBeNull();
	});

	it('surfaces non-ok flags', () => {
		const scan = makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000 });
		setCell(scan.cells, 0, 1, -32, 'below-threshold');
		const lut = buildAzimuthLUT(scan);
		expect(sampleGround(scan, lut, 0, 1000)).toEqual({ value: -32, flag: 'below-threshold' });
	});
});
