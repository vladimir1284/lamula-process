<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import type { ChannelRef } from '$lib/pipeline';
	import { buildAccumFrames, deriveAccumulateOptionsFromPayload } from '$lib/pipeline';
	import type { TimeSpan } from '$lib/domain';
	import { computeAccumulate, type ProductResult } from '$lib/products';
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
	import { windowStore, type RadarWindow, type AccumulateWindowPayload } from '$lib/windows';
	import { catalogLabel } from '$lib/windows/productCatalog';
	import { _ } from '$lib/i18n';

	interface Props {
		win: RadarWindow;
		timeSpan: TimeSpan | null;
		channels: ChannelRef[];
		book: PaletteBook;
		unitSystem: UnitSystem;
		site: { lon: number; lat: number } | null;
		effectiveSiteAltM: number;
		onOpenLocationEditor: () => void;
		onEditScale: (paletteKey: string) => void;
	}

	let {
		win,
		timeSpan,
		channels,
		book,
		unitSystem,
		site,
		effectiveSiteAltM,
		onOpenLocationEditor,
		onEditScale
	}: Props = $props();

	const payload = $derived(win.payload as AccumulateWindowPayload);
	const overlays = standardOverlays();

	const channel = $derived(channels[payload.channelIndex]?.channel);
	const paletteKey = 'ACCUMULATE';
	const palette = $derived(paletteForMoment(book, paletteKey));
	const productTitle = $derived($_(catalogLabel('ACCUMULATE')));

	const accumOpts = $derived(
		deriveAccumulateOptionsFromPayload(payload, channel?.beamWidthDeg ?? 1.0, effectiveSiteAltM)
	);

	const frames = $derived.by(() =>
		timeSpan && channel ? buildAccumFrames(timeSpan, channel.moment) : []
	);

	// `computeAccumulate` throws when no frame has any scan for the chosen moment -- a real runtime
	// state (loaded TimeSpan doesn't carry this moment at all), not a bug, so it's caught, not let
	// propagate.
	const result: ProductResult | null = $derived.by(() => {
		if (frames.length === 0) return null;
		try {
			return computeAccumulate(frames, accumOpts);
		} catch {
			return null;
		}
	});

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
		const first = timeSpan?.observations[0];
		const filename = buildExportFilename([
			first?.site.name,
			first?.timestamp,
			'ACCUMULATE',
			channel?.moment
		]);
		const map = ppiMapRef?.getMap();
		if (map) downloadCanvasAsPng(await exportMapToCanvas(map), filename);
	}
</script>

<div class="flex h-full flex-col">
	<!-- Toolbar: channel + accumulation params + base map/overlay controls. -->
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

		<label
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.base')}</span>
			<input
				type="number"
				step="0.5"
				class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				bind:value={payload.bottomKm}
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
				bind:value={payload.topKm}
			/>
			<span class="font-mono text-[9px] text-on-surface-variant">km</span>
		</label>
		<label
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant"
				>{$_('window.readout.interval')}</span
			>
			<input
				type="number"
				step="1"
				min="1"
				class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				bind:value={payload.intervalMin}
			/>
			<span class="font-mono text-[9px] text-on-surface-variant">min</span>
		</label>
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
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.scaleTitle')}
			>
				<input type="checkbox" bind:checked={payload.showScale} class="accent-primary-container" />
				{$_('window.scaleAbbr')}
			</label>
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.siteMarkerTitle')}
			>
				<input
					type="checkbox"
					bind:checked={payload.showSiteMarker}
					class="accent-primary-container"
				/>
				{$_('window.siteMarkerAbbr')}
			</label>
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.cutGuideTitle')}
			>
				<input
					type="checkbox"
					bind:checked={payload.showCutGuide}
					class="accent-primary-container"
				/>
				{$_('window.cutGuideAbbr')}
			</label>
		{/if}

		<div class="ml-auto flex items-center gap-2">
			{#if payload.showScale}
				<ScaleLegend {palette} />
			{/if}
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
		{#if !timeSpan}
			<div class="flex h-full flex-col items-center justify-center gap-3 px-4 text-center">
				<span class="material-symbols-outlined text-[32px] text-on-surface-variant"
					>upload_file</span
				>
				<p class="max-w-xs text-body-sm text-on-surface-variant">
					{$_('window.noTimeSpanAccumulate')}
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
		{:else if result}
			<PpiMap
				bind:this={ppiMapRef}
				scan={result.scan}
				{palette}
				{site}
				baseMap={payload.baseMap}
				dataOpacity={payload.dataOpacity}
				showRings={payload.showRings}
				showRadials={payload.showRadials}
				showSiteMarker={payload.showSiteMarker}
				showCutGuide={payload.showCutGuide}
				extraLayers={overlays}
				{unitSystem}
				drawEnabled={false}
				presetLine={null}
				pointSelectEnabled={false}
				azimuthSelectEnabled={false}
				azimuthDeg={null}
				statsSelectEnabled={false}
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
						: formatReading(readout.value, result?.unit ?? '', unitSystem)}
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
