import { describe, it, expect } from 'vitest';
import { buildSpline, evalSpline } from './spline';

describe('natural cubic spline', () => {
	it('reproduces knot values at the knots', () => {
		const s = buildSpline([0, 1, 2, 3], [0, 1, 4, 9]); // y = x²
		expect(evalSpline(s, 0)).toBeCloseTo(0, 10);
		expect(evalSpline(s, 2)).toBeCloseTo(4, 10);
		expect(evalSpline(s, 3)).toBeCloseTo(9, 10);
	});

	it('is exact on collinear points (zero curvature)', () => {
		const s = buildSpline([0, 1, 2, 3], [0, 2, 4, 6]); // y = 2x
		expect(evalSpline(s, 1.5)).toBeCloseTo(3, 10);
		expect(evalSpline(s, 2.5)).toBeCloseTo(5, 10);
	});

	it('clamps flat outside the range', () => {
		const s = buildSpline([1, 2, 3], [10, 20, 30]);
		expect(evalSpline(s, -5)).toBe(10);
		expect(evalSpline(s, 99)).toBe(30);
	});

	it('handles degenerate short inputs', () => {
		expect(evalSpline(buildSpline([5], [42]), 100)).toBe(42);
		const line = buildSpline([0, 10], [0, 100]);
		expect(evalSpline(line, 5)).toBeCloseTo(50, 10);
	});
});
