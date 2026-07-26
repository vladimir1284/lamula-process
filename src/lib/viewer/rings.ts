import Feature from 'ol/Feature';
import type { FeatureLike } from 'ol/Feature';
import CircleGeom from 'ol/geom/Circle';
import Point from 'ol/geom/Point';
import { Style, Stroke, Text, Fill } from 'ol/style';
import { formatDistanceM, type UnitSystem } from '$lib/units';

/**
 * Range-ring features for the PPI overlay. Rings are drawn in the map projection (EPSG:3857)
 * as circles centred on the site, with radius = groundMetres · mercatorScale so they line up
 * with the georeferenced radar raster (same flat-earth scaling, see geo/extent.ts).
 */

export interface RingOptions {
	center3857: [number, number];
	/** Ring radii in ground metres. */
	ringsM: number[];
	/** Projected-units per ground metre at the site latitude. */
	mercatorScale: number;
	/** Label each ring in km. Default true. */
	labels?: boolean;
	/** Unit system for the ring label text. Default metric (km). */
	unitSystem?: UnitSystem;
}

export function ringFeatures(opts: RingOptions): Feature[] {
	const feats: Feature[] = [];
	const system = opts.unitSystem ?? 'metric';
	for (const m of opts.ringsM) {
		const radius = m * opts.mercatorScale;
		const ring = new Feature(new CircleGeom(opts.center3857, radius));
		ring.set('kind', 'ring');
		feats.push(ring);
		if (opts.labels ?? true) {
			// place a label at the ring's north point
			const label = new Feature(new Point([opts.center3857[0], opts.center3857[1] + radius]));
			label.set('kind', 'ring-label');
			label.set('text', formatDistanceM(m, system, 0));
			feats.push(label);
		}
	}
	return feats;
}

export function ringStyle(feature: FeatureLike): Style {
	const kind = feature.get('kind');
	if (kind === 'ring-label') {
		return new Style({
			text: new Text({
				text: feature.get('text'),
				font: '11px sans-serif',
				fill: new Fill({ color: 'rgba(255,255,255,0.9)' }),
				stroke: new Stroke({ color: 'rgba(0,0,0,0.7)', width: 2 }),
				offsetY: -6
			})
		});
	}
	return new Style({
		stroke: new Stroke({ color: 'rgba(255,255,255,0.35)', width: 1 })
	});
}

/** Default rings covering an extent's half-width, one every `stepM` metres. */
export function defaultRingsM(maxRangeM: number, stepM = 50_000): number[] {
	const rings: number[] = [];
	for (let m = stepM; m <= maxRangeM + 1; m += stepM) rings.push(m);
	return rings;
}
