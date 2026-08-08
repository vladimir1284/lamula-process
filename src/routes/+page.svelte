<script lang="ts">
	import { onMount } from 'svelte';
	import { useMachine } from '@xstate/svelte';
	import { observationMachine } from '$lib/pipeline/observationMachine';
	import { observationChannels, hasGeoref, applySpeckleFilter } from '$lib/pipeline';
	import type { Palette, ProductPaletteKey } from '$lib/palette/types';
	import type { MomentType } from '$lib/domain/types';
	import { formatAltitudeM } from '$lib/units';
	import { locale, setLocale, SUPPORTED_LOCALES, _, type Locale } from '$lib/i18n';
	import { VadModal, ScaleEditor, Modal, SiteLocationEditor } from '$lib/viewer';
	import { computeVadProfile } from '$lib/products/vadProfile';
	import AwsExplorer from '$lib/aws-explorer/AwsExplorer.svelte';
	import { MenuBar, type MenuDef, type MenuItem } from '$lib/nav';
	import { loadConfig, type RecentFileEntry } from '$lib/platform';
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
	import {
		windowStore,
		WindowManager,
		WINDOW_TYPE_ICON,
		saveLayout,
		clearLayout,
		exportLayout,
		importLayout,
		type CanvasSize,
		type RadarWindow
	} from '$lib/windows';
	import {
		PRODUCT_GROUPS,
		isGroundKind,
		catalogLabel,
		defaultMapPayload,
		defaultRhiPayload,
		type CatalogProductKind
	} from '$lib/windows/productCatalog';
	import {
		MapWindow,
		RhiWindow,
		CrossSectionWindow,
		ProfileWindow,
		StatsWindow
	} from '$lib/viewer/windows';

	// Every moment the app can decode, for the settings assignment UI (domain/types.ts MomentType).
	const MOMENTS: MomentType[] = ['dBZ', 'dBuZ', 'V', 'W', 'ZDR', 'uPhiDP', 'RhoHV', 'KDP'];

	// i18n-ignore: language names shown in their own language, standard picker convention
	const LOCALE_NAMES: Record<Locale, string> = { es: 'Español', en: 'English' };
	// Ground products whose physical unit differs from any moment (palette/types.ts
	// ProductPaletteKey), so they get their own settings assignment row instead of following the
	// channel's moment.
	const PRODUCT_PALETTE_KEYS: { key: ProductPaletteKey; label: string }[] = [
		{ key: 'TOPS_HEIGHT', label: 'settings.palettes.keys.topsHeight' },
		{ key: 'VIL', label: 'settings.palettes.keys.vil' },
		{ key: 'RAIN', label: 'settings.palettes.keys.rain' },
		{ key: 'WIND_SPEED', label: 'settings.palettes.keys.windSpeed' }
	];

	const { snapshot, send } = useMachine(observationMachine);

	// Per-variable palette group, persisted + configurable (platform/paletteStore.ts). Seeded
	// synchronously so the first paint has colors; the stored/edited book loads in onMount.
	let book = $state<PaletteBook>(seedPaletteBook());
	let siteOverride = $state<{ lat: number; lon: number; altM: number } | null>(null);
	let scaleEditorKey = $state<string | null>(null);
	const showScaleEditor = $derived(scaleEditorKey !== null);
	let showSettings = $state(false);
	let showAwsExplorer = $state(false);
	// Compressed/expanded left panel, persisted in localStorage (same web-only pattern as
	// windows/layoutStore.ts). Seeded false so first paint matches the common case; the stored
	// value loads in onMount, same as `book`/`settings` above.
	const SIDEBAR_COLLAPSED_KEY = 'lamula-process:sidebar-collapsed';
	let sidebarCollapsed = $state(false);
	function toggleSidebar() {
		sidebarCollapsed = !sidebarCollapsed;
		localStorage.setItem(SIDEBAR_COLLAPSED_KEY, String(sidebarCollapsed));
	}
	function itemTitle(item: { id: CatalogProductKind; label: string }): string | undefined {
		const hint = !isGroundKind(item.id) && !focusedMap ? $_('sidebar.crossSectionHint') : undefined;
		if (sidebarCollapsed) return hint ? `${$_(item.label)} — ${hint}` : $_(item.label);
		return hint;
	}
	let vadChannelIndex = $state<number | null>(null);

	// App-wide settings (platform/settingsStore.ts): unit system + default base map/overlays,
	// persisted in localStorage. Seeded synchronously with the defaults so the first paint is
	// consistent; the stored/edited values load in onMount, same pattern as `book` above. Now that
	// each map window owns its own baseMap/opacity/rings/radials, these only seed newly-opened map
	// windows -- they're no longer synced back from a single "active" view.
	let settings = $state<AppSettings>({ ...DEFAULT_SETTINGS });
	const unitSystem = $derived(settings.unitSystem);
	async function updateSettings(patch: Partial<AppSettings>) {
		settings = { ...settings, ...patch };
		await saveSettings(settings);
	}

	// Keeps <html class="light"> (set synchronously pre-hydration by app.html's inline script)
	// in sync with the persisted preference, and follows the OS setting live when mode is 'system'.
	// `isLightTheme` mirrors the same result for the header toggle button's icon.
	let isLightTheme = $state(false);
	$effect(() => {
		const mode = settings.themeMode;
		const mq = window.matchMedia('(prefers-color-scheme: light)');
		const apply = () => {
			isLightTheme = mode === 'light' || (mode === 'system' && mq.matches);
			document.documentElement.classList.toggle('light', isLightTheme);
		};
		apply();
		if (mode !== 'system') return;
		mq.addEventListener('change', apply);
		return () => mq.removeEventListener('change', apply);
	});
	// Settings modal: which section is active, and (for "Sitios") which saved site is being
	// edited -- reusing SiteLocationEditor for both the header's "editar ubicación" shortcut and
	// the general site-data management, so there's a single settings entry point, not two.
	let settingsTab = $state<'unidades' | 'sitios' | 'paletas' | 'calculo' | 'vista' | 'idioma'>(
		'unidades'
	);
	let editingSiteKey = $state<string | null>(null);
	let siteList = $state<SiteDataStore>({});
	async function refreshSiteList() {
		siteList = await loadSiteData();
	}

	const observation = $derived($snapshot.context.observation);
	const loading = $derived(
		$snapshot.value === 'opening' ||
			$snapshot.value === 'openingVolume' ||
			$snapshot.value === 'parsing' ||
			$snapshot.value === 'parsingVolume'
	);
	const error = $derived($snapshot.context.error);
	const recentFiles = $derived($snapshot.context.recentFiles);

	function reopenRecent(entry: RecentFileEntry) {
		send({ type: 'OPEN_RECENT', entry });
	}

	const rawChannels = $derived(observation ? observationChannels(observation) : []);
	// Clones + filters scans rather than mutating `observation` -- toggling the speckle setting
	// back to 0 always recovers the untouched data (see pipeline/applySpeckleFilter.ts).
	const channels = $derived(
		settings.speckleDistanceM > 0
			? applySpeckleFilter(rawChannels, book, settings.speckleDistanceM)
			: rawChannels
	);
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
	// for formats that don't self-describe it (NEXRAD L2, .obs). Global (not per-window): every
	// map window looks at the same one loaded observation.
	const effectiveSite = $derived.by(() => {
		if (!observation) return null;
		if (observation.site.lat !== undefined && observation.site.lon !== undefined) {
			return { lat: observation.site.lat, lon: observation.site.lon, altM: observation.site.altM };
		}
		return siteOverride;
	});
	const site = $derived(effectiveSite ? { lon: effectiveSite.lon, lat: effectiveSite.lat } : null);

	const vadChannel = $derived(
		vadChannelIndex !== null ? channels[vadChannelIndex]?.channel : undefined
	);
	const vadProfile = $derived.by(() => {
		if (!vadChannel || vadChannel.scans.length === 0) return null;
		return computeVadProfile(vadChannel, {}, effectiveSite?.altM ?? 0);
	});

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
		sidebarCollapsed = localStorage.getItem(SIDEBAR_COLLAPSED_KEY) === 'true';
		book = await loadPaletteBook();
		settings = await loadSettings();
		await refreshSiteList();
		const config = await loadConfig();
		send({ type: 'RECENT_FILES_LOADED', recentFiles: config.recentFiles });
	});

	// The scale editor edits whichever palette-book key the "editar escala" button of the window
	// that opened it was pointing at (see MapWindow/RhiWindow/CrossSectionWindow/ProfileWindow's
	// `onEditScale`). Persist the edit and keep the key pointed at it (so a rename doesn't detach
	// the assignment from the edited palette).
	function onPaletteChange(edited: Palette) {
		const key = scaleEditorKey;
		if (!key) return;
		book = assignMomentPalette(upsertPalette(book, edited), key, edited.name);
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

	// ── Window desktop: launching windows from the sidebar catalog ────────────────────────────
	let canvasSize = $state<CanvasSize>({ width: 0, height: 0 });

	const focusedMap = $derived.by((): RadarWindow | null => {
		const w = windowStore.windows.find((w) => w.id === windowStore.focusedId);
		return w && w.type === 'map' ? w : null;
	});

	function launchCatalogItem(id: CatalogProductKind) {
		if (isGroundKind(id)) {
			windowStore.open('map', {
				title: $_(catalogLabel(id)),
				payload: defaultMapPayload(id, {
					baseMap: settings.baseMap,
					showRings: settings.showRings,
					showRadials: settings.showRadials,
					showScale: settings.showScale,
					showSiteMarker: settings.showSiteMarker,
					showCutGuide: settings.showCutGuide,
					zrA: settings.zrA,
					zrB: settings.zrB
				})
			});
			return;
		}
		const src = focusedMap;
		if (!src) return;
		if (id === 'RHI') {
			windowStore.open('rhi', {
				title: 'RHI',
				payload: defaultRhiPayload(src.id, settings.imageSmoothing)
			});
		} else if (id === 'CROSS_LINE') {
			// Arm draw mode on the source map first; the window opens once the line is traced
			// (see MapWindow.svelte's onCutLine).
			windowStore.armCrossSection(src.id);
		} else if (id === 'PROFILE') {
			// Arm draw mode on the source map first; the window opens once a point is picked
			// (see MapWindow.svelte's onPointSelect).
			windowStore.armProfile(src.id);
		} else if (id === 'STATS') {
			// Arm draw mode on the source map first; the window opens once a region is traced
			// (see MapWindow.svelte's onStatsRegionSelect).
			windowStore.armStats(src.id);
		}
	}

	// ── "Ventana" menu: arrange/persist the window desktop ────────────────────────────────────
	let layoutFileInput: HTMLInputElement | undefined = $state();

	async function saveLayoutNow() {
		await saveLayout({
			version: 1,
			windows: $state.snapshot(windowStore.windows),
			focusedId: windowStore.focusedId
		});
	}

	async function resetLayout() {
		windowStore.closeAll();
		await clearLayout();
	}

	function downloadLayoutFile() {
		const blob = new Blob(
			[
				exportLayout({
					version: 1,
					windows: $state.snapshot(windowStore.windows),
					focusedId: windowStore.focusedId
				})
			],
			{ type: 'application/json' }
		);
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = 'layout.json';
		a.click();
		URL.revokeObjectURL(url);
	}

	async function onImportLayoutFile(e: Event) {
		const input = e.currentTarget as HTMLInputElement;
		const file = input.files?.[0];
		if (!file) return;
		input.value = '';
		if (windowStore.windows.length > 0 && !confirm($_('dialog.confirmReplaceLayout'))) {
			return;
		}
		const layout = await importLayout(await file.text());
		windowStore.hydrate(layout);
	}

	const menus = $derived<MenuDef[]>([
		{
			label: $_('menu.file.label'),
			items: [
				{
					label: loading ? $_('menu.file.opening') : $_('menu.file.open'),
					icon: 'upload_file',
					disabled: loading,
					onclick: () => send({ type: 'OPEN' })
				},
				{
					label: $_('menu.file.openVolume'),
					icon: 'layers',
					disabled: loading,
					onclick: () => send({ type: 'OPEN_VOLUME' })
				},
				{
					label: $_('menu.file.downloadAws'),
					icon: 'cloud_download',
					disabled: loading,
					onclick: () => (showAwsExplorer = true)
				},
				{
					label: $_('menu.file.openRecent'),
					icon: 'history',
					submenu:
						recentFiles.length > 0
							? recentFiles.map((entry) => ({
									label: entry.label,
									icon: entry.source === 'aws' ? 'cloud' : 'description',
									onclick: () => reopenRecent(entry)
								}))
							: [{ label: $_('menu.file.noRecent'), disabled: true }]
				}
			]
		},
		{
			label: $_('menu.window.label'),
			items: [
				{
					label: $_('menu.window.cascade'),
					icon: 'view_carousel',
					disabled: windowStore.windows.length === 0,
					onclick: () => windowStore.cascade(canvasSize)
				},
				{
					label: $_('menu.window.tile'),
					icon: 'grid_view',
					disabled: windowStore.windows.length === 0,
					onclick: () => windowStore.tile(canvasSize)
				},
				{
					label: $_('menu.window.resetLayout'),
					icon: 'restart_alt',
					onclick: resetLayout
				},
				{
					label: $_('menu.window.closeAll'),
					icon: 'close',
					disabled: windowStore.windows.length === 0,
					onclick: () => windowStore.closeAll()
				},
				{ label: '', separator: true },
				{ label: $_('menu.window.saveLayout'), icon: 'save', onclick: saveLayoutNow },
				{ label: $_('menu.window.exportLayout'), icon: 'download', onclick: downloadLayoutFile },
				{
					label: $_('menu.window.importLayout'),
					icon: 'upload',
					onclick: () => layoutFileInput?.click()
				},
				{ label: '', separator: true },
				...((): MenuItem[] =>
					windowStore.windows.length > 0
						? windowStore.windows.map((w) => ({
								label: w.title,
								icon: WINDOW_TYPE_ICON[w.type],
								checked: w.id === windowStore.focusedId && !w.minimized,
								onclick: () => windowStore.restore(w.id)
							}))
						: [{ label: $_('menu.window.noWindows'), disabled: true }])()
			]
		}
	]);
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
							<span class="material-symbols-outlined text-[16px]">edit_location</span>
							{$_('common.editLocation')}
						</button>
					{/if}
				</nav>
			{/if}
		</div>
		<div class="flex items-center gap-3">
			<button
				class="flex h-10 w-10 items-center justify-center rounded border border-outline-variant text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
				onclick={() => updateSettings({ themeMode: isLightTheme ? 'dark' : 'light' })}
				aria-label={$_('common.toggleTheme')}
				title={$_('common.toggleTheme')}
			>
				<span class="material-symbols-outlined text-[20px]"
					>{isLightTheme ? 'dark_mode' : 'light_mode'}</span
				>
			</button>
			<button
				class="flex h-10 w-10 items-center justify-center rounded border border-outline-variant text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
				onclick={() => (showSettings = true)}
				aria-label={$_('common.settings')}
				title={$_('common.settings')}
			>
				<span class="material-symbols-outlined text-[20px]">settings</span>
			</button>
		</div>
	</header>

	<!-- ── SideNavBar: product catalog (each click opens a window) ───────────── -->
	<aside
		class={`fixed top-0 left-0 z-40 flex h-full flex-col overflow-y-auto border-r border-outline-variant bg-surface-container-low pt-16 transition-[width] ${sidebarCollapsed ? 'w-sidebar-collapsed-width' : 'w-sidebar-width'}`}
	>
		<div class={sidebarCollapsed ? 'space-y-5 px-2 py-4' : 'space-y-5 p-4'}>
			<div>
				<div class="mb-2 flex items-center justify-between px-1">
					{#if !sidebarCollapsed}
						<p class="font-mono text-[10px] tracking-widest text-outline uppercase">
							{$_('sidebar.product')}
						</p>
					{/if}
					<button
						type="button"
						class="flex h-7 w-7 items-center justify-center rounded text-on-surface-variant transition-colors hover:bg-surface-variant hover:text-primary-container"
						onclick={toggleSidebar}
						aria-label={sidebarCollapsed ? $_('sidebar.expandPanel') : $_('sidebar.collapsePanel')}
						title={sidebarCollapsed ? $_('sidebar.expandPanel') : $_('sidebar.collapsePanel')}
					>
						<span class="material-symbols-outlined text-[18px]"
							>{sidebarCollapsed ? 'chevron_right' : 'chevron_left'}</span
						>
					</button>
				</div>
				<div class="space-y-3 font-mono text-label-mono">
					{#each PRODUCT_GROUPS as group (group.label)}
						<div>
							{#if !sidebarCollapsed}
								<p
									class="mb-1 px-1 text-[10px] tracking-wider text-on-surface-variant/60 uppercase"
								>
									{$_(group.label)}
								</p>
							{/if}
							{#each group.items as item (item.id)}
								<button
									type="button"
									class={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-on-surface-variant transition-all hover:bg-surface-variant disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent ${sidebarCollapsed ? 'justify-center' : ''}`}
									disabled={!observation || (!isGroundKind(item.id) && !focusedMap)}
									title={itemTitle(item)}
									onclick={() => launchCatalogItem(item.id)}
								>
									<span class="material-symbols-outlined text-[18px]">{item.icon}</span>
									{#if !sidebarCollapsed}{$_(item.label)}{/if}
								</button>
							{/each}
							{#if group.label === 'catalog.groups.crossSections' && !focusedMap && !sidebarCollapsed}
								<p class="px-3 py-1 font-mono text-[9px] text-on-surface-variant/70">
									{$_('sidebar.needsFocusedMap')}
								</p>
							{/if}
						</div>
					{/each}
				</div>
			</div>
		</div>
	</aside>

	<!-- ── Main: window desktop ─────────────────────────────────────────────── -->
	<main
		class={`flex min-h-0 flex-1 flex-col pt-16 transition-[padding-left] ${sidebarCollapsed ? 'pl-sidebar-collapsed-width' : 'pl-sidebar-width'}`}
	>
		<div class="flex min-h-0 flex-1 flex-col space-y-gutter">
			{#if error}
				<div
					class="flex flex-col gap-1.5 rounded-xl border border-error/40 bg-error-container/20 px-4 py-3 font-mono text-label-mono text-error"
				>
					<div class="flex items-center gap-3">
						<span class="material-symbols-outlined text-[18px]">error</span>
						{$_('common.errorGeneric')}
					</div>
					<details class="ml-[30px]">
						<summary class="cursor-pointer text-[11px] text-error/80 hover:text-error">
							{$_('common.showTechnicalDetail')}
						</summary>
						<p class="mt-1 text-[11px] break-all text-error/80">{error}</p>
					</details>
				</div>
			{/if}

			<!-- WindowManager always mounts (so a saved layout restores even before a file is open,
				windows just show their own empty state) -- the onboarding panel below is an overlay on
				top of it, shown only while the desktop is genuinely empty and no file has been opened. -->
			<div class="relative flex min-h-0 flex-1 flex-col">
				{#if !observation && windowStore.windows.length === 0}
					<div
						class="glass-panel absolute inset-0 z-10 flex flex-col items-center justify-center gap-5 rounded-xl px-6 text-center"
					>
						<img src="/logo.svg" alt="Lamula" class="h-[96px] w-[96px]" />
						<div>
							<h2 class="font-headline text-headline-md text-on-surface">
								{$_('onboarding.title')}
							</h2>
							<p class="mt-1 text-body-sm text-on-surface-variant">
								{$_('onboarding.formats')}
							</p>
						</div>
						<button
							class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
							onclick={() => send({ type: 'OPEN' })}
							disabled={loading}
						>
							<span class="material-symbols-outlined text-[18px]">upload_file</span>
							{loading ? $_('onboarding.opening') : $_('onboarding.openFile')}
						</button>
						<button
							class="flex h-10 items-center gap-2 rounded border border-outline-variant px-4 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container hover:text-primary-container disabled:opacity-50"
							onclick={() => (showAwsExplorer = true)}
							disabled={loading}
						>
							<span class="material-symbols-outlined text-[18px]">cloud_download</span>
							{$_('onboarding.downloadAws')}
						</button>
					</div>
				{/if}
				<WindowManager bind:canvasSize>
					{#snippet content(w)}
						{#if w.type === 'map'}
							<MapWindow
								win={w}
								{observation}
								{channels}
								{book}
								{unitSystem}
								{site}
								effectiveSiteAltM={effectiveSite?.altM ?? 0}
								imageSmoothing={settings.imageSmoothing}
								onOpenLocationEditor={openLocationEditor}
								onShowVad={(idx) => (vadChannelIndex = idx)}
								onEditScale={(key) => (scaleEditorKey = key)}
							/>
						{:else if w.type === 'rhi'}
							<RhiWindow
								win={w}
								{observation}
								{channels}
								{book}
								{unitSystem}
								onEditScale={(key) => (scaleEditorKey = key)}
							/>
						{:else if w.type === 'cross-section'}
							<CrossSectionWindow
								win={w}
								{observation}
								{channels}
								{book}
								{unitSystem}
								onEditScale={(key) => (scaleEditorKey = key)}
							/>
						{:else if w.type === 'profile'}
							<ProfileWindow
								win={w}
								{observation}
								{channels}
								effectiveSiteAltM={effectiveSite?.altM ?? 0}
								onEditScale={(key) => (scaleEditorKey = key)}
							/>
						{:else if w.type === 'stats'}
							<StatsWindow
								win={w}
								{observation}
								{channels}
								effectiveSiteAltM={effectiveSite?.altM ?? 0}
							/>
						{/if}
					{/snippet}
				</WindowManager>
			</div>
		</div>
	</main>

	<input
		type="file"
		accept="application/json"
		class="hidden"
		bind:this={layoutFileInput}
		onchange={onImportLayoutFile}
	/>

	<Modal
		open={showAwsExplorer}
		title={$_('modal.awsExplorer')}
		onclose={() => (showAwsExplorer = false)}
	>
		<AwsExplorer
			{unitSystem}
			onload={(picked) => {
				showAwsExplorer = false;
				send({ type: 'LOAD_REMOTE', picked: { ...picked, source: 'aws' } });
			}}
			onloadVolume={(picked) => {
				showAwsExplorer = false;
				send({
					type: 'LOAD_VOLUME',
					picked: picked.map((p) => ({ ...p, source: 'aws' as const }))
				});
			}}
		/>
	</Modal>

	<Modal
		open={showScaleEditor}
		title={$_('modal.scaleEditor')}
		onclose={() => (scaleEditorKey = null)}
	>
		<div class="p-4">
			{#if scaleEditorKey}
				<ScaleEditor palette={paletteForMoment(book, scaleEditorKey)} onchange={onPaletteChange} />
			{/if}
		</div>
	</Modal>

	<Modal
		open={showSettings}
		title={$_('common.settings')}
		onclose={() => {
			showSettings = false;
			editingSiteKey = null;
		}}
	>
		<div class="flex flex-col gap-4">
			<!-- Section tabs. -->
			<div class="flex gap-1 border-b border-outline-variant font-mono text-label-mono uppercase">
				{#each [{ id: 'unidades', label: 'settings.tabs.units', icon: 'straighten' }, { id: 'sitios', label: 'settings.tabs.sites', icon: 'pin_drop' }, { id: 'paletas', label: 'settings.tabs.palettes', icon: 'palette' }, { id: 'calculo', label: 'settings.tabs.calc', icon: 'functions' }, { id: 'vista', label: 'settings.tabs.view', icon: 'visibility' }, { id: 'idioma', label: 'settings.tabs.language', icon: 'translate' }] as tab (tab.id)}
					<button
						class="flex items-center gap-1.5 border-b-2 px-3 py-2 transition-colors {settingsTab ===
						tab.id
							? 'border-primary-container text-primary-container'
							: 'border-transparent text-on-surface-variant hover:text-on-surface'}"
						onclick={() => (settingsTab = tab.id as typeof settingsTab)}
					>
						<span class="material-symbols-outlined text-[16px]">{tab.icon}</span>
						{$_(tab.label)}
					</button>
				{/each}
			</div>

			{#if settingsTab === 'unidades'}
				<div class="space-y-3">
					<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
						{$_('settings.units.heading')}
					</h3>
					<p class="font-mono text-[10px] text-on-surface-variant">
						{$_('settings.units.description')}
					</p>
					<div class="flex gap-2">
						<button
							class="flex items-center gap-2 rounded border px-4 py-2 font-mono text-label-mono transition-colors {unitSystem ===
							'metric'
								? 'border-primary-container bg-primary-container text-on-primary-container'
								: 'border-outline-variant bg-surface-container-high text-on-surface-variant hover:border-primary-container'}"
							onclick={() => updateSettings({ unitSystem: 'metric' })}
						>
							{$_('settings.units.metric')}
						</button>
						<button
							class="flex items-center gap-2 rounded border px-4 py-2 font-mono text-label-mono transition-colors {unitSystem ===
							'imperial'
								? 'border-primary-container bg-primary-container text-on-primary-container'
								: 'border-outline-variant bg-surface-container-high text-on-surface-variant hover:border-primary-container'}"
							onclick={() => updateSettings({ unitSystem: 'imperial' })}
						>
							{$_('settings.units.imperial')}
						</button>
					</div>
				</div>
			{:else if settingsTab === 'sitios'}
				<div class="space-y-4">
					{#if editingSiteKey}
						<div class="flex items-center justify-between">
							<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
								{$_('settings.sites.editing', { values: { key: editingSiteKey } })}
							</h3>
							<button
								class="font-mono text-[10px] text-on-surface-variant hover:text-primary-container"
								onclick={cancelSiteEdit}
							>
								{$_('settings.sites.backToList')}
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
								{$_('settings.sites.heading')}
							</h3>
							<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
								{$_('settings.sites.description')}
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
												aria-label={$_('settings.sites.editAria', { values: { key } })}
												title={$_('common.edit')}
												onclick={() => (editingSiteKey = key)}
											>
												<span class="material-symbols-outlined text-[16px]">edit</span>
											</button>
											<button
												class="text-on-surface-variant transition-colors hover:text-dbz-heavy"
												aria-label={$_('settings.sites.deleteAria', { values: { key } })}
												title={$_('common.delete')}
												onclick={() => removeSiteLocation(key)}
											>
												<span class="material-symbols-outlined text-[16px]">delete</span>
											</button>
										</li>
									{/each}
								</ul>
							{:else}
								<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
									{$_('settings.sites.empty')}
								</p>
							{/if}
							<div class="flex flex-wrap gap-2 border-t border-outline-variant pt-4">
								<button
									class="flex items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container"
									onclick={exportSiteDataFile}
								>
									<span class="material-symbols-outlined text-[16px]">download</span>
									{$_('common.export')}
								</button>
								<label
									class="flex cursor-pointer items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 font-mono text-label-mono text-on-surface transition-colors hover:border-primary-container"
								>
									<span class="material-symbols-outlined text-[16px]">upload</span>
									{$_('common.import')}
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
									<span class="material-symbols-outlined text-[16px]">public</span>
									{$_('settings.sites.loadKnown')}
								</button>
							</div>
						</div>
					{/if}
				</div>
			{:else if settingsTab === 'paletas'}
				<div class="space-y-5">
					<div>
						<h3 class="mb-1 font-mono text-label-mono tracking-widest text-on-surface uppercase">
							{$_('settings.palettes.byVariableHeading')}
						</h3>
						<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
							{$_('settings.palettes.byVariableDescription')}
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
							{$_('settings.palettes.byProductHeading')}
						</h3>
						<p class="mb-3 font-mono text-[10px] text-on-surface-variant">
							{$_('settings.palettes.byProductDescription')}
						</p>
						<div class="grid grid-cols-1 gap-2">
							{#each PRODUCT_PALETTE_KEYS as pk (pk.key)}
								<label class="flex items-center gap-3">
									<span class="w-20 shrink-0 font-mono text-label-mono text-on-surface-variant"
										>{$_(pk.label)}</span
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
							<span class="material-symbols-outlined text-[16px]">download</span>
							{$_('settings.palettes.export')}
						</button>
						<label
							class="flex cursor-pointer items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3 py-1.5 font-mono text-label-mono text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
						>
							<span class="material-symbols-outlined text-[16px]">upload</span>
							{$_('settings.palettes.import')}
							<input
								type="file"
								accept="application/json"
								class="hidden"
								onchange={onImportPaletteBook}
							/>
						</label>
					</div>
				</div>
			{:else if settingsTab === 'calculo'}
				<div class="space-y-3">
					<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
						{$_('settings.calc.heading')}
					</h3>
					<p class="font-mono text-[10px] text-on-surface-variant">
						{$_('settings.calc.description')}
					</p>
					<div class="flex gap-4">
						<label class="flex items-center gap-2">
							<span class="font-mono text-label-mono text-on-surface-variant">Z-R A</span>
							<input
								type="number"
								step="10"
								class="w-20 rounded border border-outline-variant bg-surface-container-high px-2 py-1 font-mono text-label-mono text-on-surface"
								value={settings.zrA}
								onchange={(e) =>
									updateSettings({ zrA: Number((e.currentTarget as HTMLInputElement).value) })}
							/>
						</label>
						<label class="flex items-center gap-2">
							<span class="font-mono text-label-mono text-on-surface-variant">Z-R B</span>
							<input
								type="number"
								step="0.1"
								class="w-20 rounded border border-outline-variant bg-surface-container-high px-2 py-1 font-mono text-label-mono text-on-surface"
								value={settings.zrB}
								onchange={(e) =>
									updateSettings({ zrB: Number((e.currentTarget as HTMLInputElement).value) })}
							/>
						</label>
					</div>
					<div class="space-y-2 border-t border-outline-variant pt-4">
						<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
							{$_('settings.calc.speckleHeading')}
						</h3>
						<p class="font-mono text-[10px] text-on-surface-variant">
							{$_('settings.calc.speckleDescription')}
						</p>
						<label class="flex items-center gap-2">
							<input
								type="number"
								min="0"
								step="100"
								class="w-24 rounded border border-outline-variant bg-surface-container-high px-2 py-1 font-mono text-label-mono text-on-surface"
								value={settings.speckleDistanceM}
								onchange={(e) =>
									updateSettings({
										speckleDistanceM: Math.max(
											0,
											Number((e.currentTarget as HTMLInputElement).value)
										)
									})}
							/>
							<span class="font-mono text-label-mono text-on-surface-variant">m</span>
						</label>
					</div>
				</div>
			{:else if settingsTab === 'vista'}
				<div class="space-y-3">
					<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
						{$_('settings.view.heading')}
					</h3>
					<p class="font-mono text-[10px] text-on-surface-variant">
						{$_('settings.view.description')}
					</p>
					<div class="flex gap-2">
						{#each [
							['dark', 'settings.view.themeDark'],
							['light', 'settings.view.themeLight'],
							['system', 'settings.view.themeSystem']
						] as [mode, labelKey] (mode)}
							<button
								class="flex items-center gap-2 rounded border px-4 py-2 font-mono text-label-mono transition-colors {settings.themeMode ===
								mode
									? 'border-primary-container bg-primary-container text-on-primary-container'
									: 'border-outline-variant bg-surface-container-high text-on-surface-variant hover:border-primary-container'}"
								onclick={() => updateSettings({ themeMode: mode as AppSettings['themeMode'] })}
							>
								{$_(labelKey)}
							</button>
						{/each}
					</div>
					<label class="flex items-center gap-2 font-mono text-label-mono text-on-surface-variant">
						<input
							type="checkbox"
							checked={settings.showScale}
							class="accent-primary-container"
							onchange={(e) =>
								updateSettings({ showScale: (e.currentTarget as HTMLInputElement).checked })}
						/>
						{$_('settings.view.showScale')}
					</label>
					<label class="flex items-center gap-2 font-mono text-label-mono text-on-surface-variant">
						<input
							type="checkbox"
							checked={settings.showSiteMarker}
							class="accent-primary-container"
							onchange={(e) =>
								updateSettings({ showSiteMarker: (e.currentTarget as HTMLInputElement).checked })}
						/>
						{$_('settings.view.showSiteMarker')}
					</label>
					<label class="flex items-center gap-2 font-mono text-label-mono text-on-surface-variant">
						<input
							type="checkbox"
							checked={settings.showCutGuide}
							class="accent-primary-container"
							onchange={(e) =>
								updateSettings({ showCutGuide: (e.currentTarget as HTMLInputElement).checked })}
						/>
						{$_('settings.view.showCutGuide')}
					</label>
					<label class="flex items-center gap-2 font-mono text-label-mono text-on-surface-variant">
						<input
							type="checkbox"
							checked={settings.imageSmoothing}
							class="accent-primary-container"
							onchange={(e) =>
								updateSettings({ imageSmoothing: (e.currentTarget as HTMLInputElement).checked })}
						/>
						{$_('settings.view.imageSmoothing')}
					</label>
				</div>
			{:else if settingsTab === 'idioma'}
				<div class="space-y-3">
					<h3 class="font-mono text-label-mono tracking-widest text-on-surface uppercase">
						Idioma / Language
					</h3>
					<div class="flex gap-2">
						{#each SUPPORTED_LOCALES as loc (loc)}
							<button
								class="flex items-center gap-2 rounded border px-4 py-2 font-mono text-label-mono transition-colors {$locale ===
								loc
									? 'border-primary-container bg-primary-container text-on-primary-container'
									: 'border-outline-variant bg-surface-container-high text-on-surface-variant hover:border-primary-container'}"
								onclick={() => setLocale(loc)}
							>
								{LOCALE_NAMES[loc]}
							</button>
						{/each}
					</div>
				</div>
			{/if}
		</div>
	</Modal>

	<VadModal
		open={vadChannelIndex !== null}
		profile={vadProfile}
		onclose={() => (vadChannelIndex = null)}
	/>
</div>
