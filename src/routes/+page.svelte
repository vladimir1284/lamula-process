<script lang="ts">
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
	import { eastWestLine, northSouthLine, computeProfile, volumeToRhiScan } from '$lib/products';
	import { defaultDbzPalette } from '$lib/palette/default';
	import type { Palette } from '$lib/palette/types';
	import type { Scan } from '$lib/domain/types';
	import {
		PpiMap,
		RhiPanel,
		RhiAzimuthPicker,
		CrossSectionPanel,
		ProfilePanel,
		ScaleEditor,
		Modal,
		SiteLocationEditor
	} from '$lib/viewer';
	import { standardOverlays } from '$lib/overlays';
	import type { Readout } from '$lib/viewer/readout';
	import type { RhiReadout } from '$lib/render/rasterizeRHI';
	import {
		siteKey,
		getSiteLocation,
		setSiteLocation,
		loadSiteData,
		exportSiteData,
		importSiteData,
		loadKnownSitesSeed
	} from '$lib/platform';

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
	type ProductKind = GroundProductKind | 'CROSS_EW' | 'CROSS_NS' | 'PROFILE' | 'RHI';

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
				{ id: 'CROSS_EW', label: 'Corte Este-Oeste', icon: 'swap_horiz' },
				{ id: 'CROSS_NS', label: 'Corte Norte-Sur', icon: 'swap_vert' },
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
	let profileXkm = $state(0);
	let profileYkm = $state(30);
	let rhiAzimuthDeg = $state(0);

	let palette = $state<Palette>(defaultDbzPalette);
	let readout = $state<Readout | RhiReadout | null>(null);
	let siteOverride = $state<{ lat: number; lon: number; altM: number } | null>(null);
	let showLocationEditor = $state(false);

	const observation = $derived($snapshot.context.observation);
	const loading = $derived($snapshot.value === 'opening' || $snapshot.value === 'parsing');
	const error = $derived($snapshot.context.error);
	const recentFiles = $derived($snapshot.context.recentFiles);

	const channels = $derived(observation ? observationChannels(observation) : []);
	const channel = $derived(channels[channelIndex]?.channel);
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

	const cutLine = $derived.by(() => {
		if (!channel || (product !== 'CROSS_EW' && product !== 'CROSS_NS')) return null;
		const half = maxRangeM(channel);
		return product === 'CROSS_EW' ? eastWestLine(0, half) : northSouthLine(0, half);
	});

	const profile = $derived.by(() => {
		if (!channel || product !== 'PROFILE') return null;
		return computeProfile(channel.scans, {
			xEastM: profileXkm * 1000,
			yNorthM: profileYkm * 1000,
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

	function openLocationEditor() {
		showLocationEditor = true;
	}
	function cancelLocationEditor() {
		showLocationEditor = false;
	}
	async function saveSiteLocation(loc: { lat: number; lon: number; altM: number }) {
		siteOverride = loc;
		showLocationEditor = false;
		if (observation) await setSiteLocation(siteKey(observation.site), loc);
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
		if (observation && !hasGeoref(observation)) {
			const loc = await getSiteLocation(siteKey(observation.site));
			if (loc) siteOverride = { lat: loc.lat, lon: loc.lon, altM: loc.altM };
		}
	}

	async function loadKnownSites() {
		await loadKnownSitesSeed();
		if (observation && !hasGeoref(observation)) {
			const loc = await getSiteLocation(siteKey(observation.site));
			if (loc) siteOverride = { lat: loc.lat, lon: loc.lon, altM: loc.altM };
		}
	}
</script>

<div class="radar-grid-bg min-h-screen bg-surface-container-lowest text-on-surface">
	<!-- ── TopAppBar ─────────────────────────────────────────────────────────── -->
	<header
		class="fixed top-0 right-0 left-0 z-50 flex h-16 items-center justify-between border-b border-outline-variant bg-surface-container px-margin-desktop"
	>
		<div class="flex items-center gap-6">
			<h1 class="flex items-center gap-2 font-headline text-headline-md font-bold text-primary">
				<span
					class="material-symbols-outlined text-primary-container"
					style="font-variation-settings:'FILL' 1;">radar</span
				>
				LAMULA <span class="font-normal text-on-surface-variant">Process</span>
			</h1>
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
		<div class="flex items-center gap-4">
			<button
				class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
				onclick={() => send({ type: 'OPEN' })}
				disabled={loading}
			>
				<span class="material-symbols-outlined text-[18px]">upload_file</span>
				{loading ? 'ABRIENDO…' : 'ABRIR ARCHIVO'}
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
				<p class="mb-2 px-1 font-mono text-[10px] tracking-widest text-outline uppercase">Producto</p>
				<div class="space-y-3 font-mono text-label-mono">
					{#each PRODUCT_GROUPS as group (group.label)}
						<div>
							<p
								class="mb-1 px-1 text-[10px] tracking-wider text-on-surface-variant/60 uppercase"
							>
								{group.label}
							</p>
							{#each group.items as item (item.id)}
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
								</button>
							{/each}
						</div>
					{/each}
				</div>
			</div>
		</div>
	</aside>

	<!-- ── Main ──────────────────────────────────────────────────────────────── -->
	<main class="min-h-screen pt-16 pl-sidebar-width">
		<div class="space-y-gutter p-margin-desktop">
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
					class="glass-panel flex min-h-[70vh] flex-col items-center justify-center gap-5 rounded-xl px-6 text-center"
				>
					<span class="material-symbols-outlined text-[56px] text-primary-container">radar</span>
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
				</div>
			{:else}
				<!-- Product header + contextual params toolbar. -->
				<div
					class="glass-panel flex flex-col justify-between gap-4 rounded-xl p-4 xl:flex-row xl:items-center"
				>
					<div>
						<h2 class="flex items-center gap-3 font-headline text-headline-md text-on-surface">
							{productTitle}
							{#if ground}
								<span
									class="rounded bg-dbz-mod/15 px-2 py-0.5 font-mono text-[10px] tracking-widest text-dbz-mod uppercase"
									>{ground.unit}</span
								>
							{/if}
						</h2>
						<p class="text-body-sm text-on-surface-variant">
							{observation.site.name} · {observation.timestamp}
						</p>
					</div>

					<div class="flex flex-wrap items-center gap-3">
						{#if product === 'CAPPI'}
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">BASE</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={cappiBottomKm}
									step="0.5"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">km</span>
							</label>
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">TOPE</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={cappiTopKm}
									step="0.5"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">km</span>
							</label>
						{/if}

						{#if product === 'TOPS'}
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">UMBRAL</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={topsMinDbz}
									step="1"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">dBZ</span>
							</label>
						{/if}

						{#if product === 'VIL'}
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">BASE</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={vilBottomKm}
									step="0.5"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">km</span>
							</label>
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">TOPE</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={vilTopKm}
									step="0.5"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">km</span>
							</label>
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">C1</span>
								<input
									type="number"
									class="w-20 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={vilC1}
									step="0.0001"
								/>
							</label>
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">C2</span>
								<input
									type="number"
									class="w-20 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={vilC2}
									step="0.0001"
								/>
							</label>
						{/if}

						{#if product === 'RAIN'}
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">Z-R A</span>
								<input
									type="number"
									class="w-16 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={zrA}
									step="10"
								/>
							</label>
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">Z-R B</span>
								<input
									type="number"
									class="w-16 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={zrB}
									step="0.1"
								/>
							</label>
						{/if}

						{#if product === 'RHI'}
							<label
								class="cyan-glow flex h-10 items-center gap-3 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">AZIMUT</span>
								<input type="range" class="w-40" bind:value={rhiAzimuthDeg} min="0" max="359" step="1" />
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
						{/if}

						{#if product === 'PROFILE'}
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">X ESTE</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={profileXkm}
									step="1"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">km</span>
							</label>
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">Y NORTE</span>
								<input
									type="number"
									class="w-14 border-none bg-transparent p-0 font-mono text-label-mono text-primary-container focus:ring-0"
									bind:value={profileYkm}
									step="1"
								/>
								<span class="font-mono text-[11px] text-on-surface-variant">km</span>
							</label>
						{/if}

						{#if product === 'CROSS_EW' || product === 'CROSS_NS' || product === 'PROFILE' || product === 'RHI'}
							<label
								class="cyan-glow flex h-10 items-center gap-2 rounded border border-outline-variant bg-surface-container-high px-3"
							>
								<span class="font-mono text-[11px] text-on-surface-variant">ALT MÁX</span>
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
				</div>

				<!-- Viewer hero + scale rail. -->
				<div class="grid grid-cols-1 gap-gutter 2xl:grid-cols-[1fr_320px]">
					<section
						class="glass-panel flex flex-col overflow-hidden rounded-xl border-primary-container/30 shadow-[0_0_24px_rgba(0,240,255,0.05)]"
					>
						<div
							class="flex items-center justify-between border-b border-outline-variant bg-surface-container-high px-4 py-2.5"
						>
							<span
								class="flex items-center gap-2 font-mono text-label-mono tracking-tight text-on-surface-variant uppercase"
								><span class="material-symbols-outlined text-[18px] text-primary-container"
									>my_location</span
								> Visor · {productTitle}</span
							>
						</div>

						<div class="relative h-[620px] overflow-auto bg-black">
							{#if product === 'RHI' && rhiScan}
								<div class="flex flex-wrap gap-4 p-3">
									{#if rhiBaseScan}
										<div class="flex flex-col gap-1">
											<span class="font-mono text-[10px] text-on-surface-variant"
												>Azimut del corte (arrastra) · fondo: máx de columna</span
											>
											<RhiAzimuthPicker
												scan={rhiBaseScan}
												{palette}
												azimuthDeg={rhiAzimuthDeg}
												onchange={(a) => (rhiAzimuthDeg = a)}
											/>
										</div>
									{/if}
									<div class="min-w-[420px] flex-1">
										<p class="mb-2 font-mono text-[10px] text-on-surface-variant">
											RHI reconstruido del volumen al azimut {rhiAzimuthDeg}°: un rayo por elevación ({rhiScan.numRays}
											tumbos). La resolución vertical la limita el número de elevaciones.
										</p>
										<RhiPanel
											scan={rhiScan}
											{palette}
											maxHeightM={maxHeightKm * 1000}
											onreadout={(r) => (readout = r)}
										/>
									</div>
								</div>
							{:else if (product === 'CROSS_EW' || product === 'CROSS_NS') && cutLine && channel}
								<div class="p-3">
									<p class="mb-2 font-mono text-[10px] text-on-surface-variant">
										Corte vertical (muestreo inverso por píxel; no georreferenciado, funciona sin
										posición de sitio).
									</p>
									<CrossSectionPanel
										scans={channel.scans}
										{palette}
										line={cutLine}
										maxHeightM={maxHeightKm * 1000}
									/>
								</div>
							{:else if product === 'PROFILE' && profile}
								<div class="flex gap-4 p-3">
									<ProfilePanel {profile} valueLabel={channel?.moment ?? 'dBZ'} />
									<p class="font-mono text-[10px] text-on-surface-variant">
										Perfil vertical en (E {profileXkm} km, N {profileYkm} km): una muestra por elevación,
										interpolada por spline cúbico.
									</p>
								</div>
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
											ubicación para georreferenciar el <span class="text-on-surface">{productTitle}</span
											>, o usa cortes, perfil y RHI (no la requieren).
										</p>
										<button
											class="flex h-10 items-center gap-2 rounded bg-primary-container px-4 font-mono text-label-mono text-on-primary-container transition-all hover:opacity-90 active:scale-95"
											onclick={openLocationEditor}
										>
											<span class="material-symbols-outlined text-[18px]">add_location_alt</span> DEFINIR
											UBICACIÓN
										</button>
										<div
											class="flex flex-wrap items-center justify-center gap-2 font-mono text-label-mono"
										>
											<span class="text-on-surface-variant">Disponibles:</span>
											<span
												class="rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-on-surface"
												>Corte E-O</span
											>
											<span
												class="rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-on-surface"
												>Corte N-S</span
											>
											<span
												class="rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-on-surface"
												>Perfil vertical</span
											>
											<span
												class="rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-on-surface"
												>RHI</span
											>
										</div>
									</div>
								{:else if ground}
									<PpiMap
										scan={ground.scan}
										{palette}
										{site}
										extraLayers={overlays}
										onreadout={(r) => (readout = r)}
									/>
								{/if}
							{/if}
						</div>

						<!-- Readout bar. -->
						<div
							class="grid grid-cols-2 gap-px border-t border-outline-variant bg-surface-container-low font-mono sm:grid-cols-4"
						>
							{#if readout && 'azimuthDeg' in readout}
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">AZIMUT</p>
									<p class="text-label-mono text-primary-container">{fmt(readout.azimuthDeg)}°</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">RANGO</p>
									<p class="text-label-mono text-on-surface">{fmt(readout.rangeM / 1000)} km</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">VALOR</p>
									<p class="text-label-mono text-dbz-heavy">
										{readout.value === null ? '—' : fmt(readout.value)}
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
									<p class="text-label-mono text-on-surface">{fmt(readout.rangeM / 1000)} km</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">ALTURA</p>
									<p class="text-label-mono text-on-surface">{fmt(readout.heightM / 1000, 2)} km</p>
								</div>
								<div class="bg-surface-container-low p-3">
									<p class="mb-0.5 text-label-caps text-on-surface-variant">VALOR</p>
									<p class="text-label-mono text-dbz-heavy">
										{readout.value === null ? '—' : fmt(readout.value)}
									</p>
								</div>
								<div class="bg-surface-container-low p-3"></div>
							{:else}
								<div class="col-span-2 bg-surface-container-low p-3 sm:col-span-4">
									<p class="text-label-mono text-on-surface-variant">
										Pasa el cursor sobre el visor para leer valores.
									</p>
								</div>
							{/if}
						</div>
					</section>

					<!-- Scale editor rail. -->
					<section class="glass-panel flex flex-col self-start overflow-hidden rounded-xl">
						<div
							class="flex items-center justify-between border-b border-outline-variant bg-surface-container-high px-4 py-2.5"
						>
							<span
								class="flex items-center gap-2 font-mono text-label-mono tracking-tight text-on-surface-variant uppercase"
								><span class="material-symbols-outlined text-[18px] text-primary-container"
									>gradient</span
								> Editor de escala</span
							>
						</div>
						<div class="p-4">
							<ScaleEditor {palette} onchange={(p) => (palette = p)} />
						</div>
					</section>
				</div>

				<!-- Recientes. -->
				{#if recentFiles.length > 0}
					<section class="glass-panel overflow-hidden rounded-xl">
						<div
							class="flex items-center gap-2 border-b border-outline-variant bg-surface-container-high px-6 py-3"
						>
							<span class="material-symbols-outlined text-[18px] text-primary-container">history</span>
							<h3 class="font-mono text-label-mono uppercase">Archivos recientes</h3>
						</div>
						<ul class="divide-y divide-outline-variant/30 font-mono text-label-mono">
							{#each recentFiles as name (name)}
								<li
									class="flex items-center gap-3 px-6 py-3 text-on-surface-variant transition-colors hover:bg-surface-variant/20"
								>
									<span class="material-symbols-outlined text-[16px] text-outline">description</span>
									<span class="text-on-surface">{name}</span>
								</li>
							{/each}
						</ul>
					</section>
				{/if}

				<!-- Site-location store: export / import / seed the known radar network. -->
				<section class="glass-panel overflow-hidden rounded-xl">
					<div
						class="flex items-center gap-2 border-b border-outline-variant bg-surface-container-high px-6 py-3"
					>
						<span class="material-symbols-outlined text-[18px] text-primary-container">pin_drop</span>
						<h3 class="font-mono text-label-mono uppercase">Ubicaciones de sitio guardadas</h3>
					</div>
					<div class="flex flex-wrap gap-2 p-4 font-mono text-label-mono">
						<button
							class="flex items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 text-on-surface transition-colors hover:border-primary-container"
							onclick={exportSiteDataFile}
						>
							<span class="material-symbols-outlined text-[16px]">download</span> Exportar
						</button>
						<label
							class="flex cursor-pointer items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 text-on-surface transition-colors hover:border-primary-container"
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
							class="flex items-center gap-1 rounded border border-outline-variant bg-surface-container-high px-3 py-2 text-on-surface transition-colors hover:border-primary-container"
							onclick={loadKnownSites}
						>
							<span class="material-symbols-outlined text-[16px]">public</span> Cargar red conocida
						</button>
					</div>
				</section>
			{/if}
		</div>
	</main>

	<Modal open={showLocationEditor} title="Ubicación del sitio" onclose={cancelLocationEditor}>
		<SiteLocationEditor
			initial={siteOverride ?? undefined}
			onsave={saveSiteLocation}
			oncancel={cancelLocationEditor}
		/>
	</Modal>
</div>
