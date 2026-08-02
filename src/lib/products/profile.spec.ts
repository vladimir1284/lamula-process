import { describe, it, expect } from 'vitest';
import { makeScan } from '$lib/render/scanFixtures';
import { computeProfile } from './profile';

describe('computeProfile', () => {
	// four elevations, each a constant value; a north point samples one per tilt
	const scans = [0, 5, 10, 15].map((elev) =>
		makeScan({ numRays: 4, numGates: 10, gateLengthM: 1000, angleDeg: elev, fill: () => elev * 2 })
	);

	it('collects one ascending-height sample per elevation', () => {
		const { samples } = computeProfile(scans, { xEastM: 0, yNorthM: 3000, beamWidthDeg: 1 });
		expect(samples).toHaveLength(4);
		expect(samples.map((s) => s.value)).toEqual([0, 10, 20, 30]); // elev·2, low→high
		for (let i = 1; i < samples.length; i++)
			expect(samples[i].heightM).toBeGreaterThan(samples[i - 1].heightM);
	});

	it('interpolates onto the height grid up to topM, flat at the last estimated value above the highest sample', () => {
		const { heightsM, values } = computeProfile(scans, {
			xEastM: 0,
			yNorthM: 3000,
			beamWidthDeg: 1,
			topM: 20000,
			cellHeightM: 250
		});
		expect(heightsM[0]).toBe(0);
		expect(heightsM[heightsM.length - 1]).toBe(20000);
		expect(values[values.length - 1]).toBeCloseTo(30, 6); // flat at highest sample's value (elev·2 = 30)
		// flat below the lowest sample → equals the lowest sample value (0 here)
		expect(values[0]).toBeCloseTo(0, 6);
	});

	it('reproduces a sample value at its own height', () => {
		const { samples } = computeProfile(scans, { xEastM: 0, yNorthM: 3000, beamWidthDeg: 1 });
		// rebuild at fine resolution and read near the second sample's height
		const { heightsM, values } = computeProfile(scans, {
			xEastM: 0,
			yNorthM: 3000,
			beamWidthDeg: 1,
			cellHeightM: 10
		});
		const target = samples[1].heightM;
		let nearest = 0;
		for (let i = 1; i < heightsM.length; i++)
			if (Math.abs(heightsM[i] - target) < Math.abs(heightsM[nearest] - target)) nearest = i;
		expect(values[nearest]).toBeCloseTo(samples[1].value, 0);
	});
});
