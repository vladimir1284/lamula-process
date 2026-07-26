import { describe, it, expect } from 'vitest';
import GeoJSON from 'ol/format/GeoJSON';
import { fromLonLat } from 'ol/proj';
import Feature from 'ol/Feature';
import Point from 'ol/geom/Point';
import { standardOverlays, geoJsonLayer, coastStyle } from './geoLayer';

describe('standardOverlays', () => {
	it('returns the named overlay layers', () => {
		const layers = standardOverlays();
		expect(layers.map((l) => l.get('name'))).toEqual(['rivers', 'borders']);
	});
});

describe('geoJsonLayer', () => {
	it('carries inline features into the layer source', () => {
		const feats = [new Feature(new Point(fromLonLat([-77.85, 21.42])))];
		const layer = geoJsonLayer({ name: 'x', style: coastStyle, features: feats });
		expect(layer.getSource()!.getFeatures()).toHaveLength(1);
		expect(layer.get('name')).toBe('x');
	});

	it('reprojects lon/lat GeoJSON to EPSG:3857 as configured', () => {
		// mirrors the format config geoJsonLayer builds for URL sources
		const format = new GeoJSON({ dataProjection: 'EPSG:4326', featureProjection: 'EPSG:3857' });
		const feats = format.readFeatures({
			type: 'FeatureCollection',
			features: [
				{
					type: 'Feature',
					properties: {},
					geometry: { type: 'Point', coordinates: [-77.85, 21.42] }
				}
			]
		});
		const geom = feats[0].getGeometry() as Point;
		const [x, y] = geom.getCoordinates();
		const [ex, ey] = fromLonLat([-77.85, 21.42]);
		expect(x).toBeCloseTo(ex, 3);
		expect(y).toBeCloseTo(ey, 3);
	});
});
