import type { GroundProductKind } from '$lib/pipeline';
import type { MomentType } from '$lib/domain/types';
import type { BaseMapId } from '$lib/viewer/baseMaps';
import type {
	CrossSectionWindowPayload,
	MapWindowPayload,
	ProfileWindowPayload,
	RhiWindowPayload,
	StatsWindowPayload
} from './windowTypes';

/** Every catalog entry the sidebar can launch a window for. Ground kinds open a `map` window
 * directly; the "Cortes" group opens a derived-chart window sourced from the currently-focused
 * map window (see `windowStore`/`+page.svelte`). */
export type CatalogProductKind = GroundProductKind | 'CROSS_LINE' | 'PROFILE' | 'RHI' | 'STATS';

export const GROUND_KINDS: GroundProductKind[] = [
	'PPI',
	'CAPPI',
	'TOPS',
	'MAXS_HEIGHT',
	'COLUMN_MAX',
	'VIL',
	'RAIN',
	'WIND_SPEED'
];

/** `label` is an i18n key (see src/lib/i18n/locales/*.json `catalog.*`), not display text --
 * translate it with `$_(label)` at render time. */
export interface CatalogItem {
	id: CatalogProductKind;
	label: string;
	icon: string;
}

export interface CatalogGroup {
	label: string;
	items: CatalogItem[];
}

// Sidebar catalog -- mirrors the optgroups the app has always exposed.
export const PRODUCT_GROUPS: CatalogGroup[] = [
	{
		label: 'catalog.groups.base',
		items: [
			{ id: 'PPI', label: 'catalog.items.ppi', icon: 'storm' },
			{ id: 'CAPPI', label: 'catalog.items.cappi', icon: 'layers' }
		]
	},
	{
		label: 'catalog.groups.column',
		items: [
			{ id: 'TOPS', label: 'catalog.items.tops', icon: 'cloud_upload' },
			{ id: 'MAXS_HEIGHT', label: 'catalog.items.maxsHeight', icon: 'height' },
			{ id: 'COLUMN_MAX', label: 'catalog.items.columnMax', icon: 'stacked_line_chart' },
			{ id: 'VIL', label: 'catalog.items.vil', icon: 'opacity' }
		]
	},
	{
		label: 'catalog.groups.precipWind',
		items: [
			{ id: 'RAIN', label: 'catalog.items.rain', icon: 'rainy' },
			{ id: 'WIND_SPEED', label: 'catalog.items.windSpeed', icon: 'air' }
		]
	},
	{
		label: 'catalog.groups.crossSections',
		items: [
			{ id: 'CROSS_LINE', label: 'catalog.items.crossLine', icon: 'timeline' },
			{ id: 'PROFILE', label: 'catalog.items.profile', icon: 'monitoring' },
			{ id: 'RHI', label: 'catalog.items.rhi', icon: 'radar' },
			{ id: 'STATS', label: 'catalog.items.stats', icon: 'query_stats' }
		]
	}
];

/** Returns the i18n key for a catalog item's label -- translate with `$_()` at render time. */
export function catalogLabel(id: CatalogProductKind): string {
	return PRODUCT_GROUPS.flatMap((g) => g.items).find((i) => i.id === id)?.label ?? id;
}

export function isGroundKind(id: CatalogProductKind): id is GroundProductKind {
	return (GROUND_KINDS as string[]).includes(id);
}

/** Which palette-book key a ground product's scan is colored with: products that report a
 * different physical quantity than the channel's moment (echo tops/column-max height, VIL, rain
 * rate, wind speed) get their own key; everything else (PPI/CAPPI/COLUMN_MAX) follows the moment. */
export function paletteKeyForGroundProduct(p: GroundProductKind, moment: MomentType): string {
	switch (p) {
		case 'TOPS':
		case 'MAXS_HEIGHT':
			return 'TOPS_HEIGHT';
		case 'VIL':
			return 'VIL';
		case 'RAIN':
			return 'RAIN';
		case 'WIND_SPEED':
			return 'WIND_SPEED';
		default:
			return moment;
	}
}

export function defaultMapPayload(
	product: GroundProductKind,
	appDefaults: {
		baseMap: BaseMapId;
		showRings: boolean;
		showRadials: boolean;
		showScale: boolean;
		showSiteMarker: boolean;
		showCutGuide: boolean;
		zrA: number;
		zrB: number;
	}
): MapWindowPayload {
	return {
		product,
		channelIndex: 0,
		elevationDeg: 0.5,
		cappiBottomKm: 1,
		cappiTopKm: 3,
		topsMinDbz: 18,
		vilBottomKm: 0,
		vilTopKm: 15,
		vilC1: 0.00524,
		vilC2: 0.57143,
		zrA: appDefaults.zrA,
		zrB: appDefaults.zrB,
		baseMap: appDefaults.baseMap,
		dataOpacity: 0.8,
		showRings: appDefaults.showRings,
		showRadials: appDefaults.showRadials,
		showScale: appDefaults.showScale,
		showSiteMarker: appDefaults.showSiteMarker,
		showCutGuide: appDefaults.showCutGuide
	};
}

export function defaultRhiPayload(sourceMapWindowId: string, smooth: boolean): RhiWindowPayload {
	return { sourceMapWindowId, maxHeightKm: 18, azimuthDeg: 0, smooth };
}

export function defaultCrossSectionPayload(
	sourceMapWindowId: string,
	smooth: boolean
): CrossSectionWindowPayload {
	return { sourceMapWindowId, maxHeightKm: 18, line: null, smooth };
}

export function defaultProfilePayload(sourceMapWindowId: string): ProfileWindowPayload {
	return { sourceMapWindowId, maxHeightKm: 18, point: null };
}

export function defaultStatsPayload(sourceMapWindowId: string): StatsWindowPayload {
	return { sourceMapWindowId, region: null, threshold: 0 };
}
