<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import Map from 'ol/Map';
	import View from 'ol/View';
	import ImageLayer from 'ol/layer/Image';
	import TileLayer from 'ol/layer/Tile';
	import Static from 'ol/source/ImageStatic';
	import VectorLayer from 'ol/layer/Vector';
	import VectorSource from 'ol/source/Vector';
	import type BaseLayer from 'ol/layer/Base';
	import 'ol/ol.css';

	import { createBaseMapSources, type BaseMapId } from './baseMaps';

	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import { PpiRenderer } from '$lib/render/renderClient';
	import { buildAzimuthLUT, maxGroundRangeM } from '$lib/render/scanSample';
	import { siteExtent3857, siteCenter3857, mercatorScaleAtLat } from '$lib/geo/extent';
	import { rasterToDataURL } from './radarImage';
	import { ringFeatures, ringStyle, defaultRingsM } from './rings';
	import { readoutAt, type Readout } from './readout';

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
	}

	let {
		scan,
		palette,
		site,
		sizePx = 1024,
		extraLayers = [],
		baseMap = 'off',
		dataOpacity = 1,
		onreadout
	}: Props = $props();

	let mapEl: HTMLDivElement;
	let map: Map | undefined;
	let baseLayer: TileLayer | undefined;
	let labelsLayer: TileLayer | undefined;
	let radarLayer: ImageLayer<Static> | undefined;
	let ringsLayer: VectorLayer<VectorSource> | undefined;
	let extraGroup: BaseLayer[] = [];
	const renderer = new PpiRenderer();
	let renderToken = 0;

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
		// Ordering via zIndex: base(0) → radar(10) → CARTO names(15) → rings(20) → overlays(25).
		baseLayer = new TileLayer({ zIndex: 0 });
		labelsLayer = new TileLayer({ zIndex: 15 });
		radarLayer = new ImageLayer<Static>({ zIndex: 10, opacity: dataOpacity });
		ringsLayer = new VectorLayer({ source: new VectorSource(), style: ringStyle, zIndex: 20 });
		for (const l of extraLayers) l.setZIndex(25);
		map = new Map({
			target: mapEl,
			layers: [baseLayer, labelsLayer, radarLayer, ringsLayer, ...extraLayers],
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
