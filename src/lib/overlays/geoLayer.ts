import VectorLayer from 'ol/layer/Vector';
import VectorSource from 'ol/source/Vector';
import GeoJSON from 'ol/format/GeoJSON';
import { Style, Stroke } from 'ol/style';
import type { StyleLike } from 'ol/style/Style';
import type { Feature } from 'ol';
import type Geometry from 'ol/geom/Geometry';

/**
 * Geo overlay layers (coastlines / rivers / political borders) for the PPI map.
 *
 * The bundled GeoJSON in `static/geo/` is Natural Earth 1:50m clipped to the Cuba +
 * Central-America region (see scratchpad/fetch-geo.mjs for provenance). Data is lon/lat
 * (EPSG:4326); OpenLayers reprojects it to the map projection (EPSG:3857) on load.
 */

export const coastStyle = new Style({
	stroke: new Stroke({ color: 'rgba(180,220,255,0.8)', width: 1.2 })
});
export const riverStyle = new Style({
	stroke: new Stroke({ color: 'rgba(120,170,240,0.7)', width: 0.8 })
});
export const borderStyle = new Style({
	stroke: new Stroke({ color: 'rgba(255,220,150,0.7)', width: 1, lineDash: [4, 3] })
});

export interface GeoLayerOptions {
	name: string;
	style: StyleLike;
	/** URL of a GeoJSON asset (auto-loaded), or… */
	url?: string;
	/** …inline features already in lon/lat, reprojected to `featureProjection`. */
	features?: Feature<Geometry>[];
	/** Map projection features should end up in. Default EPSG:3857. */
	featureProjection?: string;
}

export function geoJsonLayer(opts: GeoLayerOptions): VectorLayer<VectorSource> {
	const featureProjection = opts.featureProjection ?? 'EPSG:3857';
	const format = new GeoJSON({ dataProjection: 'EPSG:4326', featureProjection });
	const source = opts.url
		? new VectorSource({ url: opts.url, format })
		: new VectorSource({ features: opts.features ?? [] });
	const layer = new VectorLayer({ source, style: opts.style });
	layer.set('name', opts.name);
	return layer;
}

/** The three standard overlays loading from the bundled static assets. */
export function standardOverlays(base = '/geo'): VectorLayer<VectorSource>[] {
	return [
		geoJsonLayer({ name: 'coastline', url: `${base}/coastline.geojson`, style: coastStyle }),
		geoJsonLayer({ name: 'rivers', url: `${base}/rivers.geojson`, style: riverStyle }),
		geoJsonLayer({ name: 'borders', url: `${base}/borders.geojson`, style: borderStyle })
	];
}
