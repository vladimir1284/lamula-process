import { describe, it, expect } from 'vitest';
import { toLinear, fromLinear, isReflectivity } from './measure';

describe('measure linear conversions', () => {
	it('treats dBZ / dBuZ as reflectivity (dB <-> Z)', () => {
		expect(isReflectivity('dBZ')).toBe(true);
		expect(isReflectivity('dBuZ')).toBe(true);
		expect(toLinear(20, 'dBZ')).toBeCloseTo(100, 6);
		expect(toLinear(40, 'dBZ')).toBeCloseTo(10000, 6);
		expect(fromLinear(100, 'dBZ')).toBeCloseTo(20, 6);
	});

	it('round-trips reflectivity', () => {
		for (const v of [-10, 0, 15.5, 55])
			expect(fromLinear(toLinear(v, 'dBZ'), 'dBZ')).toBeCloseTo(v, 6);
	});

	it('is identity for non-reflectivity moments', () => {
		expect(isReflectivity('V')).toBe(false);
		expect(toLinear(12.3, 'V')).toBe(12.3);
		expect(fromLinear(12.3, 'V')).toBe(12.3);
	});
});
