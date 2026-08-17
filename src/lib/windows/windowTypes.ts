import type { GroundProductKind } from '$lib/pipeline';
import type { CutLine } from '$lib/products';
import type { BaseMapId } from '$lib/viewer/baseMaps';
import type { RectangleRegion } from '$lib/analysis';

/** Map windows show a georeferenced ground product; `accumulate` is also a georeferenced ground
 * map but sourced from a `TimeSpan` (multiple observations) instead of the page's single current
 * Observation; the remaining four are derived-chart windows, each sourced from exactly one map
 * window (see `ChartWindowPayloadBase.sourceMapWindowId`). */
export type WindowType =
	'map' | 'accumulate' | 'rhi' | 'cross-section' | 'profile' | 'stats' | 'observation-info';

export interface WindowRect {
	x: number;
	y: number;
	width: number;
	height: number;
}

/** Everything a map window needs to render its own product/channel/elevation/overlays,
 * independent of any other map window open at the same time. */
export interface MapWindowPayload {
	/** Which resident observation (observationMachine's `observations` list) this window shows --
	 * set once at creation from whichever was active then, never reassigned. Lets several map
	 * windows each stay pinned to a different observation instead of all following the single
	 * "active" one (see `+page.svelte`'s per-window `observationById`/`channelsFor` resolution). */
	observationId: string;
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
	showLatLonGrid: boolean;
	/** Docked N-S/E-W vertical-section strips (height x distance, real data) around the map --
	 * see `crossSection.ts`'s `eastWestLine`/`northSouthLine`, rendered via `CrossSectionPanel`. */
	showCutPanels: boolean;
	/** North-south position (km, +north/-south of the site) of the docked E-W cut -- named after
	 * the coordinate's own axis, not which panel it feeds. Draggable on the map (a horizontal
	 * guide line) or via the toolbar's "N-S" input. Default 0 (through the site). */
	nsPositionKm: number;
	/** East-west position (km, +east/-west of the site) of the docked N-S cut. Draggable on the
	 * map (a vertical guide line) or via the toolbar's "E-W" input. Default 0 (through the site). */
	ewPositionKm: number;
	/** Render the docked E-W/N-S cuts as a legacy-style MAX projection (collapses the full
	 * perpendicular window by max value) instead of the true vertical-plane slice at
	 * `nsPositionKm`/`ewPositionKm`. Since the result no longer depends on that offset, the two
	 * position guide lines on the map are hidden while this is on. Default false. */
	cutMaxProjection: boolean;
}

/** The accumulate window has one fixed algorithm (no product switch, no CAPPI/TOPS/VIL fields) --
 * it always runs `computeAccumulate` over the loaded `TimeSpan`'s matching-moment channel. */
export interface AccumulateWindowPayload {
	channelIndex: number;
	bottomKm: number;
	topKm: number;
	intervalMin: number;
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

/** No per-window state -- the observation-info window reads the resident observation list and
 * active id live from `observationMachine`'s context (passed down as props), same as `StatsWindow`
 * reads its source map window live from `windowStore` instead of snapshotting it into payload. */
export type ObservationInfoWindowPayload = Record<string, never>;

export type WindowPayload =
	| MapWindowPayload
	| AccumulateWindowPayload
	| RhiWindowPayload
	| CrossSectionWindowPayload
	| ProfileWindowPayload
	| StatsWindowPayload
	| ObservationInfoWindowPayload;

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
	accumulate: 'water_drop',
	rhi: 'radar',
	'cross-section': 'timeline',
	profile: 'monitoring',
	stats: 'query_stats',
	'observation-info': 'info'
};
