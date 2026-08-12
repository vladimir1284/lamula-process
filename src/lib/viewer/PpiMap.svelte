<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import Map from 'ol/Map';
	import View from 'ol/View';
	import ImageLayer from 'ol/layer/Image';
	import TileLayer from 'ol/layer/Tile';
	import Static from 'ol/source/ImageStatic';
	import VectorLayer from 'ol/layer/Vector';
	import VectorSource from 'ol/source/Vector';
	import Draw, { createBox } from 'ol/interaction/Draw';
	import Modify from 'ol/interaction/Modify';
	import PointerInteraction from 'ol/interaction/Pointer';
	import LineString from 'ol/geom/LineString';
	import Feature from 'ol/Feature';
	import Point from 'ol/geom/Point';
	import { Style, Stroke, Circle as CircleStyle, Fill, Text } from 'ol/style';
	import type BaseLayer from 'ol/layer/Base';
	import 'ol/ol.css';

	import { createBaseMapSources, isDarkBaseMap, type BaseMapId } from './baseMaps';

	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import type { CutLine } from '$lib/products/crossSection';
	import type { OverlayLineColor } from '$lib/platform/settingsStore';
	import { PpiRenderer } from '$lib/render/renderClient';
	import { buildAzimuthLUT, maxGroundRangeM } from '$lib/render/scanSample';
	import { siteExtent3857, siteCenter3857, mercatorScaleAtLat } from '$lib/geo/extent';
	import { rasterToDataURL } from './radarImage';
	import { ringFeatures, makeRingStyle, defaultRingsM } from './rings';
	import { radialFeatures, makeRadialStyle } from './radials';
	import { latLonGridFeatures, makeLatLonGridStyle } from './latLonGrid';
	import type { OverlayBaseColor } from './overlayLineStyle';
	import { siteMarkerFeature, siteMarkerStyle } from './siteMarker';
	import { readoutAt, type Readout } from './readout';
	import type { UnitSystem } from '$lib/units';

	interface Props {
		scan: Scan;
		palette: Palette;
		/** Radar site position; required to georeference. */
		site: { lon: number; lat: number };
		/** Output raster resolution in px (square). Default 1024. */
		sizePx?: number;
		/** Extra OpenLayers layers (e.g. geo overlays) drawn above the radar image. */
		extraLayers?: BaseLayer[];
		/** Background map from the catalog (baseMaps.ts); 'off' = radar over black. */
		baseMap?: BaseMapId;
		/** Radar image opacity 0..1. Default 1 (opaque). */
		dataOpacity?: number;
		/** Called on every pointer move with the current readout. */
		onreadout?: (r: Readout | null) => void;
		/** When true, a two-point line-draw interaction is active on the map. */
		drawEnabled?: boolean;
		/** Called with the drawn line converted to site-relative ground metres. */
		onCutLine?: (line: CutLine) => void;
		/** A preset line (e.g. E-W/N-S full-range shortcut) to render in place of a hand-drawn one. */
		presetLine?: CutLine | null;
		/** When true, a single-point pick interaction is active on the map. */
		pointSelectEnabled?: boolean;
		/** Called with the picked point converted to site-relative ground metres. */
		onPointSelect?: (point: { xEastM: number; yNorthM: number }) => void;
		/** When true, a click-to-pick-azimuth interaction is active on the map. */
		azimuthSelectEnabled?: boolean;
		/** Current RHI cut azimuth (deg from north, clockwise); drawn as a radial from the site. */
		azimuthDeg?: number | null;
		/** Called with the picked azimuth (deg from north, clockwise). */
		onAzimuthSelect?: (azDeg: number) => void;
		/** When true, a click-drag rectangle-draw interaction is active on the map (stats region). */
		statsSelectEnabled?: boolean;
		/** Called with the drawn rectangle converted to site-relative ground metres. */
		onStatsRegionSelect?: (r: {
			minXM: number;
			minYM: number;
			maxXM: number;
			maxYM: number;
		}) => void;
		/** North-south position (site-relative metres) of the docked E-W cut's guide line -- a
		 * horizontal line drawn across the map, always on regardless of `drawEnabled`/etc. `null`
		 * hides it (matches `azimuthDeg`'s null-hides convention). Draggable: dropping it near the
		 * line and dragging vertically calls `onNsPositionChange`. */
		nsPositionM?: number | null;
		/** East-west position (site-relative metres) of the docked N-S cut's guide line (vertical). */
		ewPositionM?: number | null;
		/** Called with the new north-south position (metres) while dragging the E-W guide line. */
		onNsPositionChange?: (m: number) => void;
		/** Called with the new east-west position (metres) while dragging the N-S guide line. */
		onEwPositionChange?: (m: number) => void;
		/** Called with the current viewport (ground scale + centre, both site-relative) whenever the
		 * view's pan/zoom settles, and once immediately after the initial/re-fit. Lets a caller size
		 * a docked panel's span to match what's visible, and re-centre its cut on wherever the map
		 * itself is currently looking (panning moves the map's centre -> this fires -> the caller
		 * recomputes the cut's absolute position as centre + its own drag-set offset, so panning
		 * carries the cut along while the offset the user dragged in stays put, relative to centre). */
		onViewChange?: (v: { groundMPerPx: number; centerEastM: number; centerNorthM: number }) => void;
		/** Unit system for range-ring labels. Default metric (km). */
		unitSystem?: UnitSystem;
		/** Show distance-from-radar range rings. Default true. */
		showRings?: boolean;
		/** Show azimuth radial marks. Default true. */
		showRadials?: boolean;
		/** Show the radar site position marker. Default true. */
		showSiteMarker?: boolean;
		/** Show the cross-section/RHI cut guide (trace line, A/B endpoints, azimuth radial) drawn on
		 * `drawLayer`. Independent of `drawEnabled`/`azimuthSelectEnabled`/`pointSelectEnabled` --
		 * the pick interaction stays armed and still fires its callback even while this is false, it
		 * just hides what's drawn. Default true. */
		showCutGuide?: boolean;
		/** Show the lat/lon graticule. Default false. */
		showLatLonGrid?: boolean;
		/** Shared line color for rings/radials/grid. 'auto' picks white on a dark base map, black
		 * otherwise (see `baseMaps.ts`'s `isDarkBaseMap`). Default 'auto'. */
		overlayLineColor?: OverlayLineColor;
		/** Shared line width (px) for rings/radials/grid. Default 1. */
		overlayLineWidthPx?: number;
		/** Spacing between range rings, km. Default 50. */
		ringsStepKm?: number;
		/** Spacing between azimuth radials, degrees. Default 30. */
		radialsStepDeg?: number;
		/** Lat/lon grid spacing, degrees. Default 1/1. */
		gridStepLatDeg?: number;
		gridStepLonDeg?: number;
	}

	let {
		scan,
		palette,
		site,
		sizePx = 1024,
		extraLayers = [],
		baseMap = 'off',
		dataOpacity = 1,
		onreadout,
		drawEnabled = false,
		onCutLine,
		presetLine = null,
		pointSelectEnabled = false,
		onPointSelect,
		azimuthSelectEnabled = false,
		azimuthDeg = null,
		onAzimuthSelect,
		statsSelectEnabled = false,
		onStatsRegionSelect,
		nsPositionM = null,
		ewPositionM = null,
		onNsPositionChange,
		onEwPositionChange,
		onViewChange,
		unitSystem = 'metric',
		showRings = true,
		showRadials = false,
		showSiteMarker = true,
		showCutGuide = true,
		showLatLonGrid = false,
		overlayLineColor = 'auto',
		overlayLineWidthPx = 1,
		ringsStepKm = 50,
		radialsStepDeg = 30,
		gridStepLatDeg = 1,
		gridStepLonDeg = 1
	}: Props = $props();

	const effectiveOverlayColor: OverlayBaseColor = $derived(
		overlayLineColor === 'auto' ? (isDarkBaseMap(baseMap) ? 'white' : 'black') : overlayLineColor
	);

	let mapEl: HTMLDivElement;
	let map: Map | undefined;
	let baseLayer: TileLayer | undefined;
	let labelsLayer: TileLayer | undefined;
	let radarLayer: ImageLayer<Static> | undefined;
	let ringsLayer: VectorLayer<VectorSource> | undefined;
	let radialsLayer: VectorLayer<VectorSource> | undefined;
	let gridLayer: VectorLayer<VectorSource> | undefined;
	let siteLayer: VectorLayer<VectorSource> | undefined;
	let drawLayer: VectorLayer<VectorSource> | undefined;
	let guideLayer: VectorLayer<VectorSource> | undefined;
	// Which axis-line the pointer is currently dragging, if any -- set in handleDownEvent, read by
	// handleDragEvent/handleUpEvent. Not Svelte state: it's read-and-written only from inside the
	// interaction's own handlers, never from a template or effect.
	let draggingGuideAxis: 'ns' | 'ew' | null = null;
	let draw: Draw | undefined;
	let cutModify: Modify | undefined;
	let pointDraw: Draw | undefined;
	let azimuthDraw: Draw | undefined;
	let statsDraw: Draw | undefined;
	let extraGroup: BaseLayer[] = [];
	const renderer = new PpiRenderer();
	let renderToken = 0;

	// Endpoint colors match CrossSectionPanel's A/B markers so the same cut reads consistently
	// across the map and the vertical-section canvas.
	const CUT_START_COLOR = '#22c55e';
	const CUT_END_COLOR = '#ef4444';

	const drawStyle = new Style({
		stroke: new Stroke({ color: '#00f0ff', width: 2 })
	});

	const pointStyle = new Style({
		image: new CircleStyle({
			radius: 7,
			fill: new Fill({ color: '#00f0ff' }),
			stroke: new Stroke({ color: '#0b0f14', width: 2 })
		})
	});

	// Matches RhiAzimuthPicker's old dial-line color, kept for visual continuity.
	const azimuthLineStyle = new Style({
		stroke: new Stroke({ color: '#ffcc00', width: 2 })
	});

	// Docked N-S/E-W cut position guides -- dashed so they read as "draggable reference", distinct
	// from the solid free-line cut (drawStyle) and RHI radial (azimuthLineStyle).
	const guideLineStyle = new Style({
		stroke: new Stroke({ color: '#94a3b8', width: 1, lineDash: [6, 4] })
	});
	// Hit-test tolerance for grabbing a guide line, in screen pixels.
	const GUIDE_HIT_PX = 8;

	function endpointStyle(label: string, color: string): Style {
		return new Style({
			image: new CircleStyle({
				radius: 6,
				fill: new Fill({ color }),
				stroke: new Stroke({ color: '#0b0f14', width: 2 })
			}),
			text: new Text({
				text: label,
				offsetY: -14,
				font: 'bold 12px monospace',
				fill: new Fill({ color }),
				stroke: new Stroke({ color: '#0b0f14', width: 3 })
			})
		});
	}

	function siteXY(): [number, number] {
		return siteCenter3857(site.lon, site.lat);
	}
	function scale(): number {
		return mercatorScaleAtLat(site.lat);
	}
	// view.getResolution() is map units (EPSG:3857 "metres") per CSS pixel; view.getCenter() is a
	// 3857 coordinate. Both convert to site-relative ground metres the same way every other
	// prop/callback here already does: divide/subtract-then-divide by the site's mercator scale.
	function reportView() {
		if (!map || !onViewChange) return;
		const res = map.getView().getResolution();
		const center = map.getView().getCenter();
		if (res == null || center == null) return;
		const s3857 = siteXY();
		const sc = scale();
		onViewChange({
			groundMPerPx: res / sc,
			centerEastM: (center[0] - s3857[0]) / sc,
			centerNorthM: (center[1] - s3857[1]) / sc
		});
	}

	function applyBaseMap(id: BaseMapId) {
		if (!baseLayer || !labelsLayer) return;
		const { base, labels } = createBaseMapSources(id);
		baseLayer.setSource(base as never);
		labelsLayer.setSource(labels as never);
	}

	onMount(() => {
		// Ordering via zIndex: base(0) → radar(10) → CARTO names(15) → grid(19) → rings(20) →
		// radials(21) → site marker(22) → draw(23) → overlays(25).
		baseLayer = new TileLayer({ zIndex: 0 });
		labelsLayer = new TileLayer({ zIndex: 15 });
		radarLayer = new ImageLayer<Static>({ zIndex: 10, opacity: dataOpacity });
		gridLayer = new VectorLayer({
			source: new VectorSource(),
			style: makeLatLonGridStyle(effectiveOverlayColor, overlayLineWidthPx),
			zIndex: 19,
			visible: showLatLonGrid
		});
		ringsLayer = new VectorLayer({
			source: new VectorSource(),
			style: makeRingStyle(effectiveOverlayColor, overlayLineWidthPx),
			zIndex: 20,
			visible: showRings
		});
		radialsLayer = new VectorLayer({
			source: new VectorSource(),
			style: makeRadialStyle(effectiveOverlayColor, overlayLineWidthPx),
			zIndex: 21,
			visible: showRadials
		});
		siteLayer = new VectorLayer({
			source: new VectorSource({ features: [siteMarkerFeature(siteXY())] }),
			style: siteMarkerStyle,
			zIndex: 22,
			visible: showSiteMarker
		});
		drawLayer = new VectorLayer({
			source: new VectorSource(),
			style: drawStyle,
			zIndex: 23,
			visible: showCutGuide
		});
		guideLayer = new VectorLayer({
			source: new VectorSource(),
			style: guideLineStyle,
			zIndex: 24
		});
		for (const l of extraLayers) l.setZIndex(25);
		map = new Map({
			target: mapEl,
			layers: [
				baseLayer,
				labelsLayer,
				radarLayer,
				gridLayer,
				ringsLayer,
				radialsLayer,
				siteLayer,
				drawLayer,
				guideLayer,
				...extraLayers
			],
			view: new View({ center: siteXY(), zoom: 8 })
		});
		applyBaseMap(baseMap);
		extraGroup = extraLayers;

		map.on('pointermove', (ev) => {
			if (!onreadout) return;
			const lut = buildAzimuthLUT(scan);
			onreadout(readoutAt(ev.coordinate as [number, number], siteXY(), scale(), scan, lut));
		});
		// 'moveend' fires once a pan/zoom gesture settles (not per drag frame), so this is cheap --
		// no debounce needed. Also covers the render effect's own `.fit()` re-centering below.
		map.on('moveend', reportView);

		// Cursor feedback for the N-S/E-W guide lines: resize-style cursor when hovering one, so a
		// user discovers they're draggable without needing a tooltip.
		map.on('pointermove', (ev) => {
			const target = map!.getTargetElement();
			if (draggingGuideAxis) return; // handleDragEvent below owns the cursor mid-drag
			const axis = hitTestGuideAxis(ev.coordinate as [number, number]);
			target.style.cursor = axis === 'ns' ? 'ns-resize' : axis === 'ew' ? 'ew-resize' : '';
		});

		// Custom constrained drag: OL's Modify/Translate interactions move a feature freely in both
		// axes, but a guide line must only slide perpendicular to itself (E-W guide moves N-S only,
		// N-S guide moves E-W only). Pointer lets us hand-roll exactly that, hit-testing against the
		// *current* nsPositionM/ewPositionM props (read live -- these are reactive $props reads, not
		// a snapshot, so they always reflect the latest value without needing to recreate this
		// interaction on every position change).
		const dragInteraction = new PointerInteraction({
			handleDownEvent: (evt) => {
				const axis = hitTestGuideAxis(evt.coordinate as [number, number]);
				draggingGuideAxis = axis;
				return axis !== null;
			},
			handleDragEvent: (evt) => {
				if (!draggingGuideAxis || !map) return;
				map.getTargetElement().style.cursor = draggingGuideAxis === 'ns' ? 'ns-resize' : 'ew-resize';
				const [mx, my] = evt.coordinate as [number, number];
				const s3857 = siteXY();
				const sc = scale();
				const maxRangeM = maxGroundRangeM(scan);
				const clamp = (v: number) => Math.max(-maxRangeM, Math.min(maxRangeM, v));
				if (draggingGuideAxis === 'ns') onNsPositionChange?.(clamp((my - s3857[1]) / sc));
				else onEwPositionChange?.(clamp((mx - s3857[0]) / sc));
			},
			handleUpEvent: () => {
				draggingGuideAxis = null;
				return false;
			}
		});
		map.addInteraction(dragInteraction);
	});

	/** Which guide line (if any) a map coordinate is within `GUIDE_HIT_PX` screen pixels of. */
	function hitTestGuideAxis(coord: [number, number]): 'ns' | 'ew' | null {
		if (!map) return null;
		const res = map.getView().getResolution() ?? 1;
		const toleranceM = res * GUIDE_HIT_PX;
		const s3857 = siteXY();
		const sc = scale();
		const [mx, my] = coord;
		const nsDist = nsPositionM == null ? null : Math.abs(my - (s3857[1] + nsPositionM * sc));
		const ewDist = ewPositionM == null ? null : Math.abs(mx - (s3857[0] + ewPositionM * sc));
		if (nsDist !== null && nsDist <= toleranceM && (ewDist === null || nsDist <= ewDist)) return 'ns';
		if (ewDist !== null && ewDist <= toleranceM) return 'ew';
		return null;
	}

	onDestroy(() => {
		renderer.terminate();
		map?.setTarget(undefined);
	});

	export function getMap(): Map | undefined {
		return map;
	}

	// Re-render the radar image whenever the scan, palette, site, or resolution changes.
	$effect(() => {
		// track dependencies
		const s = scan;
		const p = palette;
		const px = sizePx;
		const _site = site;
		const ringsStep = ringsStepKm;
		const radialsStep = radialsStepDeg;
		const gridLatStep = gridStepLatDeg;
		const gridLonStep = gridStepLonDeg;
		if (!map || !radarLayer) return;

		const token = ++renderToken;
		const maxRangeM = maxGroundRangeM(s);
		// Worker postMessage can't structured-clone a Svelte $state proxy (palette is one) --
		// snapshot to a plain object before crossing the worker boundary.
		renderer.render($state.snapshot(s), $state.snapshot(p), { sizePx: px }).then((result) => {
			if (token !== renderToken || !radarLayer) return; // superseded
			const extent = siteExtent3857(_site.lon, _site.lat, maxRangeM);
			radarLayer.setSource(
				new Static({ url: rasterToDataURL(result), imageExtent: extent, interpolate: false })
			);

			// refresh range rings for this extent
			if (ringsLayer) {
				const src = ringsLayer.getSource()!;
				src.clear();
				src.addFeatures(
					ringFeatures({
						center3857: siteXY(),
						ringsM: defaultRingsM(maxRangeM, ringsStep * 1000),
						mercatorScale: scale(),
						unitSystem
					})
				);
			}

			// refresh lat/lon graticule for this extent
			if (gridLayer) {
				const src = gridLayer.getSource()!;
				src.clear();
				src.addFeatures(
					latLonGridFeatures({
						centerLon: _site.lon,
						centerLat: _site.lat,
						maxRangeM,
						stepLatDeg: gridLatStep,
						stepLonDeg: gridLonStep
					})
				);
			}

			// refresh azimuth radials for this extent
			if (radialsLayer) {
				const src = radialsLayer.getSource()!;
				src.clear();
				src.addFeatures(
					radialFeatures({
						center3857: siteXY(),
						rangeM: maxRangeM,
						mercatorScale: scale(),
						stepDeg: radialsStep
					})
				);
			}

			// re-place the site marker (site position can change between renders)
			if (siteLayer) {
				const src = siteLayer.getSource()!;
				src.clear();
				src.addFeature(siteMarkerFeature(siteXY()));
			}

			// centre + frame the radar on first render
			map!.getView().fit(extent, { padding: [20, 20, 20, 20] });
			// `fit()` is synchronous (no animation) but 'moveend' still fires on the next frame --
			// report the new scale immediately so a caller doesn't render one frame stale.
			reportView();
		});
	});

	// Swap background map when the prop changes.
	$effect(() => {
		applyBaseMap(baseMap);
	});

	// Track the radar (data) layer opacity.
	$effect(() => {
		radarLayer?.setOpacity(dataOpacity);
	});

	// Toggle range-ring / azimuth-radial overlay visibility.
	$effect(() => {
		ringsLayer?.setVisible(showRings);
	});
	$effect(() => {
		radialsLayer?.setVisible(showRadials);
	});
	$effect(() => {
		gridLayer?.setVisible(showLatLonGrid);
	});

	// Re-style rings/radials/grid together whenever the shared color/width setting changes, or the
	// base map switches (color can be 'auto', which depends on it).
	$effect(() => {
		const color = effectiveOverlayColor;
		const width = overlayLineWidthPx;
		ringsLayer?.setStyle(makeRingStyle(color, width));
		radialsLayer?.setStyle(makeRadialStyle(color, width));
		gridLayer?.setStyle(makeLatLonGridStyle(color, width));
	});
	$effect(() => {
		siteLayer?.setVisible(showSiteMarker);
	});
	$effect(() => {
		drawLayer?.setVisible(showCutGuide);
	});

	// Two-point line-draw interaction for the free-hand cross-section tool. Only for tracing a
	// fresh line (no cut yet) -- once a line exists, endpoint dragging (the Modify interaction
	// below) takes over instead. Only one interaction lives at a time; re-created whenever
	// drawEnabled/presetLine toggles so a stale one never lingers.
	$effect(() => {
		const enabled = drawEnabled && presetLine === null;
		if (!map || !drawLayer) return;
		if (draw) {
			map.removeInteraction(draw);
			draw = undefined;
		}
		if (!enabled) return;
		const source = drawLayer.getSource()!;
		const interaction = new Draw({ source, type: 'LineString', minPoints: 2, maxPoints: 2 });
		interaction.on('drawstart', () => source.clear());
		interaction.on('drawend', (ev) => {
			const coords = (ev.feature.getGeometry() as LineString).getCoordinates();
			const start = coords[0];
			const end = coords[coords.length - 1];

			// Mark the two endpoints so the cut's direction (A → B) is unambiguous on the map --
			// same A/green, B/red convention as the cross-section canvas.
			const startFeature = new Feature(new Point(start));
			startFeature.setStyle(endpointStyle('A', CUT_START_COLOR));
			const endFeature = new Feature(new Point(end));
			endFeature.setStyle(endpointStyle('B', CUT_END_COLOR));
			source.addFeatures([startFeature, endFeature]);

			if (!onCutLine) return;
			const [x0, y0] = start;
			const [x1, y1] = end;
			const s3857 = siteXY();
			const sc = scale();
			onCutLine({
				ax: (x0 - s3857[0]) / sc,
				ay: (y0 - s3857[1]) / sc,
				bx: (x1 - s3857[0]) / sc,
				by: (y1 - s3857[1]) / sc
			});
		});
		map.addInteraction(interaction);
		draw = interaction;
	});

	// Render a preset line (E-W/N-S full-range shortcuts) in place of a hand-drawn one -- same
	// A/B endpoint styling, just placed by the site/orientation math instead of a pointer drag.
	$effect(() => {
		const line = presetLine;
		if (!map || !drawLayer) return;
		const source = drawLayer.getSource()!;
		source.clear();
		if (!line) return;
		const s3857 = siteXY();
		const sc = scale();
		const start: [number, number] = [line.ax * sc + s3857[0], line.ay * sc + s3857[1]];
		const end: [number, number] = [line.bx * sc + s3857[0], line.by * sc + s3857[1]];
		source.addFeature(new Feature(new LineString([start, end])));
		const startFeature = new Feature(new Point(start));
		startFeature.setStyle(endpointStyle('A', CUT_START_COLOR));
		const endFeature = new Feature(new Point(end));
		endFeature.setStyle(endpointStyle('B', CUT_END_COLOR));
		source.addFeatures([startFeature, endFeature]);
	});

	// Once a cut line exists, let the user drag its A/B endpoints to redefine the cut in place --
	// no need to reset and re-trace. Vertex insert/delete are disabled so the line always stays a
	// straight two-point cut.
	$effect(() => {
		const line = presetLine;
		if (!map || !drawLayer) return;
		if (cutModify) {
			map.removeInteraction(cutModify);
			cutModify = undefined;
		}
		if (!line) return;
		const source = drawLayer.getSource()!;
		const interaction = new Modify({
			source,
			insertVertexCondition: () => false,
			deleteCondition: () => false
		});
		interaction.on('modifyend', () => {
			if (!onCutLine) return;
			const lineFeature = source
				.getFeatures()
				.find((f) => f.getGeometry()?.getType() === 'LineString');
			if (!lineFeature) return;
			const coords = (lineFeature.getGeometry() as LineString).getCoordinates();
			const start = coords[0];
			const end = coords[coords.length - 1];
			const s3857 = siteXY();
			const sc = scale();
			onCutLine({
				ax: (start[0] - s3857[0]) / sc,
				ay: (start[1] - s3857[1]) / sc,
				bx: (end[0] - s3857[0]) / sc,
				by: (end[1] - s3857[1]) / sc
			});
		});
		map.addInteraction(interaction);
		cutModify = interaction;
	});

	// Single-point pick interaction for the vertical-profile tool. Same lifecycle pattern as the
	// line-draw interaction above; the two are mutually exclusive in practice (different products)
	// but tracked with separate interaction handles so either can toggle independently.
	$effect(() => {
		const enabled = pointSelectEnabled;
		if (!map || !drawLayer) return;
		if (pointDraw) {
			map.removeInteraction(pointDraw);
			pointDraw = undefined;
		}
		if (!enabled) return;
		const source = drawLayer.getSource()!;
		const interaction = new Draw({ source, type: 'Point' });
		interaction.on('drawstart', () => source.clear());
		interaction.on('drawend', (ev) => {
			const [x, y] = (ev.feature.getGeometry() as Point).getCoordinates();
			ev.feature.setStyle(pointStyle);

			if (!onPointSelect) return;
			const s3857 = siteXY();
			const sc = scale();
			onPointSelect({ xEastM: (x - s3857[0]) / sc, yNorthM: (y - s3857[1]) / sc });
		});
		map.addInteraction(interaction);
		pointDraw = interaction;
	});

	// Click-to-pick-azimuth interaction for the RHI tool. Same lifecycle as the point-pick
	// interaction above; the radial itself is drawn by the azimuthDeg effect below, not here, so a
	// slider/number-input change (no map click involved) also moves the line.
	$effect(() => {
		const enabled = azimuthSelectEnabled;
		if (!map || !drawLayer) return;
		if (azimuthDraw) {
			map.removeInteraction(azimuthDraw);
			azimuthDraw = undefined;
		}
		if (!enabled) return;
		const source = drawLayer.getSource()!;
		const interaction = new Draw({ source, type: 'Point' });
		interaction.on('drawend', (ev) => {
			const [x, y] = (ev.feature.getGeometry() as Point).getCoordinates();
			source.clear(); // drop the raw pick point; the azimuthDeg effect redraws the radial
			if (!onAzimuthSelect) return;
			const s3857 = siteXY();
			const dx = x - s3857[0];
			const dy = y - s3857[1];
			const az = ((Math.atan2(dx, dy) * 180) / Math.PI + 360) % 360;
			onAzimuthSelect(Math.round(az));
		});
		map.addInteraction(interaction);
		azimuthDraw = interaction;
	});

	// Click-drag rectangle-draw interaction for the stats-region tool. Same lifecycle as the
	// point-pick interaction above; `createBox()` makes a 'Circle'-type Draw actually drag out an
	// axis-aligned box (a Polygon), so `getExtent()` gives the rectangle directly.
	$effect(() => {
		const enabled = statsSelectEnabled;
		if (!map || !drawLayer) return;
		if (statsDraw) {
			map.removeInteraction(statsDraw);
			statsDraw = undefined;
		}
		if (!enabled) return;
		const source = drawLayer.getSource()!;
		const interaction = new Draw({ source, type: 'Circle', geometryFunction: createBox() });
		interaction.on('drawstart', () => source.clear());
		interaction.on('drawend', (ev) => {
			const extent = ev.feature.getGeometry()!.getExtent();
			if (!onStatsRegionSelect) return;
			const s3857 = siteXY();
			const sc = scale();
			onStatsRegionSelect({
				minXM: (extent[0] - s3857[0]) / sc,
				minYM: (extent[1] - s3857[1]) / sc,
				maxXM: (extent[2] - s3857[0]) / sc,
				maxYM: (extent[3] - s3857[1]) / sc
			});
		});
		map.addInteraction(interaction);
		statsDraw = interaction;
	});

	// Draws the current RHI azimuth as a radial from the site to the scan's max range. Reacts to
	// azimuthDeg directly (not just to map clicks) so the sidebar slider/number-input also moves it.
	$effect(() => {
		if (!azimuthSelectEnabled || !map || !drawLayer) return;
		const az = azimuthDeg;
		const s = scan;
		const source = drawLayer.getSource()!;
		source.clear();
		if (az == null) return;
		const s3857 = siteXY();
		const sc = scale();
		const maxRangeM = maxGroundRangeM(s);
		const rad = (az * Math.PI) / 180;
		const end: [number, number] = [
			s3857[0] + Math.sin(rad) * maxRangeM * sc,
			s3857[1] + Math.cos(rad) * maxRangeM * sc
		];
		const feature = new Feature(new LineString([s3857, end]));
		feature.setStyle(azimuthLineStyle);
		source.addFeature(feature);
	});

	// Draws the two docked-panel guide lines (E-W: horizontal, at nsPositionM; N-S: vertical, at
	// ewPositionM), spanning the scan's full range. Always on -- these aren't gated by a "draw
	// mode" toggle, only by `nsPositionM`/`ewPositionM` being non-null (see prop doc).
	$effect(() => {
		if (!map || !guideLayer) return;
		const ns = nsPositionM;
		const ew = ewPositionM;
		const s = scan;
		const source = guideLayer.getSource()!;
		source.clear();
		const s3857 = siteXY();
		const sc = scale();
		const maxRangeM = maxGroundRangeM(s) * sc;
		if (ns != null) {
			const y = s3857[1] + ns * sc;
			source.addFeature(
				new Feature(
					new LineString([
						[s3857[0] - maxRangeM, y],
						[s3857[0] + maxRangeM, y]
					])
				)
			);
		}
		if (ew != null) {
			const x = s3857[0] + ew * sc;
			source.addFeature(
				new Feature(
					new LineString([
						[x, s3857[1] - maxRangeM],
						[x, s3857[1] + maxRangeM]
					])
				)
			);
		}
	});

	// Keep the map's extra layers in sync if the prop changes.
	$effect(() => {
		if (!map) return;
		for (const l of extraGroup) map.removeLayer(l);
		for (const l of extraLayers) {
			l.setZIndex(25);
			map.addLayer(l);
		}
		extraGroup = extraLayers;
	});
</script>

<div bind:this={mapEl} class="h-full w-full"></div>
