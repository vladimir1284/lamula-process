import { describe, it, expect } from 'vitest';
import { groundRangeM } from './groundRange';

describe('groundRangeM', () => {
	it('equals slant range at 0° elevation', () => {
		expect(groundRangeM(100_000, 0)).toBeCloseTo(100_000, 6);
	});

	it('shrinks with elevation (cosine projection)', () => {
		expect(groundRangeM(100_000, 60)).toBeCloseTo(50_000, 6); // cos60 = 0.5
		expect(groundRangeM(100_000, 90)).toBeCloseTo(0, 6);
	});

	it('is monotonically decreasing in elevation', () => {
		const r = 80_000;
		expect(groundRangeM(r, 0)).toBeGreaterThan(groundRangeM(r, 5));
		expect(groundRangeM(r, 5)).toBeGreaterThan(groundRangeM(r, 20));
	});
});
