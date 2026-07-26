import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { US_RADAR_SITES, nearestSites, geocodeZip } from './radarCatalog';

describe('US_RADAR_SITES', () => {
	it('excludes the Cuban INSMET rd* keys, keeps WSR-88D ICAO codes', () => {
		expect(US_RADAR_SITES.some((s) => s.code.startsWith('rd'))).toBe(false);
		expect(US_RADAR_SITES.find((s) => s.code === 'KBYX')).toEqual({
			code: 'KBYX',
			lat: 24.59694,
			lon: -81.70333,
			altM: 2.44
		});
	});
});

describe('nearestSites', () => {
	it('ranks Key West-area coordinates with KBYX as the nearest US site', () => {
		const result = nearestSites({ lat: 24.55, lon: -81.75 }, US_RADAR_SITES, 3);
		expect(result).toHaveLength(3);
		expect(result[0].code).toBe('KBYX');
		expect(result[0].distanceKm).toBeLessThan(result[1].distanceKm);
	});
});

describe('geocodeZip', () => {
	let originalFetch: typeof fetch;

	beforeEach(() => {
		originalFetch = globalThis.fetch;
	});

	afterEach(() => {
		globalThis.fetch = originalFetch;
	});

	it('returns lat/lon from the first Nominatim result', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			json: async () => [{ lat: '24.5551', lon: '-81.7800' }]
		})) as unknown as typeof fetch;

		expect(await geocodeZip('33040')).toEqual({ lat: 24.5551, lon: -81.78 });
	});

	it('returns null when no result is found', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			json: async () => []
		})) as unknown as typeof fetch;
		expect(await geocodeZip('00000')).toBeNull();
	});

	it('returns null on a non-ok response', async () => {
		globalThis.fetch = vi.fn(async () => ({ ok: false })) as unknown as typeof fetch;
		expect(await geocodeZip('33040')).toBeNull();
	});

	it('returns null when fetch throws (network down)', async () => {
		globalThis.fetch = vi.fn(async () => {
			throw new Error('network down');
		}) as unknown as typeof fetch;
		expect(await geocodeZip('33040')).toBeNull();
	});
});
