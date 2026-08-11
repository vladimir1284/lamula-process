import Feature from 'ol/Feature';
import type { FeatureLike } from 'ol/Feature';
import LineString from 'ol/geom/LineString';
import Point from 'ol/geom/Point';
import { Style, Stroke, Text, Fill } from 'ol/style';
import { fromLonLat } from 'ol/proj';
import { overlayRgba, overlayOutline, type OverlayBaseColor } from './overlayLineStyle';

/**
 * Lat/lon graticule for the PPI overlay, same family as rings.ts/radials.ts. In Web Mercator
 * (EPSG:3857) a meridian (constant lon) projects to an exactly vertical line and a parallel
 * (constant lat) to an exactly horizontal one -- x depends only on lon, y only on lat -- so each
 * line only needs its two endpoints, no interpolated segments.
 */

const METERS_PER_DEG_LAT = 111_320;
/** Floor for user-configured steps -- guards the ceil/+=step loops below from spinning forever
 * on a zero/negative setting. */
const MIN_STEP_DEG = 0.01;

export interface LatLonGridOptions {
	centerLon: number;
	centerLat: number;
	/** Ground metres from site to the extent edge (same value rings/radials use). */
	maxRangeM: number;
	/** Spacing between parallels, degrees latitude. */
	stepLatDeg: number;
	/** Spacing between meridians, degrees longitude. */
	stepLonDeg: number;
	/** Label each line with its coordinate. Default true. */
	labels?: boolean;
}

export function latLonGridFeatures(opts: LatLonGridOptions): Feature[] {
	const { centerLon, centerLat, maxRangeM } = opts;
	const labels = opts.labels ?? true;
	const stepLat = Math.max(MIN_STEP_DEG, opts.stepLatDeg);
	const stepLon = Math.max(MIN_STEP_DEG, opts.stepLonDeg);
	const latSpanDeg = (maxRangeM / METERS_PER_DEG_LAT) * 2;
	const lonSpanDeg = (maxRangeM / (METERS_PER_DEG_LAT * Math.cos((centerLat * Math.PI) / 180))) * 2;

	const minLat = centerLat - latSpanDeg / 2;
	const maxLat = centerLat + latSpanDeg / 2;
	const minLon = centerLon - lonSpanDeg / 2;
	const maxLon = centerLon + lonSpanDeg / 2;

	const feats: Feature[] = [];

	for (let lat = Math.ceil(minLat / stepLat) * stepLat; lat <= maxLat; lat += stepLat) {
		const p0 = fromLonLat([minLon, lat]) as [number, number];
		const p1 = fromLonLat([maxLon, lat]) as [number, number];
		const line = new Feature(new LineString([p0, p1]));
		line.set('kind', 'grid');
		feats.push(line);
		if (labels) {
			const label = new Feature(new Point(p1));
			label.set('kind', 'grid-label');
			label.set('text', `${lat.toFixed(2)}°`);
			feats.push(label);
		}
	}

	for (let lon = Math.ceil(minLon / stepLon) * stepLon; lon <= maxLon; lon += stepLon) {
		const p0 = fromLonLat([lon, minLat]) as [number, number];
		const p1 = fromLonLat([lon, maxLat]) as [number, number];
		const line = new Feature(new LineString([p0, p1]));
		line.set('kind', 'grid');
		feats.push(line);
		if (labels) {
			const label = new Feature(new Point(p1));
			label.set('kind', 'grid-label');
			label.set('text', `${lon.toFixed(2)}°`);
			feats.push(label);
		}
	}

	return feats;
}

/** Style factory so color/width follow the shared overlay-line settings (group config covering
 * rings/radials/grid) instead of a fixed white. */
export function makeLatLonGridStyle(
	base: OverlayBaseColor,
	widthPx: number
): (feature: FeatureLike) => Style {
	const outline = overlayOutline(base);
	return (feature) => {
		const kind = feature.get('kind');
		if (kind === 'grid-label') {
			return new Style({
				text: new Text({
					text: feature.get('text'),
					font: '10px sans-serif',
					fill: new Fill({ color: overlayRgba(base, 0.6) }),
					stroke: new Stroke({ color: overlayRgba(outline, 0.7), width: 2 })
				})
			});
		}
		return new Style({
			stroke: new Stroke({ color: overlayRgba(base, 0.15), width: widthPx, lineDash: [1, 3] })
		});
	};
}
