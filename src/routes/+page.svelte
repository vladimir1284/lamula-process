<script lang="ts">
	import { onMount } from 'svelte';
	import { useMachine } from '@xstate/svelte';
	import { observationMachine } from '$lib/pipeline/observationMachine';
	import { observationChannels, hasGeoref } from '$lib/pipeline';
	import type { Palette, ProductPaletteKey } from '$lib/palette/types';
	import type { MomentType } from '$lib/domain/types';
	import { formatAltitudeM } from '$lib/units';
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
		defaultCrossSectionPayload,
		defaultProfilePayload,
		type CatalogProductKind
	} from '$lib/windows/productCatalog';
	import { MapWindow, RhiWindow, CrossSectionWindow, ProfileWindow } from '$lib/viewer/windows';

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

	const { snapshot, send } = useMachine(observationMachine);

	// Per-variable palette group, persisted + configurable (platform/paletteStore.ts). Seeded
	// synchronously so the first paint has colors; the stored/edited book loads in onMount.
	let book = $state<PaletteBook>(seedPaletteBook());
	let siteOverride = $state<{ lat: number; lon: number; altM: number } | null>(null);
	let scaleEditorKey = $state<string | null>(null);
	const showScaleEditor = $derived(scaleEditorKey !== null);
	let showSettings = $state(false);
	let showAwsExplorer = $state(false);
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
	// Settings modal: which section is active, and (for "Sitios") which saved site is being
	// edited -- reusing SiteLocationEditor for both the header's "editar ubicación" shortcut and
	// the general site-data management, so there's a single settings entry point, not two.
	let settingsTab = $state<'unidades' | 'sitios' | 'paletas'>('unidades');
	let editingSiteKey = $state<string | null>(null);
	let siteList = $state<SiteDataStore>({});
	async function refreshSiteList() {
		siteList = await loadSiteData();
	}

	const observation = $derived($snapshot.context.observation);
	const loading = $derived($snapshot.value === 'opening' || $snapshot.value === 'parsing');
	const error = $derived($snapshot.context.error);
	const recentFiles = $derived($snapshot.context.recentFiles);

	function reopenRecent(entry: RecentFileEntry) {
		send({ type: 'OPEN_RECENT', entry });
	}

	const channels = $derived(observation ? observationChannels(observation) : []);
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
				title: catalogLabel(id),
				payload: defaultMapPayload(id, {
					baseMap: settings.baseMap,
					showRings: settings.showRings,
					showRadials: settings.showRadials
				})
			});
			return;
		}
		const src = focusedMap;
		if (!src) return;
		if (id === 'RHI') {
			windowStore.open('rhi', { title: 'RHI', payload: defaultRhiPayload(src.id) });
		} else if (id === 'CROSS_LINE') {
			windowStore.open('cross-section', {
				title: 'Corte',
				payload: defaultCrossSectionPayload(src.id)
			});
		} else if (id === 'PROFILE') {
			windowStore.open('profile', {
				title: 'Perfil vertical',
				payload: defaultProfilePayload(src.id)
			});
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
		if (
			windowStore.windows.length > 0 &&
			!confirm('Esto reemplazará el diseño actual. ¿Continuar?')
		) {
			return;
		}
		const layout = await importLayout(await file.text());
		windowStore.hydrate(layout);
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
		},
		{
			label: 'Ventana',
			items: [
				{
					label: 'Cascada',
					icon: 'view_carousel',
					disabled: windowStore.windows.length === 0,
					onclick: () => windowStore.cascade(canvasSize)
				},
				{
					label: 'Mosaico',
					icon: 'grid_view',
					disabled: windowStore.windows.length === 0,
					onclick: () => windowStore.tile(canvasSize)
				},
				{
					label: 'Restaurar diseño predeterminado',
					icon: 'restart_alt',
					onclick: resetLayout
				},
				{
					label: 'Cerrar todas',
					icon: 'close',
					disabled: windowStore.windows.length === 0,
					onclick: () => windowStore.closeAll()
				},
				{ label: '', separator: true },
				{ label: 'Guardar diseño', icon: 'save', onclick: saveLayoutNow },
				{ label: 'Exportar diseño…', icon: 'download', onclick: downloadLayoutFile },
				{ label: 'Importar diseño…', icon: 'upload', onclick: () => layoutFileInput?.click() },
				{ label: '', separator: true },
				...((): MenuItem[] =>
					windowStore.windows.length > 0
						? windowStore.windows.map((w) => ({
								label: w.title,
								icon: WINDOW_TYPE_ICON[w.type],
								checked: w.id === windowStore.focusedId && !w.minimized,
								onclick: () => windowStore.restore(w.id)
							}))
						: [{ label: 'Sin ventanas abiertas', disabled: true }])()
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

	<!-- ── SideNavBar: product catalog (each click opens a window) ───────────── -->
	<aside
		class="fixed top-0 left-0 z-40 flex h-full w-sidebar-width flex-col overflow-y-auto border-r border-outline-variant bg-surface-container-low pt-16"
	>
		<div class="space-y-5 p-4">
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
								<button
									type="button"
									class="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-left text-on-surface-variant transition-all hover:bg-surface-variant disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent"
									disabled={!observation || (!isGroundKind(item.id) && !focusedMap)}
									title={!isGroundKind(item.id) && !focusedMap
										? 'Enfoca una ventana de mapa para crear este producto derivado'
										: undefined}
									onclick={() => launchCatalogItem(item.id)}
								>
									<span class="material-symbols-outlined text-[18px]">{item.icon}</span>
									{item.label}
								</button>
							{/each}
							{#if group.label === 'Cortes' && !focusedMap}
								<p class="px-3 py-1 font-mono text-[9px] text-on-surface-variant/70">
									Requiere una ventana de mapa enfocada.
								</p>
							{/if}
						</div>
					{/each}
				</div>
			</div>
		</div>
	</aside>

	<!-- ── Main: window desktop ─────────────────────────────────────────────── -->
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
								{channels}
								effectiveSiteAltM={effectiveSite?.altM ?? 0}
								onEditScale={(key) => (scaleEditorKey = key)}
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

	<Modal open={showScaleEditor} title="Editor de escala" onclose={() => (scaleEditorKey = null)}>
		<div class="p-4">
			{#if scaleEditorKey}
				<ScaleEditor palette={paletteForMoment(book, scaleEditorKey)} onchange={onPaletteChange} />
			{/if}
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

	<VadModal
		open={vadChannelIndex !== null}
		profile={vadProfile}
		onclose={() => (vadChannelIndex = null)}
	/>
</div>
