import { isTauri } from '@tauri-apps/api/core';
import type { RadarSite } from '$lib/domain/types';
import knownSites from './known-sites.json';

/**
 * User-entered radar site locations (lat/lon/altM), keyed by site code, persisted in the
 * browser so formats that don't self-describe position (NEXRAD L2, .obs) only need it entered
 * once. Same web-only localStorage pattern as config.ts -- see that file for the Tauri caveat.
 */

export interface SiteLocation {
	lat: number;
	lon: number;
	altM: number;
	updatedAt: string;
}

export type SiteDataStore = Record<string, SiteLocation>;

const STORAGE_KEY = 'lamula-process:site-data';

/** Stable lookup key for a site: prefer its code, fall back to name. */
export function siteKey(site: Pick<RadarSite, 'code' | 'name'>): string {
	return site.code || site.name;
}

export async function loadSiteData(): Promise<SiteDataStore> {
	if (isTauri()) throw new Error('Tauri site-data store not implemented yet');
	const raw = localStorage.getItem(STORAGE_KEY);
	if (!raw) return {};
	try {
		const parsed = JSON.parse(raw);
		return parsed && typeof parsed === 'object' ? parsed : {};
	} catch {
		return {};
	}
}

export async function saveSiteData(store: SiteDataStore): Promise<void> {
	if (isTauri()) throw new Error('Tauri site-data store not implemented yet');
	localStorage.setItem(STORAGE_KEY, JSON.stringify(store));
}

export async function getSiteLocation(key: string): Promise<SiteLocation | undefined> {
	const store = await loadSiteData();
	return store[key];
}

export async function setSiteLocation(
	key: string,
	location: Omit<SiteLocation, 'updatedAt'>
): Promise<SiteDataStore> {
	const store = await loadSiteData();
	const updated: SiteDataStore = {
		...store,
		[key]: { ...location, updatedAt: new Date().toISOString() }
	};
	await saveSiteData(updated);
	return updated;
}

/** Serialize the whole store for a user-triggered download. */
export function exportSiteData(store: SiteDataStore): string {
	return JSON.stringify(store, null, 2);
}

/** Merge a previously exported JSON blob into the stored data (imported entries win on conflict). */
export async function importSiteData(json: string): Promise<SiteDataStore> {
	const incoming = JSON.parse(json);
	if (!incoming || typeof incoming !== 'object') throw new Error('invalid site-data JSON');
	const store = await loadSiteData();
	const merged: SiteDataStore = { ...store, ...incoming };
	await saveSiteData(merged);
	return merged;
}

/**
 * Seed the collection with the bundled public radar networks (Cuban INSMET sites keyed by the
 * rd* codes in src/lib/parsers/insmet/parse.ts, NOAA WSR-88D sites keyed by the ICAO id the
 * nexrad-l2 parser reads from the volume header) -- see known-sites.json for provenance. A
 * location the user already saved for a given key wins over the seed, so re-running this never
 * clobbers a hand-edited site.
 */
export async function loadKnownSitesSeed(): Promise<SiteDataStore> {
	const store = await loadSiteData();
	const merged: SiteDataStore = { ...(knownSites as SiteDataStore), ...store };
	await saveSiteData(merged);
	return merged;
}
