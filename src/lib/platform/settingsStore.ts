import { isTauri } from '@tauri-apps/api/core';
import type { UnitSystem } from '$lib/units';
import type { BaseMapId } from '$lib/viewer/baseMaps';

/**
 * App-wide user preferences, persisted in the browser. Same web-only localStorage pattern as
 * config.ts / siteData.ts / paletteStore.ts -- see config.ts for the Tauri caveat.
 */

export interface AppSettings {
	unitSystem: UnitSystem;
	baseMap: BaseMapId;
	showRings: boolean;
	showRadials: boolean;
	/** Z-R rain-rate coefficients (R = (Z/A)^(1/B)), seed newly-opened RAIN windows' own editable
	 * a/b fields -- see legacy/Units/Configuration.pas `Rain_A`/`Rain_B`. */
	zrA: number;
	zrB: number;
	/** Seeds newly-opened map windows' scale-legend visibility. */
	showScale: boolean;
	/** Seeds newly-opened map windows' radar site marker visibility. */
	showSiteMarker: boolean;
	/** Seeds newly-opened RHI/cross-section windows' raster interpolation (Pixi `scaleMode`). */
	imageSmoothing: boolean;
	/** Radial-speckle despeckle filter run length, in metres (see `pipeline/applySpeckleFilter.ts`).
	 * 0 disables the filter -- same "0 = off" convention as legacy's `Radial_Speckle`. */
	speckleDistanceM: number;
}

export const DEFAULT_SETTINGS: AppSettings = {
	unitSystem: 'metric',
	baseMap: 'carto-dark',
	showRings: true,
	showRadials: false,
	zrA: 300,
	zrB: 1.4,
	showScale: true,
	showSiteMarker: true,
	imageSmoothing: false,
	speckleDistanceM: 0
};
const STORAGE_KEY = 'lamula-process:settings';

function isUnitSystem(x: unknown): x is UnitSystem {
	return x === 'metric' || x === 'imperial';
}

export async function loadSettings(): Promise<AppSettings> {
	if (isTauri()) throw new Error('Tauri settings store not implemented yet');
	const raw = localStorage.getItem(STORAGE_KEY);
	if (!raw) return { ...DEFAULT_SETTINGS };
	try {
		const parsed = JSON.parse(raw);
		return {
			unitSystem: isUnitSystem(parsed.unitSystem) ? parsed.unitSystem : DEFAULT_SETTINGS.unitSystem,
			baseMap: typeof parsed.baseMap === 'string' ? parsed.baseMap : DEFAULT_SETTINGS.baseMap,
			showRings:
				typeof parsed.showRings === 'boolean' ? parsed.showRings : DEFAULT_SETTINGS.showRings,
			showRadials:
				typeof parsed.showRadials === 'boolean' ? parsed.showRadials : DEFAULT_SETTINGS.showRadials,
			zrA: typeof parsed.zrA === 'number' ? parsed.zrA : DEFAULT_SETTINGS.zrA,
			zrB: typeof parsed.zrB === 'number' ? parsed.zrB : DEFAULT_SETTINGS.zrB,
			showScale:
				typeof parsed.showScale === 'boolean' ? parsed.showScale : DEFAULT_SETTINGS.showScale,
			showSiteMarker:
				typeof parsed.showSiteMarker === 'boolean'
					? parsed.showSiteMarker
					: DEFAULT_SETTINGS.showSiteMarker,
			imageSmoothing:
				typeof parsed.imageSmoothing === 'boolean'
					? parsed.imageSmoothing
					: DEFAULT_SETTINGS.imageSmoothing,
			speckleDistanceM:
				typeof parsed.speckleDistanceM === 'number'
					? parsed.speckleDistanceM
					: DEFAULT_SETTINGS.speckleDistanceM
		};
	} catch {
		return { ...DEFAULT_SETTINGS };
	}
}

export async function saveSettings(settings: AppSettings): Promise<void> {
	if (isTauri()) throw new Error('Tauri settings store not implemented yet');
	localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
}
