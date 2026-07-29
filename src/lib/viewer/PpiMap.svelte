<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import Map from 'ol/Map';
	import View from 'ol/View';
	import ImageLayer from 'ol/layer/Image';
	import TileLayer from 'ol/layer/Tile';
	import Static from 'ol/source/ImageStatic';
	import VectorLayer from 'ol/layer/Vector';
	import VectorSource from 'ol/source/Vector';
	import Draw from 'ol/interaction/Draw';
	import LineString from 'ol/geom/LineString';
	import Feature from 'ol/Feature';
	import Point from 'ol/geom/Point';
	import { Style, Stroke, Circle as CircleStyle, Fill, Text } from 'ol/style';
	import type BaseLayer from 'ol/layer/Base';
	import 'ol/ol.css';

	import { createBaseMapSources, type BaseMapId } from './baseMaps';

	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import type { CutLine } from '$lib/products/crossSection';
	import { PpiRenderer } from '$lib/render/renderClient';
	import { buildAzimuthLUT, maxGroundRangeM } from '$lib/render/scanSample';
	import { siteExtent3857, siteCenter3857, mercatorScaleAtLat } from '$lib/geo/extent';
	import { rasterToDataURL } from './radarImage';
	import { ringFeatures, ringStyle, defaultRingsM } from './rings';
	import { radialFeatures, radialStyle } from './radials';
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
		/** Unit system for range-ring labels. Default metric (km). */
		unitSystem?: UnitSystem;
		/** Show distance-from-radar range rings. Default true. */
		showRings?: boolean;
		/** Show azimuth radial marks. Default true. */
		showRadials?: boolean;
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
		unitSystem = 'metric',
		showRings = true,
		showRadials = false
	}: Props = $props();

	let mapEl: HTMLDivElement;
	let map: Map | undefined;
	let baseLayer: TileLayer | undefined;
	let labelsLayer: TileLayer | undefined;
	let radarLayer: ImageLayer<Static> | undefined;
	let ringsLayer: VectorLayer<VectorSource> | undefined;
	let radialsLayer: VectorLayer<VectorSource> | undefined;
	let drawLayer: VectorLayer<VectorSource> | undefined;
	let draw: Draw | undefined;
	let pointDraw: Draw | undefined;
	let azimuthDraw: Draw | undefined;
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

	function applyBaseMap(id: BaseMapId) {
		if (!baseLayer || !labelsLayer) return;
		const { base, labels } = createBaseMapSources(id);
		baseLayer.setSource(base as never);
		labelsLayer.setSource(labels as never);
	}

	onMount(() => {
		// Ordering via zIndex: base(0) → radar(10) → CARTO names(15) → rings(20) → radials(21) →
		// overlays(25).
		baseLayer = new TileLayer({ zIndex: 0 });
		labelsLayer = new TileLayer({ zIndex: 15 });
		radarLayer = new ImageLayer<Static>({ zIndex: 10, opacity: dataOpacity });
		ringsLayer = new VectorLayer({
			source: new VectorSource(),
			style: ringStyle,
			zIndex: 20,
			visible: showRings
		});
		radialsLayer = new VectorLayer({
			source: new VectorSource(),
			style: radialStyle,
			zIndex: 21,
			visible: showRadials
		});
		drawLayer = new VectorLayer({ source: new VectorSource(), style: drawStyle, zIndex: 22 });
		for (const l of extraLayers) l.setZIndex(25);
		map = new Map({
			target: mapEl,
			layers: [
				baseLayer,
				labelsLayer,
				radarLayer,
				ringsLayer,
				radialsLayer,
				drawLayer,
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
	});

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
						ringsM: defaultRingsM(maxRangeM),
						mercatorScale: scale(),
						unitSystem
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
						mercatorScale: scale()
					})
				);
			}

			// centre + frame the radar on first render
			map!.getView().fit(extent, { padding: [20, 20, 20, 20] });
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

	// Two-point line-draw interaction for the free-hand cross-section tool. Only one interaction
	// lives at a time; re-created whenever drawEnabled toggles so a stale one never lingers.
	$effect(() => {
		const enabled = drawEnabled;
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
