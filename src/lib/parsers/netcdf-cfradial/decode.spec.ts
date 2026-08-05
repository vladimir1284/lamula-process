import { describe, it, expect } from 'vitest';
import { rayCenterToStartStop } from './decode';

describe('rayCenterToStartStop', () => {
	it('bisects evenly-spaced ray centers to shared boundaries', () => {
		const { start, stop } = rayCenterToStartStop(new Float32Array([0, 10, 20, 30]));
		expect(Array.from(start)).toEqual([-5, 5, 15, 25].map((v) => (v < 0 ? v + 360 : v)));
		expect(Array.from(stop)).toEqual([5, 15, 25, 35]);
		// adjacent rays share a boundary (ray i's stop === ray i+1's start)
		expect(stop[0]).toBeCloseTo(start[1]);
		expect(stop[1]).toBeCloseTo(start[2]);
	});

	it('wraps correctly across the 0/360 discontinuity', () => {
		const { start, stop } = rayCenterToStartStop(new Float32Array([350, 0, 10]));
		expect(start[1]).toBeCloseTo(355);
		expect(stop[1]).toBeCloseTo(5);
	});

	it('two identical consecutive centers (real fixture has this) share a zero-width boundary', () => {
		const { start, stop } = rayCenterToStartStop(new Float32Array([88, 88, 90]));
		// ray 0's stop and ray 1's start both sit at the shared (identical) center -- zero-width
		// on that side, but ray 1 still spans out to a real boundary on the other side (ray 2).
		expect(stop[0]).toBeCloseTo(88);
		expect(start[1]).toBeCloseTo(88);
		expect(stop[1]).toBeCloseTo(89);
	});
});
