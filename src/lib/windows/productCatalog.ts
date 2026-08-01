import type { GroundProductKind } from '$lib/pipeline';
import type { MomentType } from '$lib/domain/types';
import type { BaseMapId } from '$lib/viewer/baseMaps';
import type {
	CrossSectionWindowPayload,
	MapWindowPayload,
	ProfileWindowPayload,
	RhiWindowPayload
} from './windowTypes';

/** Every catalog entry the sidebar can launch a window for. Ground kinds open a `map` window
 * directly; the "Cortes" group opens a derived-chart window sourced from the currently-focused
 * map window (see `windowStore`/`+page.svelte`). */
export type CatalogProductKind = GroundProductKind | 'CROSS_LINE' | 'PROFILE' | 'RHI';

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
		label: 'Base',
		items: [
			{ id: 'PPI', label: 'PPI', icon: 'storm' },
			{ id: 'CAPPI', label: 'CAPPI', icon: 'layers' }
		]
	},
	{
		label: 'Columna',
		items: [
			{ id: 'TOPS', label: 'Topes (echo tops)', icon: 'cloud_upload' },
			{ id: 'MAXS_HEIGHT', label: 'Altura del máximo', icon: 'height' },
			{ id: 'COLUMN_MAX', label: 'Máximo de columna', icon: 'stacked_line_chart' },
			{ id: 'VIL', label: 'VIL', icon: 'opacity' }
		]
	},
	{
		label: 'Precip. y viento',
		items: [
			{ id: 'RAIN', label: 'Tasa de lluvia (Z-R)', icon: 'rainy' },
			{ id: 'WIND_SPEED', label: 'Viento (VAD)', icon: 'air' }
		]
	},
	{
		label: 'Cortes',
		items: [
			{ id: 'CROSS_LINE', label: 'Corte (línea libre)', icon: 'timeline' },
			{ id: 'PROFILE', label: 'Perfil vertical', icon: 'monitoring' },
			{ id: 'RHI', label: 'RHI', icon: 'radar' }
		]
	}
];

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
	appDefaults: { baseMap: BaseMapId; showRings: boolean; showRadials: boolean }
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
		zrA: 300,
		zrB: 1.4,
		baseMap: appDefaults.baseMap,
		dataOpacity: 0.8,
		showRings: appDefaults.showRings,
		showRadials: appDefaults.showRadials
	};
}

export function defaultRhiPayload(sourceMapWindowId: string): RhiWindowPayload {
	return { sourceMapWindowId, maxHeightKm: 18, azimuthDeg: 0 };
}

export function defaultCrossSectionPayload(sourceMapWindowId: string): CrossSectionWindowPayload {
	return { sourceMapWindowId, maxHeightKm: 18, line: null };
}

export function defaultProfilePayload(sourceMapWindowId: string): ProfileWindowPayload {
	return { sourceMapWindowId, maxHeightKm: 18, point: null };
}
