import { describe, it, expect } from 'vitest';
import { haversineKm } from './distance';

describe('haversineKm', () => {
	it('is 0 for the same point', () => {
		expect(haversineKm({ lat: 21.4, lon: -77.9 }, { lat: 21.4, lon: -77.9 })).toBe(0);
	});

	it('matches a known great-circle distance (KBYX to KAMX, ~172 km)', () => {
		const kbyx = { lat: 24.59667, lon: -81.70306 };
		const kamx = { lat: 25.61111, lon: -80.41278 };
		expect(haversineKm(kbyx, kamx)).toBeCloseTo(172.05, 1);
	});

	it('is symmetric', () => {
		const a = { lat: 45.0, lon: -98.0 };
		const b = { lat: 35.0, lon: -106.0 };
		expect(haversineKm(a, b)).toBeCloseTo(haversineKm(b, a), 6);
	});
});
