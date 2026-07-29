<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { useMachine } from '@xstate/svelte';
	import { observationMachine } from '$lib/pipeline/observationMachine';
	import {
		observationChannels,
		listElevationsDeg,
		hasGeoref,
		deriveGroundProduct,
		type GroundProductKind,
		type DeriveOptions
	} from '$lib/pipeline';
	import {
		eastWestLine,
		northSouthLine,
		computeProfile,
		volumeToRhiScan,
		type CutLine
	} from '$lib/products';
	import type { Palette, ProductPaletteKey } from '$lib/palette/types';
	import type { Scan, MomentType } from '$lib/domain/types';
	import { momentUnit } from '$lib/domain';
	import { formatDistanceM, formatAltitudeM, formatReading } from '$lib/units';
	import {
		PpiMap,
		RhiPanel,
		CrossSectionPanel,
		ProfilePanel,
		VadModal,
		ScaleEditor,
		ScaleLegend,
		Modal,
		SiteLocationEditor,
		exportMapToCanvas,
		flattenOnBlack,
		downloadCanvasAsPng,
		buildExportFilename,
		composeSideBySide
	} from '$lib/viewer';
	import { computeVadProfile } from '$lib/products/vadProfile';
	import AwsExplorer from '$lib/aws-explorer/AwsExplorer.svelte';
	import { MenuBar, type MenuDef } from '$lib/nav';
	import { loadConfig, type RecentFileEntry } from '$lib/platform';
	import { standardOverlays } from '$lib/overlays';
	import { BASE_MAP_IDS, BASE_MAP_LABELS, type BaseMapId } from '$lib/viewer/baseMaps';
	import type { Readout } from '$lib/viewer/readout';
	import type { RhiReadout } from '$lib/render/rasterizeRHI';
	import type { CrossSectionReadout } from '$lib/viewer/CrossSectionPanel.svelte';
	import {
		siteKey,
		getSiteLocation,
		setSiteLocation,
		deleteSiteLocation,
		loadSiteData,
		exportSiteData,
		importSiteData,
		loadKnownSitesSeed,
		type SiteDataStore,
		type PaletteBook,
		seedPaletteBook,
		loadPaletteBook,
		savePaletteBook,
		paletteForMoment,
		upsertPalette,
		assignMomentPalette,
		exportPaletteBook,
		importPaletteBook,
		type AppSettings,
		DEFAULT_SETTINGS,
		loadSettings,
		saveSettings
	} from '$lib/platform';

	// Every moment the app can decode, for the settings assignment UI (domain/types.ts MomentType).
	const MOMENTS: MomentType[] = ['dBZ', 'dBuZ', 'V', 'W', 'ZDR', 'uPhiDP', 'RhoHV'];
	// Ground products whose physical unit differs from any moment (palette/types.ts
	// ProductPaletteKey), so they get their own settings assignment row instead of following the
	// channel's moment.
	const PRODUCT_PALETTE_KEYS: { key: ProductPaletteKey; label: string }[] = [
		{ key: 'TOPS_HEIGHT', label: 'Topes / Alt. máx.' },
		{ key: 'VIL', label: 'VIL' },
		{ key: 'RAIN', label: 'Lluvia' },
		{ key: 'WIND_SPEED', label: 'Viento' }
	];

	// Which palette-book key a given product's scan is colored with: ground products that report a
	// different physical quantity than the channel's moment (echo tops/column-max height, VIL,
	// rain rate, wind speed) get their own key; everything else (PPI/CAPPI/COLUMN_MAX and the
	// cross-section/profile/RHI panels, which all show the raw moment) follows the moment.
	function paletteKeyFor(p: ProductKind, moment: MomentType): string {
		switch (p) {
			case 'TOPS':
			case 'MAXS_HEIGHT':
				return 'TOPS_HEIGHT';
			case 'VIL':
				return 'VIL';
			case 'RAIN':
				return 'RAIN';
			case 'WIND_SPEED':
				return 'WIND_SPEED';
			default:
				return moment;
		}
	}

	const { snapshot, send } = useMachine(observationMachine);

	// Products that render on the georeferenced PPI map (single ground-range scan).
	const GROUND_KINDS: GroundProductKind[] = [
		'PPI',
		'CAPPI',
		'TOPS',
		'MAXS_HEIGHT',
		'COLUMN_MAX',
		'VIL',
		'RAIN',
		'WIND_SPEED'
	];
	type ProductKind = GroundProductKind | 'CROSS_LINE' | 'PROFILE' | 'RHI';

	// Sidebar catalog — mirrors the optgroups the app has always exposed.
	const PRODUCT_GROUPS: {
		label: string;
		items: { id: ProductKind; label: string; icon: string }[];
	}[] = [
		{
			label: 'Base',
			items: [
				{ id: 'PPI', label: 'PPI', icon: 'storm' },
				{ id: 'CAPPI', label: 'CAPPI', icon: 'layers' }
			]
		},
		{
			label: 'Columna',
			items: [
				{ id: 'TOPS', label: 'Topes (echo tops)', icon: 'cloud_upload' },
				{ id: 'MAXS_HEIGHT', label: 'Altura del máximo', icon: 'height' },
				{ id: 'COLUMN_MAX', label: 'Máximo de columna', icon: 'stacked_line_chart' },
				{ id: 'VIL', label: 'VIL', icon: 'opacity' }
			]
		},
		{
			label: 'Precip. y viento',
			items: [
				{ id: 'RAIN', label: 'Tasa de lluvia (Z-R)', icon: 'rainy' },
				{ id: 'WIND_SPEED', label: 'Viento (VAD)', icon: 'air' }
			]
		},
		{
			label: 'Cortes',
			items: [
				{ id: 'CROSS_LINE', label: 'Corte (línea libre)', icon: 'timeline' },
				{ id: 'PROFILE', label: 'Perfil vertical', icon: 'monitoring' },
				{ id: 'RHI', label: 'RHI', icon: 'radar' }
			]
		}
	];

	let product = $state<ProductKind>('PPI');
	let channelIndex = $state(0);
	let elevationDeg = $state(0.5);
	// product parameters
	let cappiBottomKm = $state(1);
	let cappiTopKm = $state(3);
	let topsMinDbz = $state(18);
	let vilBottomKm = $state(0);
	let vilTopKm = $state(15);
	let vilC1 = $state(0.00524);
	let vilC2 = $state(0.57143);
	let zrA = $state(300);
	let zrB = $state(1.4);
	let maxHeightKm = $state(18);
	let profilePoint = $state<{ xEastM: number; yNorthM: number } | null>(null);
	let rhiAzimuthDeg = $state(0);
	let drawnCutLine = $state<CutLine | null>(null);
	let crossLineReadout = $state<CrossSectionReadout | null>(null);

	// Per-variable palette group, persisted + configurable (platform/paletteStore.ts). Seeded
	// synchronously so the first paint has colors; the stored/edited book loads in onMount.
	let book = $state<PaletteBook>(seedPaletteBook());
	let readout = $state<Readout | RhiReadout | null>(null);
	let siteOverride = $state<{ lat: number; lon: number; altM: number } | null>(null);
	let showScaleEditor = $state(false);
	let showSettings = $state(false);
	let showAwsExplorer = $state(false);
	let showVadModal = $state(false);

	const vadProfile = $derived.by(() => {
		if (!channel || channel.scans.length === 0) return null;
		return computeVadProfile(channel, {}, effectiveSite?.altM ?? 0);
	});

	// App-wide settings (platform/settingsStore.ts): unit system + default base map, persisted in
	// localStorage. Seeded synchronously with the defaults so the first paint is consistent; the
	// stored/edited values load in onMount, same pattern as `book` above.
	let settings = $state<AppSettings>({ ...DEFAULT_SETTINGS });
	const unitSystem = $derived(settings.unitSystem);
	let settingsLoaded = false;
	async function updateSettings(patch: Partial<AppSettings>) {
		settings = { ...untrack(() => settings), ...patch };
		await saveSettings(settings);
	}
	// Settings modal: which section is active, and (for "Sitios") which saved site is being
	// edited -- reusing SiteLocationEditor for both the header's "editar ubicación" shortcut and
	// the general site-data management, so there's a single settings entry point, not two.
	let settingsTab = $state<'unidades' | 'sitios' | 'paletas'>('unidades');
	let editingSiteKey = $state<string | null>(null);
	let siteList = $state<SiteDataStore>({});
	async function refreshSiteList() {
		siteList = await loadSiteData();
	}

	// Background map + radar (data) layer opacity for the PPI viewer. `baseMap` mirrors
	// `settings.baseMap` for the <select> binding below, and is persisted back on change.
	let baseMap = $state<BaseMapId>(DEFAULT_SETTINGS.baseMap);
	let dataOpacity = $state(0.8);
	let showRings = $state(DEFAULT_SETTINGS.showRings);
	let showRadials = $state(DEFAULT_SETTINGS.showRadials);
	$effect(() => {
		const bm = baseMap;
		if (!settingsLoaded) return;
		untrack(() => void updateSettings({ baseMap: bm }));
	});
	$effect(() => {
		const sr = showRings;
		if (!settingsLoaded) return;
		untrack(() => void updateSettings({ showRings: sr }));
	});
	$effect(() => {
		const sr = showRadials;
		if (!settingsLoaded) return;
		untrack(() => void updateSettings({ showRadials: sr }));
	});

	// Refs to the currently-mounted view, for "export image" (only one of these is non-null at a
	// time, mirroring the {#if}/{:else if} chain that mounts them).
	let ppiMapRef: ReturnType<typeof PpiMap> | undefined = $state();
	let rhiPanelRef: ReturnType<typeof RhiPanel> | undefined = $state();
	let crossSectionRef: ReturnType<typeof CrossSectionPanel> | undefined = $state();
	let profileRef: ReturnType<typeof ProfilePanel> | undefined = $state();

	const observation = $derived($snapshot.context.observation);
	const loading = $derived($snapshot.value === 'opening' || $snapshot.value === 'parsing');
	const error = $derived($snapshot.context.error);
	const recentFiles = $derived($snapshot.context.recentFiles);

	function reopenRecent(entry: RecentFileEntry) {
		send({ type: 'OPEN_RECENT', entry });
	}

	const menus = $derived<MenuDef[]>([
		{
			label: 'Archivo',
			items: [
				{
					label: loading ? 'Abriendo…' : 'Abrir archivo',
					icon: 'upload_file',
					disabled: loading,
					onclick: () => send({ type: 'OPEN' })
				},
				{
					label: 'Descargar (AWS)',
					icon: 'cloud_download',
					disabled: loading,
					onclick: () => (showAwsExplorer = true)
				},
				{
					label: 'Abrir reciente',
					icon: 'history',
					submenu:
						recentFiles.length > 0
							? recentFiles.map((entry) => ({
									label: entry.label,
									icon: entry.source === 'aws' ? 'cloud' : 'description',
									onclick: () => reopenRecent(entry)
								}))
							: [{ label: 'Sin archivos recientes', disabled: true }]
				}
			]
		}
	]);

	const channels = $derived(observation ? observationChannels(observation) : []);
	const channel = $derived(channels[channelIndex]?.channel);
	// Active palette follows the selected product: the channel's moment for PPI/CAPPI/COLUMN_MAX
	// and the cross-section/profile/RHI panels, or a dedicated product key for ground products
	// that report a different physical quantity (tops, VIL, rain rate, wind speed) -- see
	// `paletteKeyFor`.
	const paletteKey = $derived(paletteKeyFor(product, channel?.moment ?? 'dBZ'));
	const palette = $derived(paletteForMoment(book, paletteKey));
	const elevations = $derived(channel ? listElevationsDeg(channel) : []);
	const georef = $derived(observation ? hasGeoref(observation) : false);

	// Formats that don't self-describe site position (NEXRAD L2, .obs) may have a
	// previously-saved location for this site code -- load it once per new observation.
	let siteLookupToken = 0;
	$effect(() => {
		const obs = observation;
		siteOverride = null;
		if (!obs || hasGeoref(obs)) return;
		const token = ++siteLookupToken;
		getSiteLocation(siteKey(obs.site)).then((loc) => {
			if (token !== siteLookupToken || !loc) return; // superseded by a newer file
			siteOverride = { lat: loc.lat, lon: loc.lon, altM: loc.altM };
		});
	});

	// Site position as carried by the parser, falling back to a user-entered/saved override
	// for formats that don't self-describe it (NEXRAD L2, .obs).
	const effectiveSite = $derived.by(() => {
		if (!observation) return null;
		if (observation.site.lat !== undefined && observation.site.lon !== undefined) {
			return { lat: observation.site.lat, lon: observation.site.lon, altM: observation.site.altM };
		}
		return siteOverride;
	});

	const isGround = $derived(GROUND_KINDS.includes(product as GroundProductKind));
	// Products that use a standalone canvas panel (no georeferencing required).
	const usesElevation = $derived(
		product === 'PPI' || product === 'RAIN' || product === 'WIND_SPEED'
	);
	const productTitle = $derived(
		PRODUCT_GROUPS.flatMap((g) => g.items).find((i) => i.id === product)?.label ?? product
	);

	function maxRangeM(ch: NonNullable<typeof channel>): number {
		return Math.max(...ch.scans.map((s) => s.rangeToFirstGateM + (s.numGates - 1) * s.gateLengthM));
	}

	const deriveOpts = $derived<DeriveOptions>({
		elevationDeg,
		beamWidthDeg: channel?.beamWidthDeg ?? 1.0,
		siteAltM: effectiveSite?.altM ?? 0,
		cappiBottomM: cappiBottomKm * 1000,
		cappiTopM: cappiTopKm * 1000,
		topsMinDbz,
		vilBottomM: vilBottomKm * 1000,
		vilTopM: vilTopKm * 1000,
		vilC1,
		vilC2,
		zrA,
		zrB
	});

	// Ground-product scan + unit for the map path.
	const ground = $derived.by((): { scan: Scan; unit: string } | null => {
		if (!channel || channel.scans.length === 0 || !isGround) return null;
		return deriveGroundProduct(channel, product as GroundProductKind, deriveOpts);
	});

	const rhiScan = $derived.by((): Scan | null => {
		if (product !== 'RHI' || !channel || channel.scans.length === 0) return null;
		return volumeToRhiScan(channel.scans, rhiAzimuthDeg);
	});
	// Column-max composite as the plan-view reference for the azimuth picker: the radial always
	// lands on real echo regardless of which tilt holds it (vs. the lowest sweep, whose footprint
	// can differ a lot from the rest of a deep VCP).
	const rhiBaseScan = $derived.by((): Scan | null => {
		if (product !== 'RHI' || !channel || channel.scans.length === 0) return null;
		return deriveGroundProduct(channel, 'COLUMN_MAX', deriveOpts).scan;
	});

	// Draws the full-range E-W / N-S preset lines for the free-line cut tool (through the site,
	// spanning the loaded volume's max range on each side) -- shortcuts for tracing, not separate
	// products.
	function presetCutLine(orientation: 'EW' | 'NS'): CutLine | null {
		if (!channel) return null;
		const half = maxRangeM(channel);
		return orientation === 'EW' ? eastWestLine(0, half) : northSouthLine(0, half);
	}

	// Free-hand cut: a column-max composite as the plan-view background to draw the line on (same
	// reasoning as rhiBaseScan -- always shows real echo regardless of which tilt holds it).
	const crossLineBaseScan = $derived.by((): Scan | null => {
		if (product !== 'CROSS_LINE' || !channel || channel.scans.length === 0) return null;
		return deriveGroundProduct(channel, 'COLUMN_MAX', deriveOpts).scan;
	});

	// Drop the drawn line whenever the user leaves the CROSS_LINE tool, so coming back starts fresh.
	$effect(() => {
		if (product !== 'CROSS_LINE') {
			drawnCutLine = null;
			crossLineReadout = null;
		}
	});

	// Same reasoning as crossLineBaseScan: a column-max composite as the plan-view background to
	// pick the profile point on.
	const profileBaseScan = $derived.by((): Scan | null => {
		if (product !== 'PROFILE' || !channel || channel.scans.length === 0) return null;
		return deriveGroundProduct(channel, 'COLUMN_MAX', deriveOpts).scan;
	});

	// Drop the picked point whenever the user leaves the PROFILE tool, so coming back starts fresh.
	$effect(() => {
		if (product !== 'PROFILE') {
			profilePoint = null;
		}
	});

	const profile = $derived.by(() => {
		if (!channel || product !== 'PROFILE' || !profilePoint) return null;
		return computeProfile(channel.scans, {
			xEastM: profilePoint.xEastM,
			yNorthM: profilePoint.yNorthM,
			beamWidthDeg: channel.beamWidthDeg ?? 1.0,
			topM: maxHeightKm * 1000,
			siteAltM: effectiveSite?.altM ?? 0
		});
	});

	const site = $derived(effectiveSite ? { lon: effectiveSite.lon, lat: effectiveSite.lat } : null);

	const overlays = standardOverlays();

	function fmt(n: number | null | undefined, digits = 1): string {
		return n === null || n === undefined ? '—' : n.toFixed(digits);
	}

	// Opens Configuración straight to the "editar ubicación" form for the current file's site
	// (single settings entry point -- no separate location-editor modal).
	function openLocationEditor() {
		editingSiteKey = observation ? siteKey(observation.site) : null;
		settingsTab = 'sitios';
		showSettings = true;
	}
	function cancelSiteEdit() {
		editingSiteKey = null;
	}
	async function saveSiteLocation(loc: { lat: number; lon: number; altM: number }) {
		const key = editingSiteKey;
		editingSiteKey = null;
		if (!key) return;
		if (observation && siteKey(observation.site) === key) siteOverride = loc;
		await setSiteLocation(key, loc);
		await refreshSiteList();
	}
	async function removeSiteLocation(key: string) {
		if (editingSiteKey === key) editingSiteKey = null;
		await deleteSiteLocation(key);
		await refreshSiteList();
	}

	async function exportSiteDataFile() {
		const store = await loadSiteData();
		const blob = new Blob([exportSiteData(store)], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = 'site_data.json';
		a.click();
		URL.revokeObjectURL(url);
	}

	async function importSiteDataFile(e: Event) {
		const input = e.currentTarget as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		await importSiteData(await file.text());
		input.value = '';
		await refreshSiteList();
		if (observation && !hasGeoref(observation)) {
			const loc = await getSiteLocation(siteKey(observation.site));
			if (loc) siteOverride = { lat: loc.lat, lon: loc.lon, altM: loc.altM };
		}
	}

	async function loadKnownSites() {
		await loadKnownSitesSeed();
		await refreshSiteList();
		if (observation && !hasGeoref(observation)) {
			const loc = await getSiteLocation(siteKey(observation.site));
			if (loc) siteOverride = { lat: loc.lat, lon: loc.lon, altM: loc.altM };
		}
	}

	onMount(async () => {
		book = await loadPaletteBook();
		settings = await loadSettings();
		baseMap = settings.baseMap;
		showRings = settings.showRings;
		showRadials = settings.showRadials;
		settingsLoaded = true;
		await refreshSiteList();
		const config = await loadConfig();
		send({ type: 'RECENT_FILES_LOADED', recentFiles: config.recentFiles });
	});

	// The scale editor edits the palette assigned to the active key (current moment or product).
	// Persist the edit and keep the key pointed at it (so a rename doesn't detach the assignment
	// from the edited palette).
	function onPaletteChange(edited: Palette) {
		book = assignMomentPalette(upsertPalette(book, edited), paletteKey, edited.name);
		void savePaletteBook(book);
	}

	function onAssign(key: string, paletteName: string) {
		book = assignMomentPalette(book, key, paletteName);
		void savePaletteBook(book);
	}

	function downloadPaletteBook() {
		const blob = new Blob([exportPaletteBook(book)], { type: 'application/json' });
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = 'palettes.json';
		a.click();
		URL.revokeObjectURL(url);
	}

	async function onImportPaletteBook(event: Event) {
		const input = event.target as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		book = await importPaletteBook(await file.text());
		input.value = '';
	}

	// Split-view products (RHI/cross-section/profile) show a map picker alongside the product
	// plot, each an independently-refed canvas -- 'both' composites map+plot side by side,
	// 'product' exports just the plot. Ground products only ever have the map, so mode is moot.
	const isSplitProduct = $derived(
		product === 'RHI' || product === 'CROSS_LINE' || product === 'PROFILE'
	);
	let showExportMenu = $state(false);

	async function exportCurrentImage(mode: 'both' | 'product' = 'product') {
		const nameParts = [
			observation?.site.name,
			observation?.timestamp,
			product,
			channel?.moment,
			product === 'RHI' ? `az${rhiAzimuthDeg}` : usesElevation ? `el${elevationDeg}` : undefined,
			mode === 'both' ? 'ambos' : undefined
		];
		const filename = buildExportFilename(nameParts);

		let panelRef: { getCanvas: () => HTMLCanvasElement | undefined } | undefined;
		if (product === 'RHI') panelRef = rhiPanelRef;
		else if (product === 'CROSS_LINE') panelRef = crossSectionRef;
		else if (product === 'PROFILE') panelRef = profileRef;

		if (panelRef) {
			const canvas = panelRef.getCanvas();
			if (!canvas) return;
			if (mode === 'both') {
				const map = ppiMapRef?.getMap();
				if (map) {
					const mapCanvas = await exportMapToCanvas(map);
					downloadCanvasAsPng(composeSideBySide(mapCanvas, flattenOnBlack(canvas)), filename);
					return;
				}
			}
			downloadCanvasAsPng(flattenOnBlack(canvas), filename);
		} else if (isGround) {
			const map = ppiMapRef?.getMap();
			if (map) downloadCanvasAsPng(await exportMapToCanvas(map), filename);
		}
	}
</script>

<div
	class="radar-grid-bg flex h-screen flex-col overflow-hidden bg-surface-container-lowest text-on-surface"
>
	<!-- ── TopAppBar ─────────────────────────────────────────────────────────── -->
	<header
		class="fixed top-0 right-0 left-0 z-50 flex h-16 items-center justify-between border-b border-outline-variant bg-surface-container px-margin-desktop"
	>
		<div class="flex items-center gap-6">
			<h1 class="flex items-center gap-2 font-headline text-headline-md font-bold text-primary">
				<img src="/logo.svg" alt="" class="h-7 w-7" />
				LAMULA <span class="font-normal text-on-surface-variant">Process</span>
			</h1>
			<MenuBar {menus} />
			{#if observation}
				<nav class="hidden items-center gap-5 font-mono text-label-mono lg:flex">
					<span class="flex items-center gap-2"
						><span class="text-on-surface-variant">SITIO</span><span class="text-primary"
							>{observation.site.name}</span
						></span
					>
					<span class="text-outline-variant">·</span>
					<span class="flex items-center gap-2"
						><span class="text-on-surface-variant">FECHA</span><span class="text-on-surface"
							>{observation.timestamp}</span
						></span
					>
					<span class="text-outline-variant">·</span>
					<span
						class="rounded border border-primary-container/30 bg-surface-container-high px-2 py-0.5 text-primary-container"
						>{observation.design}</span
					>
					{#if !georef && effectiveSite}
						<span class="text-outline-variant">·</span>
						<button
							class="flex items-center gap-1 text-primary-container transition-opacity hover:opacity-80"
							onclick={openLocationEditor}
						>
							<span class="material-symbols-outlined text-[16px]">edit_location</span> Editar ubicación
						</button>
					{/if}
				</nav>
			{/if}
		</div>
		<div class="flex items-center gap-3">
			<button
				class="flex h-10 w-10 items-center justify-center rounded border border-outline-variant text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
				onclick={() => (showSettings = true)}
				aria-label="Configuración"
				title="Configuración"
			>
				<span class="material-symbols-outlined text-[20px]">settings</span>
			</button>
		</div>
	</header>

	<!-- ── SideNavBar: channel + elevation + product catalog ─────────────────── -->
	<aside
		class="fixed top-0 left-0 z-40 flex h-full w-sidebar-width flex-col overflow-y-auto border-r border-outline-variant bg-surface-container-low pt-16"
	>
		<div class="space-y-5 p-4">
			{#if observation}
				<div class="grid grid-cols-1 gap-3">
					<label class="flex flex-col gap-1">
						<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
							>Canal</span
						>
						<div
							class="cyan-glow flex h-9 items-center rounded border border-outline-variant bg-surface-container-high px-3"
						>
							<select
								class="w-full cursor-pointer border-none bg-transparent p-0 font-mono text-label-mono text-on-surface focus:ring-0"
								bind:value={channelIndex}
							>
								{#each channels as ref (ref.index)}
									<option value={ref.index}
										>{ref.channel.moment} ({ref.channel.scans.length})</option
									>
								{/each}
							</select>
						</div>
					</label>

					{#if usesElevation}
						<label class="flex flex-col gap-1">
							<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
								>Elevación</span
							>
							<div
								class="cyan-glow flex h-9 items-center rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<select
									class="w-full cursor-pointer border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={elevationDeg}
								>
									{#each elevations as e (e)}
										<option value={e}>{e.toFixed(1)}°</option>
									{/each}
								</select>
							</div>
						</label>
					{/if}
				</div>
			{/if}

			<div>
				<p class="mb-2 px-1 font-mono text-[10px] tracking-widest text-outline uppercase">
					Producto
				</p>
				<div class="space-y-3 font-mono text-label-mono">
					{#each PRODUCT_GROUPS as group (group.label)}
						<div>
							<p class="mb-1 px-1 text-[10px] tracking-wider text-on-surface-variant/60 uppercase">
								{group.label}
							</p>
							{#each group.items as item (item.id)}
								<div>
									<button
										type="button"
										class="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left transition-all {product ===
										item.id
											? 'border-l-4 border-primary bg-primary-container text-on-primary-container'
											: 'text-on-surface-variant hover:bg-surface-variant'}"
										onclick={() => (product = item.id)}
									>
										<span
											class="material-symbols-outlined text-[18px]"
											style={product === item.id ? "font-variation-settings:'FILL' 1;" : ''}
											>{item.icon}</span
										>
										{item.label}
										{#if product === item.id && ground}
											<span
												class="ml-auto rounded bg-on-primary-container px-1.5 py-0.5 font-mono text-[9px] tracking-widest text-dbz-mod uppercase"
												>{ground.unit}</span
											>
										{/if}
									</button>

									{#if product === item.id}
										<div class="flex flex-col gap-2 py-2 pl-4">
											{#if item.id === 'CAPPI'}
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>BASE</span
													>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={cappiBottomKm}
														step="0.5"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">km</span>
												</label>
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>TOPE</span
													>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={cappiTopKm}
														step="0.5"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">km</span>
												</label>
											{/if}

											{#if item.id === 'TOPS'}
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>UMBRAL</span
													>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={topsMinDbz}
														step="1"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">dBZ</span>
												</label>
											{/if}

											{#if item.id === 'VIL'}
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>BASE</span
													>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={vilBottomKm}
														step="0.5"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">km</span>
												</label>
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>TOPE</span
													>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={vilTopKm}
														step="0.5"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">km</span>
												</label>
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant">C1</span>
													<input
														type="number"
														class="w-20 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={vilC1}
														step="0.0001"
													/>
												</label>
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant">C2</span>
													<input
														type="number"
														class="w-20 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={vilC2}
														step="0.0001"
													/>
												</label>
											{/if}

											{#if item.id === 'RAIN'}
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>Z-R A</span
													>
													<input
														type="number"
														class="w-16 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={zrA}
														step="10"
													/>
												</label>
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>Z-R B</span
													>
													<input
														type="number"
														class="w-16 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={zrB}
														step="0.1"
													/>
												</label>
											{/if}

											{#if item.id === 'RHI'}
												<label
													class="cyan-glow flex h-9 items-center gap-3 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>AZIMUT</span
													>
													<input
														type="range"
														class="w-full"
														bind:value={rhiAzimuthDeg}
														min="0"
														max="359"
														step="1"
													/>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={rhiAzimuthDeg}
														min="0"
														max="359"
														step="1"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">°</span>
												</label>
												<p class="px-1 font-mono text-[10px] text-on-surface-variant">
													Haz clic en el mapa para marcar el azimut, o usa el control de arriba.
												</p>
											{/if}

											{#if item.id === 'PROFILE'}
												<p class="px-1 font-mono text-[10px] text-on-surface-variant">
													{profilePoint
														? 'Punto marcado.'
														: 'Haz clic en el mapa para marcar el punto del perfil.'}
												</p>
												{#if profilePoint}
													<button
														type="button"
														class="flex h-8 items-center justify-center gap-2 rounded border border-outline-variant bg-surface-container-high font-mono text-[11px] text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
														onclick={() => (profilePoint = null)}
													>
														<span class="material-symbols-outlined text-[14px]">restart_alt</span> Rehacer
														punto
													</button>
												{/if}
											{/if}

											{#if item.id === 'CROSS_LINE'}
												<p class="px-1 font-mono text-[10px] text-on-surface-variant">
													{drawnCutLine
														? 'Línea trazada.'
														: 'Haz clic en el mapa para marcar 2 puntos, o usa un comodín.'}
												</p>
												<div class="flex gap-2 px-1">
													<button
														type="button"
														class="flex h-8 flex-1 items-center justify-center gap-2 rounded border border-outline-variant bg-surface-container-high font-mono text-[11px] text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
														disabled={!channel}
														onclick={() => {
															drawnCutLine = presetCutLine('EW');
															crossLineReadout = null;
														}}
													>
														<span class="material-symbols-outlined text-[14px]">swap_horiz</span> Este-Oeste
													</button>
													<button
														type="button"
														class="flex h-8 flex-1 items-center justify-center gap-2 rounded border border-outline-variant bg-surface-container-high font-mono text-[11px] text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
														disabled={!channel}
														onclick={() => {
															drawnCutLine = presetCutLine('NS');
															crossLineReadout = null;
														}}
													>
														<span class="material-symbols-outlined text-[14px]">swap_vert</span> Norte-Sur
													</button>
												</div>
												{#if drawnCutLine}
													<button
														type="button"
														class="flex h-8 items-center justify-center gap-2 rounded border border-outline-variant bg-surface-container-high font-mono text-[11px] text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
														onclick={() => {
															drawnCutLine = null;
															crossLineReadout = null;
														}}
													>
														<span class="material-symbols-outlined text-[14px]">restart_alt</span> Rehacer
														línea
													</button>
												{/if}
											{/if}

											{#if item.id === 'CROSS_LINE' || item.id === 'PROFILE' || item.id === 'RHI'}
												<label
													class="cyan-glow flex h-9 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
												>
													<span class="w-12 font-mono text-[11px] text-on-surface-variant"
														>ALT MÁX</span
													>
													<input
														type="number"
														class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
														bind:value={maxHeightKm}
														step="1"
													/>
													<span class="font-mono text-[11px] text-on-surface-variant">km</span>
												</label>
											{/if}
										</div>
									{/if}
								</div>
							{/each}
						</div>
					{/each}
				</div>
			</div>
		</div>
	</aside>

	<!-- ── Main ──────────────────────────────────────────────────────────────── -->
	<main class="flex min-h-0 flex-1 flex-col pt-16 pl-sidebar-width">
		<div class="flex min-h-0 flex-1 flex-col space-y-gutter p-margin-desktop">
			{#if error}
				<div
					class="flex items-center gap-3 rounded-xl border border-error/40 bg-error-container/20 px-4 py-3 font-mono text-label-mono text-error"
				>
					<span class="material-symbols-outlined text-[18px]">error</span>
					{error}
				</div>
			{/if}

			{#if !observation}
				<!-- Empty state: no observation open. -->
				<div
					class="glass-panel flex min-h-0 flex-1 flex-col items-center justify-center gap-5 rounded-xl px-6 text-center"
				>
					<img src="/logo.svg" alt="Lamula" class="h-[96px] w-[96px]" />
					<div>
						<h2 class="font-headline text-headline-md text-on-surface">Abre una observación</h2>
						<p class="mt-1 text-body-sm text-on-surface-variant">
							Formatos: INSMET .obs · NEXRAD Level II · Rainbow5 .vol
						</p>
					</div>
					<button
						class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
						onclick={() => send({ type: 'OPEN' })}
						disabled={loading}
					>
						<span class="material-symbols-outlined text-[18px]">upload_file</span>
						{loading ? 'ABRIENDO…' : 'ABRIR ARCHIVO'}
					</button>
					<button
						class="flex h-10 items-center gap-2 rounded border border-outline-variant px-4 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container hover:text-primary-container disabled:opacity-50"
						onclick={() => (showAwsExplorer = true)}
						disabled={loading}
					>
						<span class="material-symbols-outlined text-[18px]">cloud_download</span>
						DESCARGAR (AWS)
					</button>
				</div>
			{:else}
				<!-- Viewer hero (full width; scale = legend in header, editing via modal). -->
				<div class="flex min-h-0 flex-1 flex-col">
					<section
						class="glass-panel flex min-h-0 flex-1 flex-col overflow-hidden rounded-xl border-primary-container/30 shadow-[0_0_24px_rgba(0,240,255,0.05)]"
					>
						<div
							class="flex items-center gap-4 border-b border-outline-variant bg-surface-container-high px-4 py-2.5"
						>
							<span
								class="flex shrink-0 items-center gap-2 font-mono text-label-mono tracking-tight text-on-surface-variant uppercase"
								><span class="material-symbols-outlined text-[18px] text-primary-container"
									>my_location</span
								>
								Visor · {productTitle}</span
							>
							<div class="ml-auto flex items-center gap-3">
								{#if isGround && site}
									<!-- Background map selector. -->
									<label
										class="flex shrink-0 items-center gap-1.5 font-mono text-label-mono text-on-surface-variant"
										title="Mapa de fondo"
									>
										<span class="material-symbols-outlined text-[16px] text-primary-container"
											>map</span
										>
										<select
											bind:value={baseMap}
											class="rounded border border-outline-variant bg-surface-container-high px-1.5 py-1 text-on-surface focus:border-primary-container focus:outline-none"
										>
											<option value="off">{BASE_MAP_LABELS.off}</option>
											{#each BASE_MAP_IDS as id (id)}
												<option value={id}>{BASE_MAP_LABELS[id]}</option>
											{/each}
										</select>
									</label>
									<!-- Radar (data) layer opacity. -->
									<label
										class="flex shrink-0 items-center gap-1.5 font-mono text-label-mono text-on-surface-variant"
										title="Opacidad de la capa de datos"
									>
										<span class="material-symbols-outlined text-[16px] text-primary-container"
											>opacity</span
										>
										<input
											type="range"
											min="0"
											max="1"
											step="0.05"
											bind:value={dataOpacity}
											class="h-1 w-24 accent-primary-container"
										/>
										<span class="w-8 text-right text-on-surface"
											>{Math.round(dataOpacity * 100)}%</span
										>
									</label>
									<!-- Range-ring / azimuth-radial overlay toggles. -->
									<label
										class="flex shrink-0 items-center gap-1 font-mono text-label-mono text-on-surface-variant"
										title="Círculos de distancia"
									>
										<input
											type="checkbox"
											bind:checked={showRings}
											class="accent-primary-container"
										/>
										ANILLOS
									</label>
									<label
										class="flex shrink-0 items-center gap-1 font-mono text-label-mono text-on-surface-variant"
										title="Marcas radiales (acimut)"
									>
										<input
											type="checkbox"
											bind:checked={showRadials}
											class="accent-primary-container"
										/>
										RADIALES
									</label>
								{/if}
								<ScaleLegend {palette} />
								{#if isSplitProduct}
									<div class="relative">
										<button
											class="flex shrink-0 items-center rounded border border-outline-variant bg-surface-container-high p-1 text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
											onclick={() => (showExportMenu = !showExportMenu)}
											aria-haspopup="true"
											aria-expanded={showExportMenu}
											aria-label="Exportar imagen"
											title="Exportar imagen"
										>
											<span class="material-symbols-outlined text-[16px]">download</span>
										</button>
										{#if showExportMenu}
											<ul
												role="menu"
												class="absolute top-full right-0 z-50 mt-1 min-w-52 rounded border border-outline-variant bg-surface-container-high py-1 shadow-lg"
											>
												<li>
													<button
														class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-label-mono text-on-surface transition-colors hover:bg-surface-variant/20"
														onclick={() => {
															showExportMenu = false;
															exportCurrentImage('both');
														}}
													>
														<span class="material-symbols-outlined text-[16px]">view_column_2</span>
														Ambos paneles
													</button>
												</li>
												<li>
													<button
														class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-label-mono text-on-surface transition-colors hover:bg-surface-variant/20"
														onclick={() => {
															showExportMenu = false;
															exportCurrentImage('product');
														}}
													>
														<span class="material-symbols-outlined text-[16px]">image</span>
														Solo producto
													</button>
												</li>
											</ul>
										{/if}
									</div>
								{:else}
									<button
										class="flex shrink-0 items-center rounded border border-outline-variant bg-surface-container-high p-1 text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
										onclick={() => exportCurrentImage('product')}
										aria-label="Exportar imagen"
										title="Exportar imagen"
									>
										<span class="material-symbols-outlined text-[16px]">download</span>
									</button>
								{/if}
								<button
									class="flex shrink-0 items-center rounded border border-outline-variant bg-surface-container-high p-1 text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
									onclick={() => (showScaleEditor = true)}
									aria-label="Editar escala"
									title="Editar escala"
								>
									<span class="material-symbols-outlined text-[16px]">palette</span>
								</button>
							</div>
						</div>

						<div class="relative min-h-0 flex-1 overflow-auto bg-black">
							{#if product === 'RHI'}
								{#if !site}
									<div
										class="flex h-full flex-col items-center justify-center gap-4 px-6 text-center"
									>
										<span class="material-symbols-outlined text-[40px] text-dbz-heavy"
											>wrong_location</span
										>
										<p class="max-w-md text-body-sm text-on-surface-variant">
											El azimut del RHI se marca sobre el mapa y necesita la posición del sitio.
											Define la ubicación.
										</p>
										<button
											class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95"
											onclick={openLocationEditor}
										>
											<span class="material-symbols-outlined text-[18px]">add_location_alt</span> DEFINIR
											UBICACIÓN
										</button>
									</div>
								{:else if rhiBaseScan && rhiScan}
									<div class="flex h-full gap-3 p-3">
										<!-- Left: map to pick the RHI azimuth on. -->
										<div class="flex min-w-0 flex-1 flex-col gap-1">
											<p class="font-mono text-[10px] text-on-surface-variant">
												Fondo: máximo de columna. Haz clic para marcar el azimut del RHI.
											</p>
											<div
												class="min-h-0 flex-1 overflow-hidden rounded border border-outline-variant"
											>
												<PpiMap
													scan={rhiBaseScan}
													{palette}
													{site}
													{baseMap}
													{dataOpacity}
													{showRings}
													{showRadials}
													extraLayers={overlays}
													azimuthSelectEnabled={true}
													azimuthDeg={rhiAzimuthDeg}
													{unitSystem}
													onAzimuthSelect={(a) => (rhiAzimuthDeg = a)}
													onreadout={(r) => (readout = r)}
												/>
											</div>
										</div>

										<!-- Right: the RHI itself. -->
										<div class="flex min-w-0 flex-1 flex-col gap-1">
											<p class="font-mono text-[10px] text-on-surface-variant">
												RHI reconstruido del volumen al azimut {rhiAzimuthDeg}°: un rayo por
												elevación ({rhiScan.numRays}
												tumbos). La resolución vertical la limita el número de elevaciones.
											</p>
											<div
												class="flex min-h-0 flex-1 flex-col justify-center overflow-hidden rounded border border-outline-variant bg-surface-container-lowest"
											>
												<RhiPanel
													bind:this={rhiPanelRef}
													scan={rhiScan}
													{palette}
													maxHeightM={maxHeightKm * 1000}
													{unitSystem}
													onreadout={(r) => (readout = r)}
												/>
											</div>
										</div>
									</div>
								{/if}
							{:else if product === 'CROSS_LINE'}
								{#if !site}
									<div
										class="flex h-full flex-col items-center justify-center gap-4 px-6 text-center"
									>
										<span class="material-symbols-outlined text-[40px] text-dbz-heavy"
											>wrong_location</span
										>
										<p class="max-w-md text-body-sm text-on-surface-variant">
											El corte de línea libre se traza sobre el mapa y necesita la posición del
											sitio. Define la ubicación para poder trazar el corte.
										</p>
										<button
											class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95"
											onclick={openLocationEditor}
										>
											<span class="material-symbols-outlined text-[18px]">add_location_alt</span> DEFINIR
											UBICACIÓN
										</button>
									</div>
								{:else if crossLineBaseScan && channel}
									<div class="flex h-full gap-3 p-3">
										<!-- Left: map to trace the cut on. -->
										<div class="flex min-w-0 flex-1 flex-col gap-1">
											<p class="font-mono text-[10px] text-on-surface-variant">
												Fondo: máximo de columna. Haz clic para el punto <span
													class="text-[#22c55e]">A (inicio)</span
												>
												y otro para <span class="text-[#ef4444]">B (fin)</span> del corte.
											</p>
											<div
												class="min-h-0 flex-1 overflow-hidden rounded border border-outline-variant"
											>
												<PpiMap
													scan={crossLineBaseScan}
													{palette}
													{site}
													{baseMap}
													{dataOpacity}
													{showRings}
													{showRadials}
													extraLayers={overlays}
													drawEnabled={true}
													presetLine={drawnCutLine}
													{unitSystem}
													onCutLine={(l) => (drawnCutLine = l)}
													onreadout={(r) => (readout = r)}
												/>
											</div>
										</div>

										<!-- Right: the vertical cut itself, in its own panel. -->
										<div class="flex min-w-0 flex-1 flex-col gap-1">
											<p class="font-mono text-[10px] text-on-surface-variant">
												Corte vertical de <span class="text-[#22c55e]">A</span> a
												<span class="text-[#ef4444]">B</span> (muestreo inverso por píxel).
											</p>
											<div
												class="flex min-h-0 flex-1 flex-col justify-center overflow-hidden rounded border border-outline-variant bg-surface-container-lowest"
											>
												{#if drawnCutLine}
													<CrossSectionPanel
														bind:this={crossSectionRef}
														scans={channel.scans}
														{palette}
														line={drawnCutLine}
														maxHeightM={maxHeightKm * 1000}
														markEndpoints={true}
														{unitSystem}
														onreadout={(r) => (crossLineReadout = r)}
													/>
												{:else}
													<p class="px-4 text-center font-mono text-[10px] text-on-surface-variant">
														Traza una línea en el mapa de la izquierda para ver el corte vertical.
													</p>
												{/if}
											</div>

											<!-- Dedicated readout for this panel, mirroring the map's bottom bar. -->
											<div
												class="grid grid-cols-3 gap-px border border-outline-variant bg-surface-container-low font-mono"
											>
												{#if crossLineReadout}
													<div class="bg-surface-container-low p-2">
														<p class="mb-0.5 text-label-caps text-on-surface-variant">
															DISTANCIA (A→B)
														</p>
														<p class="text-label-mono text-on-surface">
															{formatDistanceM(crossLineReadout.distanceM, unitSystem)}
														</p>
													</div>
													<div class="bg-surface-container-low p-2">
														<p class="mb-0.5 text-label-caps text-on-surface-variant">ALTURA</p>
														<p class="text-label-mono text-on-surface">
															{formatAltitudeM(crossLineReadout.heightM, unitSystem)}
														</p>
													</div>
													<div class="bg-surface-container-low p-2">
														<p class="mb-0.5 text-label-caps text-on-surface-variant">VALOR</p>
														<p class="text-label-mono text-dbz-heavy">
															{crossLineReadout.sample?.value == null
																? '—'
																: formatReading(
																		crossLineReadout.sample.value,
																		momentUnit(channel?.moment ?? 'dBZ'),
																		unitSystem
																	)}
														</p>
													</div>
												{:else}
													<div class="col-span-3 bg-surface-container-low p-2">
														<p class="text-label-mono text-on-surface-variant">
															Pasa el cursor sobre el corte para leer valores.
														</p>
													</div>
												{/if}
											</div>
										</div>
									</div>
								{/if}
							{:else if product === 'PROFILE'}
								{#if !site}
									<div
										class="flex h-full flex-col items-center justify-center gap-4 px-6 text-center"
									>
										<span class="material-symbols-outlined text-[40px] text-dbz-heavy"
											>wrong_location</span
										>
										<p class="max-w-md text-body-sm text-on-surface-variant">
											El perfil vertical se marca sobre el mapa y necesita la posición del sitio.
											Define la ubicación.
										</p>
										<button
											class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95"
											onclick={openLocationEditor}
										>
											<span class="material-symbols-outlined text-[18px]">add_location_alt</span> DEFINIR
											UBICACIÓN
										</button>
									</div>
								{:else if profileBaseScan && channel}
									<div class="flex h-full gap-3 p-3">
										<!-- Left: map to pick the profile point on. -->
										<div class="flex min-w-0 flex-1 flex-col gap-1">
											<p class="font-mono text-[10px] text-on-surface-variant">
												Fondo: máximo de columna. Haz clic para marcar el punto del perfil.
											</p>
											<div
												class="min-h-0 flex-1 overflow-hidden rounded border border-outline-variant"
											>
												<PpiMap
													scan={profileBaseScan}
													{palette}
													{site}
													{baseMap}
													{dataOpacity}
													{showRings}
													{showRadials}
													extraLayers={overlays}
													pointSelectEnabled={true}
													{unitSystem}
													onPointSelect={(p) => (profilePoint = p)}
													onreadout={(r) => (readout = r)}
												/>
											</div>
										</div>

										<!-- Right: the vertical profile itself. -->
										<div class="flex min-w-0 flex-1 flex-col gap-1">
											<p class="font-mono text-[10px] text-on-surface-variant">
												Perfil vertical en el punto marcado: una muestra por elevación, interpolada
												por spline cúbico.
											</p>
											<div
												class="flex min-h-0 flex-1 flex-col justify-center overflow-hidden rounded border border-outline-variant bg-surface-container-lowest"
											>
												{#if profile}
													<ProfilePanel
														bind:this={profileRef}
														{profile}
														valueLabel={channel?.moment ?? 'dBZ'}
													/>
												{:else}
													<p class="px-4 text-center font-mono text-[10px] text-on-surface-variant">
														Haz clic en el mapa de la izquierda para ver el perfil vertical.
													</p>
												{/if}
											</div>
										</div>
									</div>
								{/if}
							{:else if isGround}
								{#if !site}
									<!-- Format without a site position (e.g. NEXRAD L2 msg-31). -->
									<div
										class="flex h-full flex-col items-center justify-center gap-4 px-6 text-center"
									>
										<span class="material-symbols-outlined text-[40px] text-dbz-heavy"
											>wrong_location</span
										>
										<p class="max-w-md text-body-sm text-on-surface-variant">
											Este formato no trae posición del sitio (p. ej. NEXRAD L2 msg-31). Define la
											ubicación para georreferenciar el <span class="text-on-surface"
												>{productTitle}</span
											>. Cortes, perfil y RHI también la necesitan (se trazan sobre el mapa).
										</p>
										<button
											class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95"
											onclick={openLocationEditor}
										>
											<span class="material-symbols-outlined text-[18px]">add_location_alt</span> DEFINIR
											UBICACIÓN
										</button>
									</div>
								{:else if ground}
									<div class="relative h-full w-full">
										{#if product === 'WIND_SPEED'}
											<div class="absolute top-3 right-3 z-30">
												<button
													class="flex items-center gap-2 rounded-lg border border-primary-container/60 bg-surface-container-high/90 px-3 py-2 font-mono text-label-mono text-primary-container shadow-xl backdrop-blur-md transition-all hover:bg-primary-container hover:text-on-primary-container active:scale-95"
													onclick={() => (showVadModal = true)}
												>
													<span class="material-symbols-outlined text-[20px]">air</span>
													VER PERFIL DE VIENTO VAD (MODAL)
												</button>
											</div>
										{/if}
										<PpiMap
											bind:this={ppiMapRef}
											scan={ground.scan}
											{palette}
											{site}
											{baseMap}
											{dataOpacity}
											{showRings}
											{showRadials}
											extraLayers={overlays}
											{unitSystem}
											onreadout={(r) => (readout = r)}
										/>
									</div>
								{/if}
							{/if}
						</div>

						<!-- Readout bar. -->
						<div
							class="grid grid-cols-2 gap-px border-t border-outline-variant bg-surface-container-low font-mono sm:grid-cols-3 lg:grid-cols-6"
						>
							{#if readout && 'azimuthDeg' in readout}
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">LAT</p>
									<p class="text-label-mono text-on-surface">{fmt(readout.lat, 4)}°</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">LON</p>
									<p class="text-label-mono text-on-surface">{fmt(readout.lon, 4)}°</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">AZIMUT</p>
									<p class="text-label-mono text-primary-container">{fmt(readout.azimuthDeg)}°</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">RANGO</p>
									<p class="text-label-mono text-on-surface">
										{formatDistanceM(readout.rangeM, unitSystem)}
									</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">VALOR</p>
									<p class="text-label-mono text-dbz-heavy">
										{readout.value === null
											? '—'
											: formatReading(readout.value, ground?.unit ?? '', unitSystem)}
									</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">ESTADO</p>
									<p class="text-label-mono text-on-surface">
										{readout.flag && readout.flag !== 'ok' ? readout.flag : 'ok'}
									</p>
								</div>
							{:else if readout && 'heightM' in readout}
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">RANGO</p>
									<p class="text-label-mono text-on-surface">
										{formatDistanceM(readout.rangeM, unitSystem)}
									</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">ALTURA</p>
									<p class="text-label-mono text-on-surface">
										{formatAltitudeM(readout.heightM, unitSystem)}
									</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">VALOR</p>
									<p class="text-label-mono text-dbz-heavy">
										{readout.value === null
											? '—'
											: formatReading(
													readout.value,
													momentUnit(channel?.moment ?? 'dBZ'),
													unitSystem
												)}
									</p>
								</div>
								<div class="bg-surface-container-low p-3"></div>
							{:else}
								<div class="col-span-2 bg-surface-container-low p-3 sm:col-span-3 lg:col-span-6">
									<p class="text-label-mono text-on-surface-variant">
										Pasa el cursor sobre el visor para leer valores.
									</p>
								</div>
							{/if}
						</div>
					</section>
				</div>
			{/if}
		</div>
	</main>

	<Modal
		open={showAwsExplorer}
		title="Descargar observación (AWS)"
		onclose={() => (showAwsExplorer = false)}
	>
		<AwsExplorer
			{unitSystem}
			onload={(picked) => {
				showAwsExplorer = false;
				send({ type: 'LOAD_REMOTE', picked: { ...picked, source: 'aws' } });
			}}
		/>
	</Modal>

	<Modal open={showScaleEditor} title="Editor de escala" onclose={() => (showScaleEditor = false)}>
		<div class="p-4">
			<ScaleEditor {palette} onchange={onPaletteChange} />
		</div>
	</Modal>

	<Modal
		open={showSettings}
		title="Configuración"
		onclose={() => {
			showSettings = false;
			editingSiteKey = null;
		}}
	>
		<div class="flex flex-col gap-4">
			<!-- Section tabs. -->
			<div class="flex gap-1 border-b border-outline-variant font-mono text-label-mono uppercase">
				{#each [{ id: 'unidades', label: 'Unidades', icon: 'straighten' }, { id: 'sitios', label: 'Sitios', icon: 'pin_drop' }, { id: 'paletas', label: 'Paletas', icon: 'palette' }] as tab (tab.id)}
					<button
						class="flex items-center gap-1.5 border-b-2 px-3 py-2 transition-colors {settingsTab ===
						tab.id
							? 'border-primary-container text-primary-container'
							: 'border-transparent text-on-surface-variant hover:text-on-surface'}"
						onclick={() => (settingsTab = tab.id as typeof settingsTab)}
					>
						<span class="material-symbols-outlined text-[16px]">{tab.icon}</span>
						{tab.label}
					</button>
				{/each}
			</div>

			{#if settingsTab === 'unidades'}
				<div class="space-y-3">
					<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
						Sistema de unidades
					</h3>
					<p class="font-mono text-[10px] text-on-surface-variant">
						Afecta anillos de rango, ejes de corte/RHI, distancia a sitio (descarga AWS) y las
						lecturas de viento/lluvia al pasar el cursor. Los umbrales de paletas y las
						coordenadas/altura guardadas de sitio siguen en unidades métricas internamente.
					</p>
					<div class="flex gap-2">
						<button
							class="flex items-center gap-2 rounded border px-4 py-2 font-mono text-label-mono transition-colors {unitSystem ===
							'metric'
								? 'border-primary-container bg-primary-container text-on-primary-container'
								: 'border-outline-variant bg-surface-container-high text-on-surface-variant hover:border-primary-container'}"
							onclick={() => updateSettings({ unitSystem: 'metric' })}
						>
							Métrico (km, m/s, mm)
						</button>
						<button
							class="flex items-center gap-2 rounded border px-4 py-2 font-mono text-label-mono transition-colors {unitSystem ===
							'imperial'
								? 'border-primary-container bg-primary-container text-on-primary-container'
								: 'border-outline-variant bg-surface-container-high text-on-surface-variant hover:border-primary-container'}"
							onclick={() => updateSettings({ unitSystem: 'imperial' })}
						>
							Imperial (mi, mph, in)
						</button>
					</div>
				</div>
			{:else if settingsTab === 'sitios'}
				<div class="space-y-4">
					{#if editingSiteKey}
						<div class="flex items-center justify-between">
							<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
								Editar: {editingSiteKey}
							</h3>
							<button
								class="font-mono text-[10px] text-on-surface-variant hover:text-primary-container"
								onclick={cancelSiteEdit}
							>
								← Volver a la lista
							</button>
						</div>
						<SiteLocationEditor
							initial={siteList[editingSiteKey] ?? siteOverride ?? undefined}
							onsave={saveSiteLocation}
							oncancel={cancelSiteEdit}
						/>
					{:else}
						<div>
							<h3 class="mb-1 font-mono text-label-mono tracking-widest text-on-surface uppercase">
								Ubicaciones de sitio guardadas
							</h3>
							<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
								Posición usada para los formatos que no traen su propia georreferencia (NEXRAD L2,
								.obs), guardada por código de sitio.
							</p>
							{#if Object.keys(siteList).length > 0}
								<ul class="mb-3 divide-y divide-outline-variant/30 font-mono text-label-mono">
									{#each Object.entries(siteList) as [key, loc] (key)}
										<li class="flex items-center gap-3 py-2">
											<span class="w-20 shrink-0 text-on-surface">{key}</span>
											<span class="flex-1 text-[11px] text-on-surface-variant">
												{fmt(loc.lat, 4)}°, {fmt(loc.lon, 4)}° · {formatAltitudeM(
													loc.altM,
													unitSystem
												)}
											</span>
											<button
												class="text-on-surface-variant transition-colors hover:text-primary-container"
												aria-label="Editar {key}"
												title="Editar"
												onclick={() => (editingSiteKey = key)}
											>
												<span class="material-symbols-outlined text-[16px]">edit</span>
											</button>
											<button
												class="text-on-surface-variant transition-colors hover:text-dbz-heavy"
												aria-label="Eliminar {key}"
												title="Eliminar"
												onclick={() => removeSiteLocation(key)}
											>
												<span class="material-symbols-outlined text-[16px]">delete</span>
											</button>
										</li>
									{/each}
								</ul>
							{:else}
								<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
									Sin ubicaciones guardadas todavía.
								</p>
							{/if}
							<div class="flex flex-wrap gap-2 border-t border-outline-variant pt-4">
								<button
									class="flex items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container"
									onclick={exportSiteDataFile}
								>
									<span class="material-symbols-outlined text-[16px]">download</span> Exportar
								</button>
								<label
									class="flex cursor-pointer items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container"
								>
									<span class="material-symbols-outlined text-[16px]">upload</span> Importar
									<input
										type="file"
										accept="application/json"
										class="hidden"
										onchange={importSiteDataFile}
									/>
								</label>
								<button
									class="flex items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container"
									onclick={loadKnownSites}
								>
									<span class="material-symbols-outlined text-[16px]">public</span> Cargar red conocida
								</button>
							</div>
						</div>
					{/if}
				</div>
			{:else if settingsTab === 'paletas'}
				<div class="space-y-5">
					<div>
						<h3 class="mb-1 font-mono text-label-mono tracking-widest text-on-surface uppercase">
							Paletas por variable
						</h3>
						<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
							Cada variable se dibuja con la paleta asignada. Edita los colores con el ícono de
							paleta sobre el visor; aquí eliges qué paleta usa cada variable.
						</p>
						<div class="grid grid-cols-1 gap-2">
							{#each MOMENTS as m (m)}
								<label class="flex items-center gap-3">
									<span class="w-20 shrink-0 font-mono text-label-mono text-on-surface-variant"
										>{m}</span
									>
									<div
										class="flex h-9 flex-1 items-center rounded border border-outline-variant bg-surface-container-high px-3"
									>
										<select
											class="w-full cursor-pointer border-none bg-transparent p-0 font-mono text-label-mono text-on-surface focus:ring-0"
											value={book.assignments[m]}
											onchange={(e) => onAssign(m, (e.currentTarget as HTMLSelectElement).value)}
										>
											{#each book.palettes as p (p.name)}
												<option value={p.name}>{p.name}</option>
											{/each}
										</select>
									</div>
								</label>
							{/each}
						</div>
					</div>

					<div>
						<h3 class="mb-1 font-mono text-label-mono tracking-widest text-on-surface uppercase">
							Paletas por producto
						</h3>
						<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
							Topes, VIL, lluvia y viento tienen su propia unidad física y no usan la paleta de la
							variable de origen.
						</p>
						<div class="grid grid-cols-1 gap-2">
							{#each PRODUCT_PALETTE_KEYS as pk (pk.key)}
								<label class="flex items-center gap-3">
									<span class="w-20 shrink-0 font-mono text-label-mono text-on-surface-variant"
										>{pk.label}</span
									>
									<div
										class="flex h-9 flex-1 items-center rounded border border-outline-variant bg-surface-container-high px-3"
									>
										<select
											class="w-full cursor-pointer border-none bg-transparent p-0 font-mono text-label-mono text-on-surface focus:ring-0"
											value={book.assignments[pk.key]}
											onchange={(e) =>
												onAssign(pk.key, (e.currentTarget as HTMLSelectElement).value)}
										>
											{#each book.palettes as p (p.name)}
												<option value={p.name}>{p.name}</option>
											{/each}
										</select>
									</div>
								</label>
							{/each}
						</div>
					</div>

					<div class="flex flex-wrap gap-2 border-t border-outline-variant pt-4">
						<button
							class="flex items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3 py-1.5 font-mono text-label-mono text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
							onclick={downloadPaletteBook}
						>
							<span class="material-symbols-outlined text-[16px]">download</span> Exportar paletas
						</button>
						<label
							class="flex cursor-pointer items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3 py-1.5 font-mono text-label-mono text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
						>
							<span class="material-symbols-outlined text-[16px]">upload</span> Importar paletas
							<input
								type="file"
								accept="application/json"
								class="hidden"
								onchange={onImportPaletteBook}
							/>
						</label>
					</div>
				</div>
			{/if}
		</div>
	</Modal>

	<VadModal open={showVadModal} profile={vadProfile} onclose={() => (showVadModal = false)} />
</div>
