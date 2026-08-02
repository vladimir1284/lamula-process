import type { GroundProductKind } from '$lib/pipeline';
import type { CutLine } from '$lib/products';
import type { BaseMapId } from '$lib/viewer/baseMaps';
import type { RectangleRegion } from '$lib/analysis';

/** Map windows show a georeferenced ground product; the other four are derived-chart windows,
 * each sourced from exactly one map window (see `ChartWindowPayloadBase.sourceMapWindowId`). */
export type WindowType = 'map' | 'rhi' | 'cross-section' | 'profile' | 'stats';

export interface WindowRect {
	x: number;
	y: number;
	width: number;
	height: number;
}

/** Everything a map window needs to render its own product/channel/elevation/overlays,
 * independent of any other map window open at the same time. */
export interface MapWindowPayload {
	product: GroundProductKind;
	channelIndex: number;
	elevationDeg: number;
	cappiBottomKm: number;
	cappiTopKm: number;
	topsMinDbz: number;
	vilBottomKm: number;
	vilTopKm: number;
	vilC1: number;
	vilC2: number;
	zrA: number;
	zrB: number;
	baseMap: BaseMapId;
	dataOpacity: number;
	showRings: boolean;
	showRadials: boolean;
	showScale: boolean;
	showSiteMarker: boolean;
	showCutGuide: boolean;
}

export interface ChartWindowPayloadBase {
	/** The map window this chart was generated from. Set once at creation, never reassigned. */
	sourceMapWindowId: string;
}

export interface RhiWindowPayload extends ChartWindowPayloadBase {
	maxHeightKm: number;
	azimuthDeg: number;
	/** Raster interpolation for the Pixi heatmap (`scaleMode`): false = nearest (blocky, exact
	 * cell boundaries), true = linear (smoothed). */
	smooth: boolean;
}

export interface CrossSectionWindowPayload extends ChartWindowPayloadBase {
	maxHeightKm: number;
	line: CutLine | null;
	/** Raster interpolation for the Pixi heatmap (`scaleMode`): false = nearest (blocky, exact
	 * cell boundaries), true = linear (smoothed). */
	smooth: boolean;
}

export interface ProfileWindowPayload extends ChartWindowPayloadBase {
	maxHeightKm: number;
	point: { xEastM: number; yNorthM: number } | null;
}

export interface StatsWindowPayload extends ChartWindowPayloadBase {
	region: RectangleRegion | null;
	/** Cells with value strictly greater than this count toward coverage (see `computeStatistics`). */
	threshold: number;
}

export type WindowPayload =
	| MapWindowPayload
	| RhiWindowPayload
	| CrossSectionWindowPayload
	| ProfileWindowPayload
	| StatsWindowPayload;

export interface RadarWindow {
	id: string;
	type: WindowType;
	title: string;
	rect: WindowRect;
	z: number;
	minimized: boolean;
	maximized: boolean;
	/** Snapshot to return to on un-minimize/un-maximize. */
	restoreRect: WindowRect | null;
	payload: WindowPayload;
}

export function isChartWindow(
	w: RadarWindow
): w is RadarWindow & { payload: ChartWindowPayloadBase } {
	return (
		w.type === 'rhi' || w.type === 'cross-section' || w.type === 'profile' || w.type === 'stats'
	);
}

export const MIN_WINDOW_WIDTH = 320;
export const MIN_WINDOW_HEIGHT = 240;

export const WINDOW_TYPE_ICON: Record<WindowType, string> = {
	map: 'my_location',
	rhi: 'radar',
	'cross-section': 'timeline',
	profile: 'monitoring',
	stats: 'query_stats'
};
