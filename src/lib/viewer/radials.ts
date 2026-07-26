import Feature from 'ol/Feature';
import type { FeatureLike } from 'ol/Feature';
import LineString from 'ol/geom/LineString';
import Point from 'ol/geom/Point';
import { Style, Stroke, Text, Fill } from 'ol/style';

/**
 * Azimuth-radial features for the PPI overlay. Radials are straight lines from the site out to
 * `rangeM`, drawn in the map projection (EPSG:3857) using the same flat-earth scaling as the
 * range rings (see rings.ts / geo/extent.ts).
 */

export interface RadialOptions {
	center3857: [number, number];
	/** Outer radius in ground metres (typically the scan's max range). */
	rangeM: number;
	/** Projected-units per ground metre at the site latitude. */
	mercatorScale: number;
	/** Degrees between radials. Default 30. */
	stepDeg?: number;
	/** Label each radial with its azimuth in degrees. Default true. */
	labels?: boolean;
}

export function radialFeatures(opts: RadialOptions): Feature[] {
	const feats: Feature[] = [];
	const step = opts.stepDeg ?? 30;
	const radius = opts.rangeM * opts.mercatorScale;
	const [cx, cy] = opts.center3857;
	for (let az = 0; az < 360; az += step) {
		// Compass azimuth (0=N, clockwise) to map XY: x = sin(az), y = cos(az).
		const rad = (az * Math.PI) / 180;
		const tipX = cx + radius * Math.sin(rad);
		const tipY = cy + radius * Math.cos(rad);

		const line = new Feature(
			new LineString([
				[cx, cy],
				[tipX, tipY]
			])
		);
		line.set('kind', 'radial');
		feats.push(line);

		if (opts.labels ?? true) {
			const label = new Feature(new Point([tipX, tipY]));
			label.set('kind', 'radial-label');
			label.set('text', `${az}°`);
			feats.push(label);
		}
	}
	return feats;
}

export function radialStyle(feature: FeatureLike): Style {
	const kind = feature.get('kind');
	if (kind === 'radial-label') {
		return new Style({
			text: new Text({
				text: feature.get('text'),
				font: '10px sans-serif',
				fill: new Fill({ color: 'rgba(255,255,255,0.7)' }),
				stroke: new Stroke({ color: 'rgba(0,0,0,0.7)', width: 2 })
			})
		});
	}
	return new Style({
		stroke: new Stroke({ color: 'rgba(255,255,255,0.2)', width: 1, lineDash: [2, 4] })
	});
}
