/**
 * Terrain elevation lookup for the site-location editor's altM default. Backed by the public
 * Open-Elevation API (no key, but no SLA either) -- failures are swallowed to null so the
 * caller falls back to manual altM entry instead of blocking the flow.
 */

const OPEN_ELEVATION_URL = 'https://api.open-elevation.com/api/v1/lookup';

interface OpenElevationResponse {
	results?: { elevation: number }[];
}

/** Terrain elevation in metres at (lat, lon), or null if the lookup fails for any reason. */
export async function fetchElevationM(lat: number, lon: number): Promise<number | null> {
	try {
		const url = `${OPEN_ELEVATION_URL}?locations=${lat},${lon}`;
		const res = await fetch(url);
		if (!res.ok) return null;
		const body = (await res.json()) as OpenElevationResponse;
		const elevation = body.results?.[0]?.elevation;
		return typeof elevation === 'number' ? elevation : null;
	} catch {
		return null;
	}
}
