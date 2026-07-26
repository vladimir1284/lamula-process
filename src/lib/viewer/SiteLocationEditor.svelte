<script lang="ts">
	import { onMount, onDestroy, untrack } from 'svelte';
	import Map from 'ol/Map';
	import View from 'ol/View';
	import VectorLayer from 'ol/layer/Vector';
	import VectorSource from 'ol/source/Vector';
	import Feature from 'ol/Feature';
	import Point from 'ol/geom/Point';
	import { Style, Circle, Fill, Stroke } from 'ol/style';
	import { fromLonLat, toLonLat } from 'ol/proj';
	import type { MapBrowserEvent } from 'ol';
	import 'ol/ol.css';

	import { standardOverlays } from '$lib/overlays';
	import { fetchElevationM } from '$lib/geo/elevation';

	interface LocationValue {
		lat: number;
		lon: number;
		altM: number;
	}

	interface Props {
		/** Prefills the form, e.g. when re-editing an already-saved site. */
		initial?: Partial<LocationValue>;
		onsave: (location: LocationValue) => void;
		oncancel: () => void;
	}

	let { initial, onsave, oncancel }: Props = $props();

	// Caribbean / Central America, matching the region the bundled geo overlays cover.
	const DEFAULT_CENTER: [number, number] = [-77, 20];
	const DEFAULT_ZOOM = 5;

	// One-shot seed from the prop: this editor owns its fields afterwards, it doesn't track
	// further changes to `initial` (there aren't any -- the parent mounts a fresh instance per edit).
	let lat = $state<number | undefined>(untrack(() => initial?.lat));
	let lon = $state<number | undefined>(untrack(() => initial?.lon));
	let altM = $state<number | undefined>(untrack(() => initial?.altM));
	let altMTouched = $state(false);
	let elevationStatus = $state<'idle' | 'loading' | 'unavailable'>('idle');

	let mapEl: HTMLDivElement;
	let map: Map | undefined;
	let markerSource: VectorSource | undefined;

	const canSave = $derived(
		lat !== undefined &&
			lon !== undefined &&
			altM !== undefined &&
			!Number.isNaN(lat) &&
			!Number.isNaN(lon) &&
			!Number.isNaN(altM)
	);

	function setMarker(newLon: number, newLat: number) {
		if (!markerSource) return;
		markerSource.clear();
		markerSource.addFeature(new Feature(new Point(fromLonLat([newLon, newLat]))));
	}

	function onMapClick(ev: MapBrowserEvent) {
		const [clickLon, clickLat] = toLonLat(ev.coordinate);
		lon = clickLon;
		lat = clickLat;
	}

	function onLatInput(v: string) {
		const n = Number(v);
		lat = v === '' ? undefined : n;
	}
	function onLonInput(v: string) {
		const n = Number(v);
		lon = v === '' ? undefined : n;
	}
	function onAltInput(v: string) {
		altMTouched = true;
		altM = v === '' ? undefined : Number(v);
	}

	onMount(() => {
		markerSource = new VectorSource();
		const markerLayer = new VectorLayer({
			source: markerSource,
			style: new Style({
				image: new Circle({
					radius: 7,
					fill: new Fill({ color: '#dc2626' }),
					stroke: new Stroke({ color: '#ffffff', width: 2 })
				})
			})
		});

		map = new Map({
			target: mapEl,
			layers: [...standardOverlays(), markerLayer],
			view: new View({
				center:
					lon !== undefined && lat !== undefined
						? fromLonLat([lon, lat])
						: fromLonLat(DEFAULT_CENTER),
				zoom: lon !== undefined && lat !== undefined ? 8 : DEFAULT_ZOOM
			})
		});
		map.on('click', onMapClick);

		if (lon !== undefined && lat !== undefined) setMarker(lon, lat);
	});

	onDestroy(() => {
		map?.setTarget(undefined);
	});

	// Keep the marker in sync with lat/lon, however they changed (click or manual entry).
	$effect(() => {
		if (lon !== undefined && lat !== undefined && !Number.isNaN(lon) && !Number.isNaN(lat)) {
			setMarker(lon, lat);
		} else if (markerSource) {
			markerSource.clear();
		}
	});

	// Auto-fill altM from terrain elevation whenever lat/lon settle on a value the user hasn't
	// overridden by hand. Token-guarded so a stale response can't clobber a newer pick.
	let elevationToken = 0;
	$effect(() => {
		const currentLat = lat;
		const currentLon = lon;
		if (altMTouched) return;
		if (currentLat === undefined || currentLon === undefined) return;
		if (Number.isNaN(currentLat) || Number.isNaN(currentLon)) return;

		const token = ++elevationToken;
		elevationStatus = 'loading';
		fetchElevationM(currentLat, currentLon).then((m) => {
			if (token !== elevationToken) return; // superseded by a newer pick
			if (m === null) {
				elevationStatus = 'unavailable';
				return;
			}
			elevationStatus = 'idle';
			altM = m;
		});
	});

	function save() {
		if (!canSave) return;
		onsave({ lat: lat as number, lon: lon as number, altM: altM as number });
	}
</script>

<div class="flex flex-col gap-3 font-mono text-label-mono">
	<p class="text-body-sm text-on-surface-variant">
		Selecciona la ubicación del radar haciendo click en el mapa, o entra las coordenadas a mano.
	</p>

	<div
		bind:this={mapEl}
		class="h-72 w-full overflow-hidden rounded border border-outline-variant"
	></div>

	<div class="flex flex-wrap gap-3">
		<label class="flex flex-col gap-1">
			<span class="text-[11px] text-on-surface-variant">Latitud</span>
			<input
				type="number"
				step="any"
				class="cyan-glow w-32 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
				value={lat ?? ''}
				oninput={(e) => onLatInput(e.currentTarget.value)}
			/>
		</label>
		<label class="flex flex-col gap-1">
			<span class="text-[11px] text-on-surface-variant">Longitud</span>
			<input
				type="number"
				step="any"
				class="cyan-glow w-32 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
				value={lon ?? ''}
				oninput={(e) => onLonInput(e.currentTarget.value)}
			/>
		</label>
		<label class="flex flex-col gap-1">
			<span class="text-[11px] text-on-surface-variant">Altura (m sobre el nivel del mar)</span>
			<input
				type="number"
				step="any"
				class="cyan-glow w-36 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
				value={altM ?? ''}
				oninput={(e) => onAltInput(e.currentTarget.value)}
			/>
		</label>
	</div>

	{#if elevationStatus === 'loading'}
		<p class="flex items-center gap-1 text-[11px] text-on-surface-variant">
			<span class="material-symbols-outlined text-[14px]">terrain</span> Buscando elevación del terreno…
		</p>
	{:else if elevationStatus === 'unavailable'}
		<p class="flex items-center gap-1 text-[11px] text-dbz-heavy">
			<span class="material-symbols-outlined text-[14px]">warning</span>
			No se pudo obtener la elevación automática (servicio no disponible). Entra la altura a mano.
		</p>
	{/if}

	<div class="flex justify-end gap-2 border-t border-outline-variant pt-3">
		<button
			class="rounded border border-outline-variant bg-surface-container-high px-3 py-1 text-on-surface transition-colors hover:border-primary-container"
			onclick={oncancel}
		>
			Cancelar
		</button>
		<button
			class="flex items-center gap-1 rounded bg-primary-container px-3 py-1 text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
			disabled={!canSave}
			onclick={save}
		>
			<span class="material-symbols-outlined text-[16px]">save</span> Guardar
		</button>
	</div>
</div>
