// Catálogo de mapas base para el visor PPI. Portado de lamula-webviewer
// (shared/basemaps.ts + utils/map/base-layers.ts): OSM trae los nombres
// horneados; las variantes CARTO son un par *_nolabels (base) + *_only_labels
// (capa de nombres, va por encima del radar para quedar legible).
//
// 'off' NO es un mapa: apaga base y labels (sólo el radar sobre negro).
import OSM from 'ol/source/OSM';
import XYZ from 'ol/source/XYZ';
import type TileSource from 'ol/source/Tile';

export const BASE_MAP_IDS = ['osm', 'carto-voyager', 'carto-positron', 'carto-dark'] as const;

export type BaseMapId = (typeof BASE_MAP_IDS)[number] | 'off';

export const BASE_MAP_LABELS: Record<BaseMapId, string> = {
	'off': 'Sin mapa',
	'osm': 'OSM',
	'carto-voyager': 'CARTO Voyager',
	'carto-positron': 'CARTO Claro',
	'carto-dark': 'CARTO Oscuro'
};

export function isBaseMapId(v: unknown): v is BaseMapId {
	return v === 'off' || (BASE_MAP_IDS as readonly string[]).includes(v as string);
}

const CARTO_ATTRIBUTION =
	'&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>';

// estilos raster de basemaps.cartocdn.com — voyager cuelga de rastertiles/,
// positron/dark usan los nombres light_/dark_ del CDN
const CARTO_STYLES: Record<string, { base: string; labels: string }> = {
	'carto-voyager': { base: 'rastertiles/voyager_nolabels', labels: 'rastertiles/voyager_only_labels' },
	'carto-positron': { base: 'light_nolabels', labels: 'light_only_labels' },
	'carto-dark': { base: 'dark_nolabels', labels: 'dark_only_labels' }
};

function cartoSource(style: string): XYZ {
	// OL no expande el token {r} de CARTO — resolver @2x aquí una vez
	const retina = typeof devicePixelRatio !== 'undefined' && devicePixelRatio > 1;
	return new XYZ({
		url: `https://{a-d}.basemaps.cartocdn.com/${style}/{z}/{x}/{y}${retina ? '@2x' : ''}.png`,
		tilePixelRatio: retina ? 2 : 1,
		attributions: CARTO_ATTRIBUTION
	});
}

export interface BaseMapSources {
	base: TileSource | null;
	/** null = sin capa de labels (OSM los trae horneados, 'off' apaga todo) */
	labels: TileSource | null;
}

export function createBaseMapSources(id: BaseMapId): BaseMapSources {
	if (id === 'off') return { base: null, labels: null };
	if (id === 'osm') return { base: new OSM(), labels: null };
	const style = CARTO_STYLES[id]!;
	return { base: cartoSource(style.base), labels: cartoSource(style.labels) };
}
