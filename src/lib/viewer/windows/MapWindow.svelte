<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import type { ChannelRef, GroundProductKind } from '$lib/pipeline';
	import { listElevationsDeg, deriveGroundProduct, type DeriveOptions } from '$lib/pipeline';
	import type { Observation } from '$lib/domain/types';
	import type { PaletteBook } from '$lib/platform';
	import { paletteForMoment } from '$lib/platform';
	import { formatDistanceM, formatReading, type UnitSystem } from '$lib/units';
	import { standardOverlays } from '$lib/overlays';
	import { BASE_MAP_IDS, BASE_MAP_LABELS } from '$lib/viewer/baseMaps';
	import {
		PpiMap,
		ScaleLegend,
		exportMapToCanvas,
		downloadCanvasAsPng,
		buildExportFilename
	} from '$lib/viewer';
	import type { Readout } from '$lib/viewer/readout';
	import {
		windowStore,
		isChartWindow,
		type RadarWindow,
		type MapWindowPayload,
		type ChartWindowPayloadBase,
		type RhiWindowPayload,
		type CrossSectionWindowPayload
	} from '$lib/windows';
	import {
		catalogLabel,
		defaultCrossSectionPayload,
		defaultProfilePayload,
		paletteKeyForGroundProduct
	} from '$lib/windows/productCatalog';
	import { _ } from '$lib/i18n';

	interface Props {
		win: RadarWindow;
		observation: Observation | null;
		channels: ChannelRef[];
		book: PaletteBook;
		unitSystem: UnitSystem;
		site: { lon: number; lat: number } | null;
		effectiveSiteAltM: number;
		onOpenLocationEditor: () => void;
		onShowVad: (channelIndex: number) => void;
		onEditScale: (paletteKey: string) => void;
	}

	let {
		win,
		observation,
		channels,
		book,
		unitSystem,
		site,
		effectiveSiteAltM,
		onOpenLocationEditor,
		onShowVad,
		onEditScale
	}: Props = $props();

	const payload = $derived(win.payload as MapWindowPayload);
	const overlays = standardOverlays();

	const channel = $derived(channels[payload.channelIndex]?.channel);
	const elevations = $derived(channel ? listElevationsDeg(channel) : []);
	const usesElevation = $derived(
		payload.product === 'PPI' || payload.product === 'RAIN' || payload.product === 'WIND_SPEED'
	);
	const paletteKey = $derived(
		paletteKeyForGroundProduct(payload.product, channel?.moment ?? 'dBZ')
	);
	const palette = $derived(paletteForMoment(book, paletteKey));
	const productTitle = $derived($_(catalogLabel(payload.product)));

	const deriveOpts = $derived<DeriveOptions>({
		elevationDeg: payload.elevationDeg,
		beamWidthDeg: channel?.beamWidthDeg ?? 1.0,
		siteAltM: effectiveSiteAltM,
		cappiBottomM: payload.cappiBottomKm * 1000,
		cappiTopM: payload.cappiTopKm * 1000,
		topsMinDbz: payload.topsMinDbz,
		vilBottomM: payload.vilBottomKm * 1000,
		vilTopM: payload.vilTopKm * 1000,
		vilC1: payload.vilC1,
		vilC2: payload.vilC2,
		zrA: payload.zrA,
		zrB: payload.zrB
	});

	const ground = $derived.by(() => {
		if (!channel || channel.scans.length === 0) return null;
		return deriveGroundProduct(channel, payload.product as GroundProductKind, deriveOpts);
	});

	// Focus -> picker linkage: which of MY derived-chart windows currently owns the picker overlay.
	// Sticky (not a plain "focused === child" check) so clicking the map itself to move the picker
	// doesn't immediately hide it by shifting focus away from the child.
	const myChartWindows = $derived(
		windowStore.windows.filter(
			(w) => isChartWindow(w) && (w.payload as ChartWindowPayloadBase).sourceMapWindowId === win.id
		)
	);
	let activeChildId = $state<string | null>(null);
	$effect(() => {
		if (myChartWindows.some((w) => w.id === windowStore.focusedId)) {
			activeChildId = windowStore.focusedId;
		}
	});
	$effect(() => {
		if (activeChildId && !myChartWindows.some((w) => w.id === activeChildId)) activeChildId = null;
	});
	const activeChild = $derived(myChartWindows.find((w) => w.id === activeChildId) ?? null);
	const showPicker = $derived(
		activeChild !== null &&
			(windowStore.focusedId === win.id || windowStore.focusedId === activeChildId)
	);
	// Armed: this map is waiting for a free cross-section line (or profile point) to be picked,
	// before any chart window exists (see productCatalog CROSS_LINE/PROFILE handlers in +page.svelte).
	const armingCrossSection = $derived(windowStore.armedCrossSection === win.id);
	const armingProfile = $derived(windowStore.armedProfile === win.id);
	const pickerMode = $derived(
		armingCrossSection
			? 'cross-section'
			: armingProfile
				? 'profile'
				: showPicker && activeChild
					? activeChild.type
					: null
	);

	function onAzimuthSelect(a: number) {
		if (activeChild?.type === 'rhi') windowStore.setPayload(activeChild.id, { azimuthDeg: a });
	}
	function onCutLine(l: CrossSectionWindowPayload['line']) {
		if (armingCrossSection) {
			windowStore.disarmCrossSection();
			windowStore.open('cross-section', {
				title: $_('window.crossSectionTitle'),
				payload: { ...defaultCrossSectionPayload(win.id), line: l }
			});
			return;
		}
		if (activeChild?.type === 'cross-section') windowStore.setPayload(activeChild.id, { line: l });
	}
	function onPointSelect(p: { xEastM: number; yNorthM: number }) {
		if (armingProfile) {
			windowStore.disarmProfile();
			windowStore.open('profile', {
				title: $_('catalog.items.profile'),
				payload: { ...defaultProfilePayload(win.id), point: p },
				rect: { width: 420, height: 640 }
			});
			return;
		}
		if (activeChild?.type === 'profile') windowStore.setPayload(activeChild.id, { point: p });
	}

	let readout = $state<Readout | null>(null);
	let ppiMapRef: ReturnType<typeof PpiMap> | undefined = $state();

	onMount(() => {
		windowStore.setInstanceApi(win.id, { getMap: () => ppiMapRef?.getMap() });
	});
	onDestroy(() => windowStore.setInstanceApi(win.id, null));

	function fmt(n: number | null | undefined, digits = 1): string {
		return n === null || n === undefined ? '—' : n.toFixed(digits);
	}

	async function exportCurrentImage() {
		const filename = buildExportFilename([
			observation?.site.name,
			observation?.timestamp,
			payload.product,
			channel?.moment,
			usesElevation ? `el${payload.elevationDeg}` : undefined
		]);
		const map = ppiMapRef?.getMap();
		if (map) downloadCanvasAsPng(await exportMapToCanvas(map), filename);
	}
</script>

<div class="flex h-full flex-col">
	<!-- Toolbar: channel/elevation + per-product params + base map/overlay controls. -->
	<div
		class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
	>
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
			>{productTitle}</span
		>
		<label
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant"
				>{$_('window.readout.channel')}</span
			>
			<select
				class="border-none bg-transparent p-0 font-mono text-[11px] text-on-surface focus:ring-0"
				bind:value={payload.channelIndex}
			>
				{#each channels as ref (ref.index)}
					<option value={ref.index}>{ref.channel.moment} ({ref.channel.scans.length})</option>
				{/each}
			</select>
		</label>

		{#if usesElevation}
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant"
					>{$_('window.readout.elevation')}</span
				>
				<select
					class="border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.elevationDeg}
				>
					{#each elevations as e (e)}
						<option value={e}>{e.toFixed(1)}°</option>
					{/each}
				</select>
			</label>
		{/if}

		{#if payload.product === 'CAPPI'}
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.base')}</span
				>
				<input
					type="number"
					step="0.5"
					class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.cappiBottomKm}
				/>
				<span class="font-mono text-[9px] text-on-surface-variant">km</span>
			</label>
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.top')}</span>
				<input
					type="number"
					step="0.5"
					class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.cappiTopKm}
				/>
				<span class="font-mono text-[9px] text-on-surface-variant">km</span>
			</label>
		{/if}

		{#if payload.product === 'TOPS'}
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant"
					>{$_('window.readout.threshold')}</span
				>
				<input
					type="number"
					step="1"
					class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.topsMinDbz}
				/>
				<span class="font-mono text-[9px] text-on-surface-variant">dBZ</span>
			</label>
		{/if}

		{#if payload.product === 'VIL'}
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.base')}</span
				>
				<input
					type="number"
					step="0.5"
					class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.vilBottomKm}
				/>
			</label>
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.top')}</span>
				<input
					type="number"
					step="0.5"
					class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.vilTopKm}
				/>
			</label>
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">C1</span>
				<input
					type="number"
					step="0.0001"
					class="w-16 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.vilC1}
				/>
			</label>
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">C2</span>
				<input
					type="number"
					step="0.0001"
					class="w-16 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.vilC2}
				/>
			</label>
		{/if}

		{#if payload.product === 'RAIN'}
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">Z-R A</span>
				<input
					type="number"
					step="10"
					class="w-12 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.zrA}
				/>
			</label>
			<label
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
			>
				<span class="font-mono text-[9px] text-on-surface-variant">Z-R B</span>
				<input
					type="number"
					step="0.1"
					class="w-12 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
					bind:value={payload.zrB}
				/>
			</label>
		{/if}

		{#if payload.product === 'WIND_SPEED'}
			<button
				type="button"
				class="flex h-7 items-center gap-1 rounded border border-primary-container/60 px-2 font-mono text-[11px] text-primary-container hover:bg-primary-container hover:text-on-primary-container"
				onclick={() => onShowVad(payload.channelIndex)}
			>
				<span class="material-symbols-outlined text-[14px]">air</span> VAD
			</button>
		{/if}

		{#if site}
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.baseMapTitle')}
			>
				<span class="material-symbols-outlined text-[14px] text-primary-container">map</span>
				<select
					bind:value={payload.baseMap}
					class="rounded border border-outline-variant bg-surface-container-lowest px-1 text-on-surface focus:border-primary-container focus:outline-none"
				>
					<option value="off">{$_(BASE_MAP_LABELS.off)}</option>
					{#each BASE_MAP_IDS as id (id)}
						<option value={id}>{$_(BASE_MAP_LABELS[id])}</option>
					{/each}
				</select>
			</label>
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.opacityTitle')}
			>
				<span class="material-symbols-outlined text-[14px] text-primary-container">opacity</span>
				<input
					type="range"
					min="0"
					max="1"
					step="0.05"
					bind:value={payload.dataOpacity}
					class="h-1 w-14 accent-primary-container"
				/>
			</label>
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.ringsTitle')}
			>
				<input type="checkbox" bind:checked={payload.showRings} class="accent-primary-container" />
				{$_('window.ringsAbbr')}
			</label>
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.radialsTitle')}
			>
				<input
					type="checkbox"
					bind:checked={payload.showRadials}
					class="accent-primary-container"
				/>
				{$_('window.radialsAbbr')}
			</label>
		{/if}

		<div class="ml-auto flex items-center gap-2">
			<ScaleLegend {palette} />
			<button
				type="button"
				class="flex h-7 w-7 shrink-0 items-center justify-center rounded border border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:border-primary-container hover:text-primary-container"
				onclick={() => onEditScale(paletteKey)}
				aria-label={$_('window.editScale')}
				title={$_('window.editScale')}
			>
				<span class="material-symbols-outlined text-[14px]">palette</span>
			</button>
			<button
				type="button"
				class="flex h-7 w-7 shrink-0 items-center justify-center rounded border border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:border-primary-container hover:text-primary-container"
				onclick={exportCurrentImage}
				aria-label={$_('window.exportImage')}
				title={$_('window.exportImage')}
			>
				<span class="material-symbols-outlined text-[14px]">download</span>
			</button>
		</div>
	</div>

	<!-- Map. -->
	<div class="relative min-h-0 flex-1 overflow-hidden bg-black">
		{#if !observation}
			<div class="flex h-full flex-col items-center justify-center gap-3 px-4 text-center">
				<span class="material-symbols-outlined text-[32px] text-on-surface-variant"
					>upload_file</span
				>
				<p class="max-w-xs text-body-sm text-on-surface-variant">
					{$_('window.noObservationMap')}
				</p>
			</div>
		{:else if !site}
			<div class="flex h-full flex-col items-center justify-center gap-3 px-4 text-center">
				<span class="material-symbols-outlined text-[32px] text-dbz-heavy">wrong_location</span>
				<p class="max-w-xs text-body-sm text-on-surface-variant">
					{$_('window.noSitePosition')}
					<span class="text-on-surface">{productTitle}</span>.
				</p>
				<button
					class="flex h-9 items-center gap-2 rounded bg-primary-container px-3 font-mono text-[11px] text-on-primary-container transition-all hover:opacity-90 active:scale-95"
					onclick={onOpenLocationEditor}
				>
					<span class="material-symbols-outlined text-[16px]">add_location_alt</span>
					{$_('window.defineLocation')}
				</button>
			</div>
		{:else if ground}
			<PpiMap
				bind:this={ppiMapRef}
				scan={ground.scan}
				{palette}
				{site}
				baseMap={payload.baseMap}
				dataOpacity={payload.dataOpacity}
				showRings={payload.showRings}
				showRadials={payload.showRadials}
				extraLayers={overlays}
				{unitSystem}
				drawEnabled={pickerMode === 'cross-section'}
				presetLine={pickerMode === 'cross-section'
					? ((activeChild?.payload as CrossSectionWindowPayload | undefined)?.line ?? null)
					: null}
				pointSelectEnabled={pickerMode === 'profile'}
				azimuthSelectEnabled={pickerMode === 'rhi'}
				azimuthDeg={pickerMode === 'rhi'
					? (activeChild?.payload as RhiWindowPayload).azimuthDeg
					: null}
				{onCutLine}
				{onPointSelect}
				{onAzimuthSelect}
				onreadout={(r) => (readout = r)}
			/>
		{/if}
	</div>

	<!-- Readout bar. -->
	<div
		class="grid grid-cols-3 gap-px border-t border-outline-variant bg-surface-container-low font-mono sm:grid-cols-6"
	>
		{#if readout}
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">{$_('window.readout.lat')}</p>
				<p class="text-[11px] text-on-surface">{fmt(readout.lat, 4)}°</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">{$_('window.readout.lon')}</p>
				<p class="text-[11px] text-on-surface">{fmt(readout.lon, 4)}°</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">{$_('window.readout.azimuth')}</p>
				<p class="text-[11px] text-primary-container">{fmt(readout.azimuthDeg)}°</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">{$_('window.readout.range')}</p>
				<p class="text-[11px] text-on-surface">{formatDistanceM(readout.rangeM, unitSystem)}</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">{$_('window.readout.value')}</p>
				<p class="text-[11px] text-dbz-heavy">
					{readout.value === null
						? '—'
						: formatReading(readout.value, ground?.unit ?? '', unitSystem)}
				</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">{$_('window.readout.status')}</p>
				<p class="text-[11px] text-on-surface">
					{readout.flag && readout.flag !== 'ok' ? readout.flag : 'ok'}
				</p>
			</div>
		{:else}
			<div class="col-span-3 bg-surface-container-low p-2 sm:col-span-6">
				<p class="text-[11px] text-on-surface-variant">
					{$_('window.hoverHintMap')}
				</p>
			</div>
		{/if}
	</div>
</div>
