<script lang="ts">
	import { onMount, onDestroy, type Snippet } from 'svelte';
	import type { ChannelRef, GroundProductKind } from '$lib/pipeline';
	import {
		listElevationsDeg,
		deriveGroundProduct,
		deriveOptionsFromMapPayload,
		productUsesBeamWidth
	} from '$lib/pipeline';
	import type { Observation, Scan } from '$lib/domain/types';
	import type { PaletteBook, OverlayLineColor } from '$lib/platform';
	import { paletteForMoment } from '$lib/platform';
	import { effectiveBeamWidth } from '$lib/domain';
	import { formatDistanceM, formatReading, type UnitSystem } from '$lib/units';
	import { standardOverlays } from '$lib/overlays';
	import { observeContainerSize } from '$lib/viewer/chartCanvas';
	import { BASE_MAP_IDS, BASE_MAP_LABELS } from '$lib/viewer/baseMaps';
	import {
		PpiMap,
		ScaleLegend,
		CrossSectionPanel,
		WindowNotices,
		exportMapToCanvas,
		downloadCanvasAsPng,
		buildExportFilename,
		drawScaleLegendOverlay
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
		/** Whether the known-sites seed has been merged into this browser's site-data store --
		 * lets the missing-site prompt offer "load known network" instead of just "set location"
		 * when the seed hasn't run yet. */
		knownSitesLoaded: boolean;
		/** Compressed (icons-only)/extended (icons+labels) state of the right-side tool rail --
		 * shared across every open map window (see +page.svelte's `toolRailCollapsed`), same
		 * pattern as the left sidebar's collapse toggle. */
		toolRailCollapsed: boolean;
		onToggleToolRail: () => void;
		onOpenLocationEditor: () => void;
		onLoadKnownSites: () => void;
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
		knownSitesLoaded,
		toolRailCollapsed,
		onToggleToolRail,
		onOpenLocationEditor,
		onLoadKnownSites,
		onShowVad,
		onEditScale
	}: Props = $props();

	// Which rail group's popover is open while the rail is collapsed (icons-only) -- a click
	// outside the rail closes it, same as WindowNotices' own dropdown below. The popover renders
	// as a single shared host positioned `absolute` off `wrapperEl` (this component's own root,
	// not the rail) instead of nested inside the rail's own box -- the rail needs
	// `overflow-y-auto` to scroll a tall control list, and setting overflow on one axis forces the
	// other axis to clip too (CSS spec), so a popover meant to hang off the rail's LEFT edge was
	// silently clipped there. `wrapperEl` also can't be `position:fixed`'s viewport-relative
	// escape hatch either: Window.svelte's own outer chrome is `.glass-panel`
	// (`backdrop-filter: blur(...)`) + `overflow-hidden`, and a `backdrop-filter` ancestor becomes
	// the containing block for `position:fixed` descendants too, re-clipping them right back.
	let openRailGroup = $state<string | null>(null);
	let popoverAnchor = $state<{ top: number; right: number } | null>(null);
	let railEl: HTMLDivElement | undefined = $state();
	let wrapperEl: HTMLDivElement | undefined = $state();
	let popoverEl: HTMLDivElement | undefined = $state();
	function toggleRailGroup(id: string, e: MouseEvent) {
		if (openRailGroup === id) {
			openRailGroup = null;
			return;
		}
		const btnRect = (e.currentTarget as HTMLElement).getBoundingClientRect();
		const wrapRect = wrapperEl?.getBoundingClientRect();
		if (!wrapRect) return;
		popoverAnchor = { top: btnRect.top - wrapRect.top, right: wrapRect.right - btnRect.left + 4 };
		openRailGroup = id;
	}
	function handleRailWindowClick(e: MouseEvent) {
		const target = e.target as Node;
		if (railEl?.contains(target) || popoverEl?.contains(target)) return;
		openRailGroup = null;
	}
	// A popover left open while collapsed would otherwise render as a stray floating panel once
	// the rail expands (the group body already shows inline then) -- close it on every toggle.
	$effect(() => {
		void toolRailCollapsed;
		openRailGroup = null;
	});

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
	const productParamsVisible = $derived(
		payload.product === 'CAPPI' ||
			payload.product === 'TOPS' ||
			payload.product === 'VIL' ||
			payload.product === 'RAIN'
	);

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

	// The two docked cuts are orthogonal projections of the same volume the map itself is showing.
	// `payload.nsPositionKm`/`ewPositionKm` are ABSOLUTE site-relative coordinates (bounded by
	// +-maxRangeKm, the scan's own range) -- ground-fixed, so panning/zooming the map must NOT move
	// them: they have to stay put against the lat/lon grid and the radar data, same as any other
	// ground feature (rings, radials). Only the line's SPAN (how far each strip extends) tracks the
	// viewport, so the strip always fills whatever width/height of ground is currently visible --
	// its centre position along the perpendicular axis never does. `centerEastM`/`centerNorthM`/
	// `groundMPerPx` come from PpiMap's `onViewChange`, used here only to size that span.
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
	// Ground-fixed position of each guide -- never derived from the viewport centre.
	const absNsPositionM = $derived(payload.nsPositionKm * 1000);
	const absEwPositionM = $derived(payload.ewPositionKm * 1000);
	// NOT `eastWestLine`/`northSouthLine` -- those centre the wide axis on the SITE (east/north 0)
	// and use the scan's own max range, which doesn't shrink/grow the strip as you zoom. The docked
	// strip's wide axis instead spans exactly what the map currently shows (`centerEastM`/
	// `centerNorthM` +- half the viewport in ground metres), so it never runs out mid-screen.
	const cutLineEW = $derived(
		channel && channel.scans.length > 0
			? {
					ax: centerEastM - ewMaxRangeM,
					ay: absNsPositionM,
					bx: centerEastM + ewMaxRangeM,
					by: absNsPositionM
				}
			: null
	);
	const cutLineNS = $derived(
		channel && channel.scans.length > 0
			? {
					ax: absEwPositionM,
					ay: centerNorthM - nsMaxRangeM,
					bx: absEwPositionM,
					by: centerNorthM + nsMaxRangeM
				}
			: null
	);
	// MAX-projection mode collapses the ENTIRE perpendicular window instead of sampling at a single
	// offset, so it needs that window's bounds instead of a position. Reuses the same viewport-sized
	// half-ranges the guide lines use, on the OTHER axis: the E-W panel collapses across what's
	// visible north-south, the N-S panel across what's visible east-west.
	const ewMaxProjection = $derived(
		payload.cutMaxProjection
			? { perpMinM: centerNorthM - nsMaxRangeM, perpMaxM: centerNorthM + nsMaxRangeM }
			: undefined
	);
	const nsMaxProjection = $derived(
		payload.cutMaxProjection
			? { perpMinM: centerEastM - ewMaxRangeM, perpMaxM: centerEastM + ewMaxRangeM }
			: undefined
	);
	// The drag callback reports the dropped point's absolute site-relative position directly --
	// that's exactly what the payload stores. Rounded to 0.1 km so the toolbar input doesn't jitter
	// to long decimals mid-drag.
	function onNsPositionChange(m: number) {
		payload.nsPositionKm = Math.round((m / 1000) * 10) / 10;
	}
	function onEwPositionChange(m: number) {
		payload.ewPositionKm = Math.round((m / 1000) * 10) / 10;
	}

	const beamWidth = $derived(effectiveBeamWidth(channel));
	const deriveOpts = $derived(
		deriveOptionsFromMapPayload(payload, beamWidth.deg, effectiveSiteAltM)
	);
	// Only CAPPI/TOPS/MAXS/COLUMN_MAX/VIL bracket by beam height -- warn about the inferred
	// fallback only when the currently-shown product actually depends on it, and always for the
	// docked E-W/N-S cut panels (their coverage wedge depends on it regardless of `payload.product`).
	const notices = $derived(
		beamWidth.inferred &&
			(productUsesBeamWidth(payload.product as GroundProductKind) || payload.showCutPanels)
			? [
					{
						id: 'beam-width-inferred',
						message: $_('window.beamWidthInferredNotice', { values: { value: beamWidth.deg } })
					}
				]
			: []
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
		if (!map) return;
		const canvas = await exportMapToCanvas(map);
		if (payload.showScale) drawScaleLegendOverlay(canvas, palette, ground?.unit);
		downloadCanvasAsPng(canvas, filename);
	}
</script>

<svelte:window onclick={handleRailWindowClick} />

<div class="relative flex h-full flex-col" bind:this={wrapperEl}>
	<div class="flex min-h-0 flex-1 flex-row">
		<div class="flex min-h-0 flex-1 flex-col">
			<!-- 2x2 grid: the E-W cut (row 1) shares its column width with the map (row 2, col 1), and
				the N-S cut (col 2) shares its height with the map (col 1) -- a corner filler occupies
				row 1/col 2 so the grid tracks stay simple 2x2 rather than an L-shape. This is what
				makes the three views (map + 2 cuts) line up pixel-for-pixel as orthogonal projections
				of one volume, not just three separately-sized panels. Both cuts are grid-only (no axis
				labels/ticks) -- there's no room for tick text at this thickness. -->
			<div
				class="relative grid min-h-0 flex-1 overflow-hidden bg-black"
				style="grid-template-columns: 1fr {payload.showCutPanels
					? 160
					: 0}px; grid-template-rows: {payload.showCutPanels ? 160 : 0}px 1fr;"
			>
				{#if payload.showCutPanels && channel && channel.scans.length > 0 && cutLineEW}
					<div class="col-start-1 row-start-1 min-h-0 min-w-0 border-b border-outline-variant">
						<CrossSectionPanel
							scans={channel.scans}
							{palette}
							line={cutLineEW}
							maxHeightM={18000}
							siteAltM={effectiveSiteAltM}
							beamWidthDeg={beamWidth.deg}
							{unitSystem}
							axisLines={false}
							thicknessPx={160}
							smooth={true}
							maxProjection={ewMaxProjection}
							interactive={false}
						/>
					</div>
					<div class="col-start-2 row-start-1 border-b border-l border-outline-variant"></div>
				{/if}
				<div
					class="relative col-start-1 row-start-2 min-h-0 min-w-0 overflow-hidden"
					bind:this={mapAreaEl}
				>
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
							<span class="material-symbols-outlined text-[32px] text-dbz-heavy"
								>wrong_location</span
							>
							<p class="max-w-xs text-body-sm text-on-surface-variant">
								{$_('window.noSitePosition')}
								<span class="text-on-surface">{productTitle}</span>.
							</p>
							<div class="flex gap-2">
								{#if !knownSitesLoaded}
									<button
										class="flex h-9 items-center gap-2 rounded bg-primary-container px-3 font-mono text-[11px] text-on-primary-container transition-all hover:opacity-90 active:scale-95"
										onclick={onLoadKnownSites}
									>
										<span class="material-symbols-outlined text-[16px]">public</span>
										{$_('settings.sites.loadKnown')}
									</button>
								{/if}
								<button
									class={[
										'flex h-9 items-center gap-2 rounded px-3 font-mono text-[11px] transition-all active:scale-95',
										knownSitesLoaded
											? 'bg-primary-container text-on-primary-container hover:opacity-90'
											: 'border border-outline-variant text-on-surface hover:border-primary-container'
									]}
									onclick={onOpenLocationEditor}
								>
									<span class="material-symbols-outlined text-[16px]">add_location_alt</span>
									{$_('window.defineLocation')}
								</button>
							</div>
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
							nsPositionM={payload.showCutPanels && !payload.cutMaxProjection
								? absNsPositionM
								: null}
							ewPositionM={payload.showCutPanels && !payload.cutMaxProjection
								? absEwPositionM
								: null}
							{onCutLine}
							{onPointSelect}
							{onAzimuthSelect}
							{onStatsRegionSelect}
							{onNsPositionChange}
							{onEwPositionChange}
							{onViewChange}
							onreadout={(r) => (readout = r)}
						/>
						<!-- Legend/palette chip: bottom-right overlay on the map itself, not the toolbar --
							toggled by the rail's dedicated legend icon (`railToggle` above), hidden by
							default. -->
						{#if payload.showScale}
							<div
								class="absolute right-2 bottom-2 z-10 flex items-center gap-2 rounded border border-outline-variant bg-surface-container-high/90 px-2 py-1 backdrop-blur-sm"
							>
								<ScaleLegend {palette} unit={ground?.unit} />
								<button
									type="button"
									class="flex h-5 w-5 shrink-0 items-center justify-center rounded text-on-surface-variant hover:text-primary-container"
									onclick={() => onEditScale(paletteKey)}
									aria-label={$_('window.editScale')}
									title={$_('window.editScale')}
								>
									<span class="material-symbols-outlined text-[12px]">edit</span>
								</button>
							</div>
						{/if}
					{/if}
				</div>

				{#if payload.showCutPanels && channel && channel.scans.length > 0 && cutLineNS}
					<div class="col-start-2 row-start-2 min-h-0 min-w-0 border-l border-outline-variant">
						<CrossSectionPanel
							scans={channel.scans}
							{palette}
							line={cutLineNS}
							maxHeightM={18000}
							siteAltM={effectiveSiteAltM}
							beamWidthDeg={beamWidth.deg}
							{unitSystem}
							orientation="vertical"
							axisLines={false}
							thicknessPx={160}
							smooth={true}
							maxProjection={nsMaxProjection}
							interactive={false}
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

		<!-- Tool rail: channel/elevation/product params/overlays/base map/export -- every control
			that used to live in three stacked horizontal toolbars above the map. Collapsed = icons
			only, each group's controls in a flyout popover; expanded = icons+labels with the
			controls shown inline. Toggle is shared across all open map windows (see
			+page.svelte's toolRailCollapsed/onToggleToolRail). -->
		<div
			bind:this={railEl}
			class={`flex shrink-0 flex-col gap-0.5 overflow-y-auto border-l border-outline-variant bg-surface-container-high py-2 transition-[width] ${
				toolRailCollapsed ? 'w-rail-collapsed-width items-center px-1' : 'w-rail-width px-2'
			}`}
		>
			<button
				type="button"
				class="mb-1 flex h-7 w-7 shrink-0 items-center justify-center self-end rounded text-on-surface-variant hover:bg-surface-variant/30 hover:text-primary-container"
				onclick={onToggleToolRail}
				aria-label={toolRailCollapsed ? $_('sidebar.expandPanel') : $_('sidebar.collapsePanel')}
				title={toolRailCollapsed ? $_('sidebar.expandPanel') : $_('sidebar.collapsePanel')}
			>
				<span class="material-symbols-outlined text-[16px]"
					>{toolRailCollapsed ? 'chevron_left' : 'chevron_right'}</span
				>
			</button>

			{@render railGroup('channel', 'sensors', $_('window.readout.channel'), channelBody)}
			{#if productParamsVisible}
				{@render railGroup('params', 'calculate', $_('window.productParamsTitle'), paramsBody)}
			{/if}
			{#if payload.product === 'WIND_SPEED'}
				{@render railButton('air', 'VAD', () => onShowVad(payload.channelIndex))}
			{/if}
			{#if site}
				{@render railGroup('overlays', 'layers', $_('window.linesMenu'), overlaysBody)}
				{@render railGroup('basemap', 'map', $_('window.baseMapTitle'), basemapBody)}
				{@render railToggle(
					'palette',
					$_('window.legendToggle'),
					payload.showScale,
					() => (payload.showScale = !payload.showScale)
				)}
				{@render railButton('download', $_('window.exportImage'), exportCurrentImage)}
			{/if}

			<div class={toolRailCollapsed ? '' : 'w-full'}>
				<WindowNotices {notices} />
			</div>
		</div>
	</div>

	<!-- Shared popover host for the collapsed rail's flyouts -- a single instance (not one per
		group, only one is ever open) positioned off `wrapperEl` rather than nested inside the
		rail's own `overflow-y-auto`/`railGroup` markup; see the comment on `openRailGroup` above
		for why. -->
	{#if toolRailCollapsed && openRailGroup && popoverAnchor}
		<div
			bind:this={popoverEl}
			class="absolute z-50 min-w-52 space-y-1 rounded border border-outline-variant bg-surface-container-high p-2 shadow-lg"
			style="top:{popoverAnchor.top}px; right:{popoverAnchor.right}px"
		>
			{#if openRailGroup === 'channel'}
				{@render channelBody()}
			{:else if openRailGroup === 'params'}
				{@render paramsBody()}
			{:else if openRailGroup === 'overlays'}
				{@render overlaysBody()}
			{:else if openRailGroup === 'basemap'}
				{@render basemapBody()}
			{/if}
		</div>
	{/if}
</div>

{#snippet channelBody()}
	<label
		class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
	>
		<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.channel')}</span>
		<select
			class="min-w-0 flex-1 border-none bg-transparent p-0 font-mono text-[11px] text-on-surface focus:ring-0"
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
				class="min-w-0 flex-1 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				bind:value={payload.elevationDeg}
			>
				{#each elevations as e (e)}
					<option value={e}>{e.toFixed(1)}°</option>
				{/each}
			</select>
		</label>
	{/if}
{/snippet}

{#snippet paramsBody()}
	{#if payload.product === 'CAPPI'}
		<label
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.base')}</span>
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
			<span class="font-mono text-[9px] text-on-surface-variant">{$_('window.readout.base')}</span>
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
{/snippet}

{#snippet overlaysBody()}
	<label
		class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
	>
		<input type="checkbox" bind:checked={payload.showRings} class="accent-primary-container" />
		{$_('window.ringsTitle')}
	</label>
	<label
		class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
	>
		<input type="checkbox" bind:checked={payload.showLatLonGrid} class="accent-primary-container" />
		{$_('window.latLonGridTitle')}
	</label>
	<label
		class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
	>
		<input type="checkbox" bind:checked={payload.showRadials} class="accent-primary-container" />
		{$_('window.radialsTitle')}
	</label>
	<label
		class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
		title={$_('window.siteMarkerTitle')}
	>
		<input type="checkbox" bind:checked={payload.showSiteMarker} class="accent-primary-container" />
		{$_('window.siteMarkerAbbr')}
	</label>
	<label
		class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
		title={$_('window.cutGuideTitle')}
	>
		<input type="checkbox" bind:checked={payload.showCutGuide} class="accent-primary-container" />
		{$_('window.cutGuideAbbr')}
	</label>
	<label
		class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
		title={$_('window.cutPanelsTitle')}
	>
		<input type="checkbox" bind:checked={payload.showCutPanels} class="accent-primary-container" />
		{$_('window.cutPanelsAbbr')}
	</label>
	{#if payload.showCutPanels}
		<label
			class="flex items-center gap-2 py-1 font-mono text-[11px] text-on-surface hover:text-primary-container"
			title={$_('window.cutMaxProjectionTitle')}
		>
			<input
				type="checkbox"
				bind:checked={payload.cutMaxProjection}
				class="accent-primary-container"
			/>
			{$_('window.cutMaxProjectionAbbr')}
		</label>
		{#if !payload.cutMaxProjection}
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
	{/if}
{/snippet}

{#snippet basemapBody()}
	<label
		class="flex h-7 items-center gap-1 font-mono text-[10px] text-on-surface-variant"
		title={$_('window.baseMapTitle')}
	>
		<span class="material-symbols-outlined text-[14px] text-primary-container">map</span>
		<select
			bind:value={payload.baseMap}
			class="min-w-0 flex-1 rounded border border-outline-variant bg-surface-container-lowest px-1 text-on-surface focus:border-primary-container focus:outline-none"
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
			class="h-1 flex-1 accent-primary-container"
		/>
	</label>
{/snippet}

{#snippet railGroup(id: string, icon: string, label: string, body: Snippet)}
	<div class="relative w-full">
		<button
			type="button"
			class={`flex h-8 w-full items-center gap-2 rounded px-2 font-mono text-[11px] transition-colors hover:bg-surface-variant/30 hover:text-primary-container ${
				toolRailCollapsed ? 'justify-center' : ''
			} ${openRailGroup === id ? 'bg-surface-variant/30 text-primary-container' : 'text-on-surface-variant'}`}
			onclick={(e) => toolRailCollapsed && toggleRailGroup(id, e)}
			aria-haspopup={toolRailCollapsed}
			aria-expanded={toolRailCollapsed ? openRailGroup === id : true}
			title={label}
		>
			<span class="material-symbols-outlined shrink-0 text-[16px]">{icon}</span>
			{#if !toolRailCollapsed}<span class="truncate">{label}</span>{/if}
		</button>
		{#if !toolRailCollapsed}
			<div class="mt-0.5 mb-1 space-y-1 pl-1">
				{@render body()}
			</div>
		{/if}
	</div>
{/snippet}

{#snippet railButton(icon: string, label: string, action: () => void)}
	<button
		type="button"
		class={`flex h-8 w-full items-center gap-2 rounded px-2 font-mono text-[11px] text-on-surface-variant transition-colors hover:bg-surface-variant/30 hover:text-primary-container ${
			toolRailCollapsed ? 'justify-center' : ''
		}`}
		onclick={action}
		aria-label={label}
		title={label}
	>
		<span class="material-symbols-outlined shrink-0 text-[16px]">{icon}</span>
		{#if !toolRailCollapsed}<span class="truncate">{label}</span>{/if}
	</button>
{/snippet}

{#snippet railToggle(icon: string, label: string, checked: boolean, onToggle: () => void)}
	<button
		type="button"
		role="checkbox"
		aria-checked={checked}
		class={`flex h-8 w-full items-center gap-2 rounded px-2 font-mono text-[11px] transition-colors hover:bg-surface-variant/30 ${
			toolRailCollapsed ? 'justify-center' : ''
		} ${checked ? 'bg-primary-container/20 text-primary-container' : 'text-on-surface-variant'}`}
		onclick={onToggle}
		aria-label={label}
		title={label}
	>
		<span class="material-symbols-outlined shrink-0 text-[16px]">{icon}</span>
		{#if !toolRailCollapsed}<span class="truncate">{label}</span>{/if}
	</button>
{/snippet}
