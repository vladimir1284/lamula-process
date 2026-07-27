<script lang="ts">
	import RadarSiteMap from './RadarSiteMap.svelte';
	import { geocodeZip, nearestSites, type RadarCatalogSite } from './radarCatalog';
	import { listVolumeScans, fetchVolumeScanBytes, type VolumeScan } from './nexradS3';
	import { distanceUnitLabel, toDisplayDistanceM, type UnitSystem } from '$lib/units';

	interface Picked {
		fileName: string;
		bytes: Uint8Array;
		s3Key: string;
	}

	interface Props {
		onload: (picked: Picked) => void;
		/** Unit system for the nearest-site distance display. Default metric (km). */
		unitSystem?: UnitSystem;
	}

	let { onload, unitSystem = 'metric' }: Props = $props();

	let zip = $state('');
	let geocodeStatus = $state<'idle' | 'loading' | 'not-found'>('idle');
	let nearest = $state<(RadarCatalogSite & { distanceKm: number })[]>([]);

	let selectedSite = $state<string | null>(null);

	// UTC date, since the bucket's day folders are UTC days, not the browser's local day.
	let dateStr = $state(todayUtcIsoDate());
	let scans = $state<VolumeScan[]>([]);
	let scansStatus = $state<'idle' | 'loading' | 'error' | 'ready'>('idle');
	let scansError = $state<string | null>(null);

	let loadingKey = $state<string | null>(null);
	let loadError = $state<string | null>(null);

	function todayUtcIsoDate(): string {
		return new Date().toISOString().slice(0, 10);
	}

	async function searchZip() {
		if (!zip.trim()) return;
		geocodeStatus = 'loading';
		nearest = [];
		const coords = await geocodeZip(zip.trim());
		if (!coords) {
			geocodeStatus = 'not-found';
			return;
		}
		geocodeStatus = 'idle';
		nearest = nearestSites(coords);
	}

	function selectSite(code: string) {
		selectedSite = code;
		scans = [];
		scansStatus = 'idle';
		loadError = null;
	}

	async function loadScans() {
		if (!selectedSite || !dateStr) return;
		const [year, month, day] = dateStr.split('-').map(Number);
		scansStatus = 'loading';
		scansError = null;
		try {
			scans = await listVolumeScans(selectedSite, { year, month, day });
			scansStatus = 'ready';
		} catch (err) {
			scansStatus = 'error';
			scansError = err instanceof Error ? err.message : String(err);
		}
	}

	// Re-list whenever the site or date settles on a new value.
	$effect(() => {
		void selectedSite;
		void dateStr;
		loadScans();
	});

	async function loadScan(scan: VolumeScan) {
		loadingKey = scan.key;
		loadError = null;
		try {
			const picked = await fetchVolumeScanBytes(scan.key);
			onload({ ...picked, s3Key: scan.key });
		} catch (err) {
			loadError = err instanceof Error ? err.message : String(err);
		} finally {
			loadingKey = null;
		}
	}
</script>

<div class="flex flex-col gap-4 font-mono text-label-mono">
	<section class="flex flex-col gap-2">
		<p class="text-body-sm text-on-surface-variant">
			Busca el radar más cercano por código postal (EE.UU.), o selecciónalo directo en el mapa.
		</p>
		<div class="flex gap-2">
			<input
				type="text"
				placeholder="Código postal"
				class="cyan-glow w-40 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
				bind:value={zip}
				onkeydown={(e) => e.key === 'Enter' && searchZip()}
			/>
			<button
				class="rounded bg-primary-container px-3 py-1 text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
				disabled={geocodeStatus === 'loading' || !zip.trim()}
				onclick={searchZip}
			>
				{geocodeStatus === 'loading' ? 'BUSCANDO…' : 'BUSCAR'}
			</button>
		</div>
		{#if geocodeStatus === 'not-found'}
			<p class="flex items-center gap-1 text-[11px] text-dbz-heavy">
				<span class="material-symbols-outlined text-[14px]">warning</span> No se encontró ese código postal.
			</p>
		{/if}

		{#if nearest.length > 0}
			<ul class="flex flex-wrap gap-2">
				{#each nearest as site (site.code)}
					<li>
						<button
							class="rounded border px-2 py-1 text-[12px] transition-colors {selectedSite ===
							site.code
								? 'border-primary-container bg-primary-container text-on-primary-container'
								: 'border-outline-variant bg-surface-container-high text-on-surface hover:border-primary-container'}"
							onclick={() => selectSite(site.code)}
						>
							{site.code} · {toDisplayDistanceM(site.distanceKm * 1000, unitSystem).toFixed(0)}
							{distanceUnitLabel(unitSystem)}
						</button>
					</li>
				{/each}
			</ul>
		{/if}

		<RadarSiteMap
			highlighted={nearest.map((s) => s.code)}
			selected={selectedSite}
			onselect={selectSite}
		/>
	</section>

	{#if selectedSite}
		<section class="flex flex-col gap-2 border-t border-outline-variant pt-3">
			<label class="flex flex-col gap-1">
				<span class="text-[11px] text-on-surface-variant">Fecha (UTC) — sitio {selectedSite}</span>
				<input
					type="date"
					class="cyan-glow w-44 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
					bind:value={dateStr}
				/>
			</label>

			{#if scansStatus === 'loading'}
				<p class="text-[11px] text-on-surface-variant">Buscando observaciones…</p>
			{:else if scansStatus === 'error'}
				<p class="flex items-center gap-1 text-[11px] text-dbz-heavy">
					<span class="material-symbols-outlined text-[14px]">warning</span>
					{scansError}
				</p>
			{:else if scansStatus === 'ready' && scans.length === 0}
				<p class="text-[11px] text-on-surface-variant">
					Sin observaciones para {selectedSite} ese día.
				</p>
			{:else if scansStatus === 'ready'}
				<ul class="flex max-h-56 flex-col gap-1 overflow-y-auto">
					{#each scans as scan (scan.key)}
						<li
							class="flex items-center justify-between gap-2 rounded border border-outline-variant bg-surface-container-high px-2 py-1"
						>
							<span class="text-on-surface">{scan.timestamp.toISOString().slice(11, 19)} UTC</span>
							<span class="text-[11px] text-on-surface-variant"
								>{(scan.sizeBytes / 1e6).toFixed(1)} MB</span
							>
							<button
								class="flex items-center gap-1 rounded bg-primary-container px-2 py-0.5 text-[12px] text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
								disabled={loadingKey !== null}
								onclick={() => loadScan(scan)}
							>
								{loadingKey === scan.key ? 'CARGANDO…' : 'CARGAR'}
							</button>
						</li>
					{/each}
				</ul>
			{/if}

			{#if loadError}
				<p class="flex items-center gap-1 text-[11px] text-dbz-heavy">
					<span class="material-symbols-outlined text-[14px]">warning</span>
					{loadError}
				</p>
			{/if}
		</section>
	{/if}
</div>
