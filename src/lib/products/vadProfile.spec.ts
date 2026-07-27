import { describe, it, expect } from 'vitest';
import type { Channel } from '$lib/domain/types';
import { makeScan } from '$lib/render/scanFixtures';
import { computeVadProfile, getCardinalDirection } from './vadProfile';

const DEG = Math.PI / 180;

function makeVadChannel(vx: number, vy: number): Channel {
	return {
		id: 0,
		moment: 'V',
		beamWidthDeg: 1,
		scans: [0.5, 1.5, 2.5].map((elev) => {
			const cosE = Math.cos(elev * DEG);
			return makeScan({
				numRays: 16,
				numGates: 4,
				gateLengthM: 1000,
				angleDeg: elev,
				fill: (r) => {
					const az = r * (360 / 16) * DEG;
					return vx * cosE * Math.sin(az) + vy * cosE * Math.cos(az);
				}
			});
		})
	};
}

describe('getCardinalDirection', () => {
	it('converts degrees to cardinal points correctly', () => {
		expect(getCardinalDirection(0)).toBe('N');
		expect(getCardinalDirection(90)).toBe('E');
		expect(getCardinalDirection(180)).toBe('S');
		expect(getCardinalDirection(270)).toBe('W');
		expect(getCardinalDirection(216.87)).toBe('SW');
	});
});

describe('computeVadProfile', () => {
	it('computes levels across multiple elevation cuts and range rings', () => {
		const channel = makeVadChannel(3, 4); // wind vector (E3, N4) -> speed 5 m/s
		const profile = computeVadProfile(channel, { minSamples: 4 });

		expect(profile.levels.length).toBe(12); // 3 scans * 4 gates
		expect(profile.maxSpeedMs).toBeCloseTo(5, 4);

		for (const lvl of profile.levels) {
			expect(lvl.speedMs).toBeCloseTo(5, 4);
			expect(lvl.vx).toBeCloseTo(3, 4);
			expect(lvl.vy).toBeCloseTo(4, 4);
			expect(lvl.rmsMs).toBeCloseTo(0, 4);
		}
	});
});
