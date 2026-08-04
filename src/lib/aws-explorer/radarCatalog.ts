/**
 * Catalogue of radar sites for the AWS explorer, one list per bucket:
 *  - US_RADAR_SITES: WSR-88D sites on the `unidata-nexrad-level2` bucket (nexradS3.ts).
 *  - CO_RADAR_SITES: IDEAM sites on the `s3-radaresideam` bucket (ideamS3.ts).
 * `known-sites.json` also carries 9 Cuban INSMET codes (keyed `rd*`, see
 * src/lib/platform/siteData.ts) which aren't on either bucket and must stay excluded from both.
 */
import knownSites from '$lib/platform/known-sites.json';
import { haversineKm } from '$lib/geo';

export interface RadarCatalogSite {
	code: string;
	lat: number;
	lon: number;
	altM: number;
}

// The IDEAM S3 folder names -- verified live against s3-radaresideam, see ideamS3.ts's header
// comment. Bogota and santa_elena are NetCDF PPIVol; the rest are Sigmet/IRIS RAW.
const IDEAM_RADAR_CODES = new Set([
	'Guaviare',
	'Munchique',
	'Carimagua',
	'Barrancabermeja',
	'Corozal',
	'Tablazo',
	'Bogota',
	'santa_elena'
]);

export const US_RADAR_SITES: RadarCatalogSite[] = Object.entries(knownSites)
	.filter(([code]) => !code.startsWith('rd') && !IDEAM_RADAR_CODES.has(code))
	.map(([code, loc]) => ({ code, lat: loc.lat, lon: loc.lon, altM: loc.altM }));

export const CO_RADAR_SITES: RadarCatalogSite[] = Object.entries(knownSites)
	.filter(([code]) => IDEAM_RADAR_CODES.has(code))
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
 * Postal code -> lat/lon via OSM's public Nominatim geocoder. No key, no SLA, and its usage
 * policy caps anonymous callers at ~1 req/sec -- fine for one lookup per user click, not for
 * batch use. Failures collapse to null the same way fetchElevationM does.
 */
export async function geocodeZip(
	zip: string,
	country: 'us' | 'co' = 'us'
): Promise<{ lat: number; lon: number } | null> {
	try {
		const url = `https://nominatim.openstreetmap.org/search?postalcode=${encodeURIComponent(zip)}&country=${country}&format=json&limit=1`;
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
