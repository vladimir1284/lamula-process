<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import type { ChannelRef, GroundProductKind } from '$lib/pipeline';
	import {
		listElevationsDeg,
		deriveGroundProduct,
		deriveOptionsFromMapPayload
	} from '$lib/pipeline';
	import type { Observation, Scan } from '$lib/domain/types';
	import type { PaletteBook, OverlayLineColor } from '$lib/platform';
	import { paletteForMoment } from '$lib/platform';
	import { formatDistanceM, formatReading, type UnitSystem } from '$lib/units';
	import { standardOverlays } from '$lib/overlays';
	import { eastWestLine, northSouthLine } from '$lib/products';
	import { observeContainerSize } from '$lib/viewer/chartCanvas';
	import { BASE_MAP_IDS, BASE_MAP_LABELS } from '$lib/viewer/baseMaps';
	import {
		PpiMap,
		ScaleLegend,
		CrossSectionPanel,
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
	import type { RectangleRegion } from '$lib/analysis';
	import {
		catalogLabel,
		defaultCrossSectionPayload,
		defaultProfilePayload,
		defaultStatsPayload,
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
		/** Seeds the `smooth` field of any cross-section window armed from this map. */
		imageSmoothing: boolean;
		/** Shared line style for rings/radials/grid, live from Settings -- see
		 * `platform/settingsStore.ts`'s `overlayLineColor`/`overlayLineWidthPx`/etc. */
		overlayLineColor: OverlayLineColor;
		overlayLineWidthPx: number;
		ringsStepKm: number;
		radialsStepDeg: number;
		gridStepLatDeg: number;
		gridStepLonDeg: number;
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
		imageSmoothing,
		overlayLineColor,
		overlayLineWidthPx,
		ringsStepKm,
		radialsStepDeg,
		gridStepLatDeg,
		gridStepLonDeg,
		onOpenLocationEditor,
		onShowVad,
		onEditScale
	}: Props = $props();

	let showLinesMenu = $state(false);

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

	// Header info block (hora/fecha/radar/VCP) -- observation.timestamp is the scan's own time
	// (UTC, matching the rest of the app's fixed-UTC display convention), not a live wall clock.
	const timeLabel = $derived(observation ? formatUtcTime(observation.timestamp) : '--:--:--');
	const dateLabel = $derived(observation ? formatUtcDate(observation.timestamp) : '');
	function formatUtcTime(ts: string): string {
		const d = new Date(ts);
		return isNaN(d.getTime()) ? ts : d.toISOString().slice(11, 19);
	}
	function formatUtcDate(ts: string): string {
		const d = new Date(ts);
		return isNaN(d.getTime()) ? '' : d.toISOString().slice(0, 10);
	}

	// Self-healing default: a payload object created before `nsPositionKm`/`ewPositionKm` existed
	// (a stale in-memory window surviving a hot-reload, or a layout JSON exported from an older
	// build) has these fields `undefined`, not `0` -- and `undefined * 1000` is `NaN`, which silently
	// breaks both the cut's data (rasterizeCrossSection samples nowhere) and its guide line (OL
	// can't place a feature at a NaN coordinate, so nothing gets drawn -- looks like "cuts are
	// empty, no guides"). Patch it once per payload instead of scattering `?? 0` at every read site.
	$effect(() => {
		if (payload.nsPositionKm === undefined) payload.nsPositionKm = 0;
		if (payload.ewPositionKm === undefined) payload.ewPositionKm = 0;
	});

	// Optional docked N-S/E-W vertical-section strips (real data, not just a guide line) -- same
	// full-range preset lines the standalone CrossSectionWindow offers, reused inline via
	// CrossSectionPanel so there's no second rendering pipeline for this.
	function maxScanRangeM(scans: Scan[]): number {
		return Math.max(...scans.map((s) => s.rangeToFirstGateM + (s.numGates - 1) * s.gateLengthM));
	}
	const maxRangeKm = $derived(
		channel && channel.scans.length > 0 ? maxScanRangeM(channel.scans) / 1000 : 400
	);

	// The two docked cuts are orthogonal projections of the same volume the map itself is showing --
	// both their SPAN and their CENTRE must track the map's own viewport, or panning/zooming the
	// map and the cuts would disagree about what ground is on screen. `payload.nsPositionKm`/
	// `ewPositionKm` are NOT absolute site-relative coordinates -- they're the user's drag/input
	// offset FROM the viewport's current centre, so panning carries the cut along (its absolute
	// position shifts with the centre) while the offset itself stays put until the user changes it
	// again. `centerEastM`/`centerNorthM`/`groundMPerPx` come from PpiMap's `onViewChange`, fired on
	// 'moveend' (and once synchronously after its render effect's own `.fit()`).
	let mapAreaEl: HTMLDivElement | undefined = $state();
	let mapPxW = $state(0);
	let mapPxH = $state(0);
	let groundMPerPx = $state(0);
	let centerEastM = $state(0);
	let centerNorthM = $state(0);
	$effect(() => {
		const el = mapAreaEl;
		if (!el) return;
		return observeContainerSize(el, (w, h) => {
			mapPxW = w;
			mapPxH = h;
		});
	});
	function onViewChange(v: { groundMPerPx: number; centerEastM: number; centerNorthM: number }) {
		groundMPerPx = v.groundMPerPx;
		centerEastM = v.centerEastM;
		centerNorthM = v.centerNorthM;
	}
	const ewMaxRangeM = $derived(
		groundMPerPx > 0 && mapPxW > 0
			? (mapPxW / 2) * groundMPerPx
			: channel && channel.scans.length > 0
				? maxScanRangeM(channel.scans)
				: 400_000
	);
	const nsMaxRangeM = $derived(
		groundMPerPx > 0 && mapPxH > 0
			? (mapPxH / 2) * groundMPerPx
			: channel && channel.scans.length > 0
				? maxScanRangeM(channel.scans)
				: 400_000
	);
	// Absolute site-relative position of each guide: viewport centre + the user's own offset.
	const absNsPositionM = $derived(centerNorthM + payload.nsPositionKm * 1000);
	const absEwPositionM = $derived(centerEastM + payload.ewPositionKm * 1000);
	const cutLineEW = $derived(
		channel && channel.scans.length > 0 ? eastWestLine(absNsPositionM, ewMaxRangeM) : null
	);
	const cutLineNS = $derived(
		channel && channel.scans.length > 0 ? northSouthLine(absEwPositionM, nsMaxRangeM) : null
	);
	// The drag callback reports the dropped point's ABSOLUTE site-relative position (PpiMap has no
	// notion of "offset from centre") -- subtract the viewport centre to get back the relative
	// offset this payload actually stores. Rounded to 0.1 km so the toolbar input doesn't jitter to
	// long decimals mid-drag.
	function onNsPositionChange(m: number) {
		payload.nsPositionKm = Math.round(((m - centerNorthM) / 1000) * 10) / 10;
	}
	function onEwPositionChange(m: number) {
		payload.ewPositionKm = Math.round(((m - centerEastM) / 1000) * 10) / 10;
	}

	const deriveOpts = $derived(
		deriveOptionsFromMapPayload(payload, channel?.beamWidthDeg ?? 1.0, effectiveSiteAltM)
	);

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
	const armingStats = $derived(windowStore.armedStats === win.id);
	const pickerMode = $derived(
		armingCrossSection
			? 'cross-section'
			: armingProfile
				? 'profile'
				: armingStats
					? 'stats'
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
				payload: { ...defaultCrossSectionPayload(win.id, imageSmoothing), line: l }
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
	function onStatsRegionSelect(r: { minXM: number; minYM: number; maxXM: number; maxYM: number }) {
		const region: RectangleRegion = { kind: 'rectangle', name: '', ...r };
		if (armingStats) {
			windowStore.disarmStats();
			windowStore.open('stats', {
				title: $_('window.statsTitle'),
				payload: { ...defaultStatsPayload(win.id), region }
			});
			return;
		}
		if (activeChild?.type === 'stats') windowStore.setPayload(activeChild.id, { region });
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
	<!-- Header info: hora/fecha, radar, producto, paleta, VCP (in that order, per spec). -->
	<div
		class="flex flex-wrap items-center gap-3 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
	>
		<div class="flex flex-col leading-none">
			<span class="font-mono text-[20px] font-bold text-on-surface">{timeLabel}</span>
			<span class="font-mono text-[10px] text-on-surface-variant">{dateLabel}</span>
		</div>
		{#if observation}
			<span class="flex items-center gap-1 font-mono text-[11px]">
				<span class="text-on-surface-variant">{$_('window.radarLabel')}</span>
				<span class="text-primary-container">{observation.site.name}</span>
			</span>
		{/if}
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
			>{productTitle}</span
		>
		<span class="flex items-center gap-1 font-mono text-[11px]" title={palette.name}>
			<span class="material-symbols-outlined text-[14px] text-primary-container">palette</span>
			<span class="text-on-surface">{palette.name}</span>
			<button
				type="button"
				class="flex h-5 w-5 shrink-0 items-center justify-center rounded text-on-surface-variant hover:text-primary-container"
				onclick={() => onEditScale(paletteKey)}
				aria-label={$_('window.editScale')}
				title={$_('window.editScale')}
			>
				<span class="material-symbols-outlined text-[12px]">edit</span>
			</button>
		</span>
		{#if observation?.design}
			<span class="flex items-center gap-1 font-mono text-[10px]">
				<span class="text-on-surface-variant">{$_('window.vcpLabel')}</span>
				<span
					class="rounded border border-primary-container/30 bg-surface-container-lowest px-1.5 py-0.5 text-primary-container"
					>{observation.design}</span
				>
			</span>
		{/if}
	</div>

	<!-- Toolbar: channel/elevation + per-product params. -->
	<div
		class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
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
	</div>

	{#if site}
		<!-- Overlays: rings, lat/lon grid, radials, scale, site marker, cut guide, cut panels. -->
		<div
			class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
		>
			<div class="relative">
				<button
					type="button"
					class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[10px] text-on-surface-variant hover:border-primary-container hover:text-primary-container"
					onclick={() => (showLinesMenu = !showLinesMenu)}
					aria-haspopup="true"
					aria-expanded={showLinesMenu}
				>
					<span class="material-symbols-outlined text-[14px]">layers</span>
					{$_('window.linesMenu')}
					<span class="material-symbols-outlined text-[14px]">arrow_drop_down</span>
				</button>
				{#if showLinesMenu}
					<ul
						role="menu"
						class="absolute top-full left-0 z-50 mt-1 min-w-40 rounded border border-outline-variant bg-surface-container-high py-1 shadow-lg"
					>
						<li>
							<label
								class="flex items-center gap-2 px-3 py-1.5 font-mono text-[11px] text-on-surface hover:bg-surface-variant/20"
							>
								<input
									type="checkbox"
									bind:checked={payload.showRings}
									class="accent-primary-container"
								/>
								{$_('window.ringsTitle')}
							</label>
						</li>
						<li>
							<label
								class="flex items-center gap-2 px-3 py-1.5 font-mono text-[11px] text-on-surface hover:bg-surface-variant/20"
							>
								<input
									type="checkbox"
									bind:checked={payload.showLatLonGrid}
									class="accent-primary-container"
								/>
								{$_('window.latLonGridTitle')}
							</label>
						</li>
						<li>
							<label
								class="flex items-center gap-2 px-3 py-1.5 font-mono text-[11px] text-on-surface hover:bg-surface-variant/20"
							>
								<input
									type="checkbox"
									bind:checked={payload.showRadials}
									class="accent-primary-container"
								/>
								{$_('window.radialsTitle')}
							</label>
						</li>
					</ul>
				{/if}
			</div>
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
			<label
				class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
				title={$_('window.cutPanelsTitle')}
			>
				<input
					type="checkbox"
					bind:checked={payload.showCutPanels}
					class="accent-primary-container"
				/>
				{$_('window.cutPanelsAbbr')}
			</label>
			{#if payload.showCutPanels}
				<label
					class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
					title={$_('window.nsPositionTitle')}
				>
					<span class="font-mono text-[9px] text-on-surface-variant"
						>{$_('window.readout.nsPosition')}</span
					>
					<input
						type="number"
						step="0.1"
						min={-maxRangeKm}
						max={maxRangeKm}
						class="w-14 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
						bind:value={payload.nsPositionKm}
					/>
					<span class="font-mono text-[9px] text-on-surface-variant">km</span>
				</label>
				<label
					class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
					title={$_('window.ewPositionTitle')}
				>
					<span class="font-mono text-[9px] text-on-surface-variant"
						>{$_('window.readout.ewPosition')}</span
					>
					<input
						type="number"
						step="0.1"
						min={-maxRangeKm}
						max={maxRangeKm}
						class="w-14 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
						bind:value={payload.ewPositionKm}
					/>
					<span class="font-mono text-[9px] text-on-surface-variant">km</span>
				</label>
			{/if}

			<div class="ml-auto flex items-center gap-2">
				{#if payload.showScale}
					<ScaleLegend {palette} unit={ground?.unit} />
				{/if}
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

		<!-- Mapa underlay. -->
		<div
			class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
		>
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
		</div>
	{/if}

	<!-- 2x2 grid: the E-W cut (row 1) shares its column width with the map (row 2, col 1), and the
		N-S cut (col 2) shares its height with the map (col 1) -- a corner filler occupies row
		1/col 2 so the grid tracks stay simple 2x2 rather than an L-shape. This is what makes the
		three views (map + 2 cuts) line up pixel-for-pixel as orthogonal projections of one volume,
		not just three separately-sized panels. Both cuts are grid-only (no axis labels/ticks) --
		there's no room for tick text at this thickness. -->
	<div
		class="relative grid min-h-0 flex-1 overflow-hidden bg-black"
		style="grid-template-columns: 1fr {payload.showCutPanels ? 160 : 0}px; grid-template-rows: {payload.showCutPanels
			? 160
			: 0}px 1fr;"
	>
		{#if payload.showCutPanels && channel && channel.scans.length > 0 && cutLineEW}
			<div class="col-start-1 row-start-1 min-h-0 min-w-0 border-b border-outline-variant">
				<CrossSectionPanel
					scans={channel.scans}
					{palette}
					line={cutLineEW}
					maxHeightM={18000}
					{unitSystem}
					axisLines={false}
					thicknessPx={160}
				/>
			</div>
			<div class="col-start-2 row-start-1 border-b border-l border-outline-variant"></div>
		{/if}
		<div class="relative col-start-1 row-start-2 min-h-0 min-w-0 overflow-hidden" bind:this={mapAreaEl}>
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
					showSiteMarker={payload.showSiteMarker}
					showCutGuide={payload.showCutGuide}
					showLatLonGrid={payload.showLatLonGrid}
					{overlayLineColor}
					{overlayLineWidthPx}
					{ringsStepKm}
					{radialsStepDeg}
					{gridStepLatDeg}
					{gridStepLonDeg}
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
					statsSelectEnabled={pickerMode === 'stats'}
					nsPositionM={payload.showCutPanels ? absNsPositionM : null}
					ewPositionM={payload.showCutPanels ? absEwPositionM : null}
					{onCutLine}
					{onPointSelect}
					{onAzimuthSelect}
					{onStatsRegionSelect}
					{onNsPositionChange}
					{onEwPositionChange}
					{onViewChange}
					onreadout={(r) => (readout = r)}
				/>
			{/if}
		</div>

		{#if payload.showCutPanels && channel && channel.scans.length > 0 && cutLineNS}
			<div class="col-start-2 row-start-2 min-h-0 min-w-0 border-l border-outline-variant">
				<CrossSectionPanel
					scans={channel.scans}
					{palette}
					line={cutLineNS}
					maxHeightM={18000}
					{unitSystem}
					orientation="vertical"
					axisLines={false}
					thicknessPx={160}
				/>
			</div>
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
