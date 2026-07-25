import { fromLonLat } from 'ol/proj';
import type { Extent } from 'ol/extent';

/**
 * Georeferencing helpers to place a radar's ground plane onto the OpenLayers map.
 *
 * The radar image is a flat local plane centred on the site (legacy convention). We embed
 * it in the map's Web Mercator (EPSG:3857) projection so it composites with lon/lat geo
 * overlays. Web Mercator's north-south scale grows as 1/cos(lat), so `groundRangeM` ground
 * metres correspond to `groundRangeM / cos(lat)` projected units — applied here so a scan
 * of true radius R km lands at the right physical size. This is the flat-earth
 * approximation the legacy viewer already made; distortion is a few percent at Cuba's
 * latitude (~21°N) over a 250 km scan and is documented, not silently absorbed.
 */

/** Mercator projected-units per ground metre at a given latitude. */
export function mercatorScaleAtLat(latDeg: number): number {
	return 1 / Math.cos((latDeg * Math.PI) / 180);
}

/**
 * Square extent [minX, minY, maxX, maxY] in EPSG:3857 covering the radar's ground disc of
 * radius `groundRangeM` around the site.
 */
export function siteExtent3857(lon: number, lat: number, groundRangeM: number): Extent {
	const [cx, cy] = fromLonLat([lon, lat]);
	const half = groundRangeM * mercatorScaleAtLat(lat);
	return [cx - half, cy - half, cx + half, cy + half];
}

/** Site centre in EPSG:3857, convenience for centring the view. */
export function siteCenter3857(lon: number, lat: number): [number, number] {
	const [cx, cy] = fromLonLat([lon, lat]);
	return [cx, cy];
}
