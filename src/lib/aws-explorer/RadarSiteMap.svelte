<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import Map from 'ol/Map';
	import View from 'ol/View';
	import TileLayer from 'ol/layer/Tile';
	import VectorLayer from 'ol/layer/Vector';
	import VectorSource from 'ol/source/Vector';
	import Feature from 'ol/Feature';
	import Point from 'ol/geom/Point';
	import { Style, Circle, Fill, Stroke } from 'ol/style';
	import { fromLonLat } from 'ol/proj';
	import type { MapBrowserEvent } from 'ol';
	import 'ol/ol.css';

	import { createBaseMapSources } from '$lib/viewer/baseMaps';
	import { US_RADAR_SITES, type RadarCatalogSite } from './radarCatalog';

	interface Props {
		/** Highlighted (e.g. nearest-N from a zip search); rendered larger/brighter than the rest. */
		highlighted?: string[];
		selected?: string | null;
		onselect: (code: string) => void;
	}

	let { highlighted = [], selected = null, onselect }: Props = $props();

	// CONUS + Alaska/Hawaii/territories, matching the spread of known-sites.json's WSR-88D entries.
	const DEFAULT_CENTER: [number, number] = [-96, 39];
	const DEFAULT_ZOOM = 4;

	let mapEl: HTMLDivElement;
	let map: Map | undefined;
	let markerSource: VectorSource | undefined;

	function styleFor(site: RadarCatalogSite): Style {
		const isSelected = site.code === selected;
		const isHighlighted = highlighted.includes(site.code);
		const color = isSelected ? '#22d3ee' : isHighlighted ? '#f59e0b' : '#94a3b8';
		return new Style({
			image: new Circle({
				radius: isSelected ? 8 : isHighlighted ? 6 : 4,
				fill: new Fill({ color }),
				stroke: new Stroke({ color: '#0f172a', width: 1.5 })
			})
		});
	}

	function buildFeatures(): Feature[] {
		return US_RADAR_SITES.map((site) => {
			const feature = new Feature(new Point(fromLonLat([site.lon, site.lat])));
			feature.set('code', site.code);
			feature.setStyle(styleFor(site));
			return feature;
		});
	}

	function onMapClick(ev: MapBrowserEvent) {
		if (!map) return;
		map.forEachFeatureAtPixel(ev.pixel, (feature) => {
			const code = feature.get('code');
			if (typeof code === 'string') onselect(code);
			return true; // stop after the first hit
		});
	}

	onMount(() => {
		markerSource = new VectorSource({ features: buildFeatures() });
		const markerLayer = new VectorLayer({ source: markerSource });
		const osmLayer = new TileLayer({ source: createBaseMapSources('osm').base! });

		map = new Map({
			target: mapEl,
			layers: [osmLayer, markerLayer],
			view: new View({ center: fromLonLat(DEFAULT_CENTER), zoom: DEFAULT_ZOOM })
		});
		map.on('click', onMapClick);
	});

	onDestroy(() => {
		map?.setTarget(undefined);
	});

	// Re-style markers whenever the highlighted/selected set changes (new zip search, new pick).
	$effect(() => {
		selected;
		highlighted;
		markerSource?.getFeatures().forEach((feature) => {
			const code = feature.get('code');
			const site = US_RADAR_SITES.find((s) => s.code === code);
			if (site) feature.setStyle(styleFor(site));
		});
	});
</script>

<div bind:this={mapEl} class="h-80 w-full overflow-hidden rounded border border-outline-variant"></div>
