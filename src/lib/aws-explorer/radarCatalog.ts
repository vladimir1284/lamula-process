/**
 * Catalogue of US WSR-88D radar sites for the AWS NEXRAD explorer -- these are the only sites
 * present on the `unidata-nexrad-level2` bucket. `known-sites.json` also carries 9 Cuban INSMET
 * codes (keyed `rd*`, see src/lib/platform/siteData.ts) which aren't on this bucket and must be
 * excluded here.
 */
import knownSites from '$lib/platform/known-sites.json';
import { haversineKm } from '$lib/geo';

export interface RadarCatalogSite {
	code: string;
	lat: number;
	lon: number;
	altM: number;
}

export const US_RADAR_SITES: RadarCatalogSite[] = Object.entries(knownSites)
	.filter(([code]) => !code.startsWith('rd'))
	.map(([code, loc]) => ({ code, lat: loc.lat, lon: loc.lon, altM: loc.altM }));

/** Sites nearest `target`, closest first. */
export function nearestSites(
	target: { lat: number; lon: number },
	sites: RadarCatalogSite[] = US_RADAR_SITES,
	n = 5
): (RadarCatalogSite & { distanceKm: number })[] {
	return sites
		.map((site) => ({ ...site, distanceKm: haversineKm(target, site) }))
		.sort((a, b) => a.distanceKm - b.distanceKm)
		.slice(0, n);
}

interface NominatimResult {
	lat: string;
	lon: string;
}

/**
 * US zip code -> lat/lon via OSM's public Nominatim geocoder. No key, no SLA, and its usage
 * policy caps anonymous callers at ~1 req/sec -- fine for one lookup per user click, not for
 * batch use. Failures collapse to null the same way fetchElevationM does.
 */
export async function geocodeZip(zip: string): Promise<{ lat: number; lon: number } | null> {
	try {
		const url = `https://nominatim.openstreetmap.org/search?postalcode=${encodeURIComponent(zip)}&country=us&format=json&limit=1`;
		const res = await fetch(url);
		if (!res.ok) return null;
		const body = (await res.json()) as NominatimResult[];
		const first = body[0];
		if (!first) return null;
		const lat = Number(first.lat);
		const lon = Number(first.lon);
		return Number.isNaN(lat) || Number.isNaN(lon) ? null : { lat, lon };
	} catch {
		return null;
	}
}
