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
	import type LineString from 'ol/geom/LineString';
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
