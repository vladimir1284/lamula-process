// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { isTauri } from '@tauri-apps/api/core';

vi.mock('@tauri-apps/api/core', () => ({ isTauri: vi.fn(() => false) }));

import {
	loadSiteData,
	saveSiteData,
	getSiteLocation,
	setSiteLocation,
	exportSiteData,
	importSiteData,
	loadKnownSitesSeed,
	siteKey
} from './siteData';

beforeEach(() => {
	localStorage.clear();
	vi.mocked(isTauri).mockReturnValue(false);
});

describe('siteKey', () => {
	it('prefers code over name', () => {
		expect(siteKey({ code: 'CMW', name: 'Camagüey' })).toBe('CMW');
	});

	it('falls back to name when code is empty', () => {
		expect(siteKey({ code: '', name: 'Camagüey' })).toBe('Camagüey');
	});
});

describe('on Tauri (not implemented yet)', () => {
	it('loadSiteData/saveSiteData both throw', async () => {
		vi.mocked(isTauri).mockReturnValue(true);
		await expect(loadSiteData()).rejects.toThrow(/not implemented yet/);
		await expect(saveSiteData({})).rejects.toThrow(/not implemented yet/);
	});
});

describe('loadSiteData', () => {
	it('returns an empty store when nothing is stored', async () => {
		expect(await loadSiteData()).toEqual({});
	});

	it('falls back to empty on corrupt JSON', async () => {
		localStorage.setItem('lamula-process:site-data', '{not json');
		expect(await loadSiteData()).toEqual({});
	});
});

describe('getSiteLocation / setSiteLocation', () => {
	it('returns undefined for an unknown key', async () => {
		expect(await getSiteLocation('CMW')).toBeUndefined();
	});

	it('persists a location and stamps updatedAt', async () => {
		const updated = await setSiteLocation('CMW', { lat: 21.4, lon: -77.9, altM: 100 });
		expect(updated.CMW).toMatchObject({ lat: 21.4, lon: -77.9, altM: 100 });
		expect(typeof updated.CMW.updatedAt).toBe('string');

		const fetched = await getSiteLocation('CMW');
		expect(fetched).toEqual(updated.CMW);
	});

	it('does not clobber other keys', async () => {
		await setSiteLocation('CMW', { lat: 21.4, lon: -77.9, altM: 100 });
		await setSiteLocation('HAV', { lat: 23.1, lon: -82.4, altM: 50 });
		const store = await loadSiteData();
		expect(Object.keys(store).sort()).toEqual(['CMW', 'HAV']);
	});
});

describe('export/import', () => {
	it('round-trips through export -> import into an empty store', async () => {
		await setSiteLocation('CMW', { lat: 21.4, lon: -77.9, altM: 100 });
		const store = await loadSiteData();
		const json = exportSiteData(store);

		localStorage.clear();
		const imported = await importSiteData(json);
		expect(imported).toEqual(store);
	});

	it('merges imported entries with existing ones, imported wins on conflict', async () => {
		await setSiteLocation('CMW', { lat: 1, lon: 1, altM: 1 });
		const json = JSON.stringify({
			CMW: { lat: 99, lon: 99, altM: 99, updatedAt: 'x' },
			HAV: { lat: 23.1, lon: -82.4, altM: 50, updatedAt: 'y' }
		});
		const merged = await importSiteData(json);
		expect(merged.CMW).toEqual({ lat: 99, lon: 99, altM: 99, updatedAt: 'x' });
		expect(merged.HAV).toEqual({ lat: 23.1, lon: -82.4, altM: 50, updatedAt: 'y' });
	});

	it('rejects a null-shaped payload', async () => {
		await expect(importSiteData('null')).rejects.toThrow(/invalid site-data/);
	});

	it('rejects malformed JSON', async () => {
		await expect(importSiteData('{not json')).rejects.toThrow();
	});
});

describe('loadKnownSitesSeed', () => {
	it('fills the store with bundled Cuban and NOAA sites', async () => {
		const store = await loadKnownSitesSeed();
		expect(store.rdGranPiedra).toMatchObject({ lat: 20.03, lon: -75.63, altM: 1230 });
		expect(store.KMLB).toBeDefined();
		expect(Object.keys(store).length).toBeGreaterThan(150);
	});

	it('does not clobber a location the user already saved for that key', async () => {
		await setSiteLocation('KMLB', { lat: 1, lon: 1, altM: 1 });
		const store = await loadKnownSitesSeed();
		expect(store.KMLB).toMatchObject({ lat: 1, lon: 1, altM: 1 });
	});
});
