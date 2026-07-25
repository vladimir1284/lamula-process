import { describe, it, expect } from 'vitest';
import { fromLonLat } from 'ol/proj';
import { siteExtent3857, siteCenter3857, mercatorScaleAtLat } from './extent';

describe('mercatorScaleAtLat', () => {
	it('is 1 at the equator and grows toward the poles', () => {
		expect(mercatorScaleAtLat(0)).toBeCloseTo(1, 6);
		expect(mercatorScaleAtLat(60)).toBeCloseTo(2, 6); // 1/cos60
		expect(mercatorScaleAtLat(21)).toBeGreaterThan(1);
	});
});

describe('siteExtent3857', () => {
	it('is centred on the site and square', () => {
		const [lon, lat] = [-77.85, 21.42]; // Camagüey-ish
		const [cx, cy] = fromLonLat([lon, lat]);
		const [minX, minY, maxX, maxY] = siteExtent3857(lon, lat, 250_000);
		expect((minX + maxX) / 2).toBeCloseTo(cx, 3);
		expect((minY + maxY) / 2).toBeCloseTo(cy, 3);
		expect(maxX - minX).toBeCloseTo(maxY - minY, 3);
	});

	it('scales ground metres into projected units by the latitude factor', () => {
		const lat = 21.42;
		const [minX, , maxX] = siteExtent3857(-77.85, lat, 250_000);
		const halfProjected = (maxX - minX) / 2;
		expect(halfProjected).toBeCloseTo(250_000 * mercatorScaleAtLat(lat), 1);
	});

	it('siteCenter3857 matches fromLonLat', () => {
		expect(siteCenter3857(-77.85, 21.42)).toEqual(fromLonLat([-77.85, 21.42]));
	});
});
