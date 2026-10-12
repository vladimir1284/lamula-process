import { describe, it, expect } from 'vitest';
import XYZ from 'ol/source/XYZ';
import { createBaseMapSources } from './baseMaps';

describe('createBaseMapSources', () => {
	it('returns null base and labels for "off"', () => {
		const sources = createBaseMapSources('off');
		expect(sources.base).toBeNull();
		expect(sources.labels).toBeNull();
	});

	it('returns OSM source for "osm"', () => {
		const sources = createBaseMapSources('osm');
		expect(sources.base).not.toBeNull();
		expect(sources.labels).toBeNull();
	});

	it('includes api_key in CARTO tile URLs', () => {
		for (const cartoId of ['carto-voyager', 'carto-positron', 'carto-dark'] as const) {
			const sources = createBaseMapSources(cartoId);
			expect(sources.base).toBeInstanceOf(XYZ);
			expect(sources.labels).toBeInstanceOf(XYZ);

			const baseUrl = (sources.base as XYZ).getUrls()?.[0] ?? '';
			const labelsUrl = (sources.labels as XYZ).getUrls()?.[0] ?? '';

			expect(baseUrl).toContain('api_key=cb1_4iib_1_1dfa4e98cff8bebc4902181e');
			expect(labelsUrl).toContain('api_key=cb1_4iib_1_1dfa4e98cff8bebc4902181e');
		}
	});
});
