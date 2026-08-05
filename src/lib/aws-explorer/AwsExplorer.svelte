<script lang="ts">
	import { SvelteSet } from 'svelte/reactivity';
	import RadarSiteMap from './RadarSiteMap.svelte';
	import {
		geocodeZip,
		nearestSites,
		US_RADAR_SITES,
		CO_RADAR_SITES,
		type RadarCatalogSite
	} from './radarCatalog';
	import * as nexradS3 from './nexradS3';
	import * as ideamS3 from './ideamS3';
	import type { VolumeScan } from './nexradS3';
	import { distanceUnitLabel, toDisplayDistanceM, type UnitSystem } from '$lib/units';
	import { _ } from '$lib/i18n';

	interface Picked {
		fileName: string;
		bytes: Uint8Array;
		s3Key: string;
	}

	interface Props {
		onload: (picked: Picked) => void;
		/** Colombia-only: fires when a picked volume has more than one sweep file to merge (see
		 * domain/mergeSweeps.ts) -- US NEXRAD volumes are always a single file and never use this. */
		onloadVolume: (picked: Picked[]) => void;
		/** Unit system for the nearest-site distance display. Default metric (km). */
		unitSystem?: UnitSystem;
	}

	let { onload, onloadVolume, unitSystem = 'metric' }: Props = $props();

	type Source = 'us' | 'co';
	// Each bucket has its own client (nexradS3.ts / ideamS3.ts) and site catalog; picking the
	// source picks which of both this component talks to for the rest of the flow.
	const SOURCES: Record<
		Source,
		{ client: typeof nexradS3; sites: RadarCatalogSite[]; center: [number, number]; zoom: number }
	> = {
		us: { client: nexradS3, sites: US_RADAR_SITES, center: [-96, 39], zoom: 4 },
		co: { client: ideamS3, sites: CO_RADAR_SITES, center: [-74, 4], zoom: 5 }
	};

	let source = $state<Source>('us');
	let client = $derived(SOURCES[source].client);
	let sites = $derived(SOURCES[source].sites);

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

	function selectSource(next: Source) {
		if (next === source) return;
		source = next;
		zip = '';
		geocodeStatus = 'idle';
		nearest = [];
		selectSite(null);
	}

	async function searchZip() {
		if (!zip.trim()) return;
		geocodeStatus = 'loading';
		nearest = [];
		const coords = await geocodeZip(zip.trim(), source);
		if (!coords) {
			geocodeStatus = 'not-found';
			return;
		}
		geocodeStatus = 'idle';
		nearest = nearestSites(coords, sites);
	}

	function selectSite(code: string | null) {
		selectedSite = code;
		scans = [];
		scansStatus = 'idle';
		loadError = null;
		selectedKeys.clear();
	}

	async function loadScans() {
		if (!selectedSite || !dateStr) return;
		const [year, month, day] = dateStr.split('-').map(Number);
		scansStatus = 'loading';
		scansError = null;
		selectedKeys.clear();
		try {
			scans = await client.listVolumeScans(selectedSite, { year, month, day });
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
			const picked = await client.fetchVolumeScanBytes(scan.key);
			onload({ ...picked, s3Key: scan.key });
		} catch (err) {
			loadError = err instanceof Error ? err.message : String(err);
		} finally {
			loadingKey = null;
		}
	}

	// Colombia only: both IDEAM formats are one-elevation-sweep-per-file, and there's no reliable
	// way to auto-detect which sweeps belong to the same volume from the listing alone -- verified
	// live against a real day's Corozal listing, consecutive sweeps are ~26-30s apart *all day*
	// with no gap marking where one volume ends and the next begins (an earlier gap-based grouping
	// attempt lumped an entire day into one "volume" of 3000+ sweeps). So instead: the user
	// explicitly checks the sweeps they want, and "load N selected" fetches+merges them (see
	// domain/mergeSweeps.ts), still hiding the fetch/parse/merge mechanics behind one click.
	const selectedKeys = new SvelteSet<string>();

	function toggleSelected(key: string) {
		if (selectedKeys.has(key)) selectedKeys.delete(key);
		else selectedKeys.add(key);
	}

	async function loadSelected() {
		const keys = [...selectedKeys];
		if (keys.length === 0) return;
		loadingKey = 'selection';
		loadError = null;
		try {
			if (keys.length === 1) {
				const picked = await client.fetchVolumeScanBytes(keys[0]);
				onload({ ...picked, s3Key: keys[0] });
				return;
			}
			const picked = await Promise.all(
				keys.map(async (key) => {
					const p = await client.fetchVolumeScanBytes(key);
					return { ...p, s3Key: key };
				})
			);
			onloadVolume(picked);
		} catch (err) {
			loadError = err instanceof Error ? err.message : String(err);
		} finally {
			loadingKey = null;
		}
	}
</script>

<div class="flex flex-col gap-4 font-mono text-label-mono">
	<section class="flex flex-col gap-2">
		<div class="flex gap-2">
			<button
				class="rounded border px-2 py-1 text-[12px] transition-colors {source === 'us'
					? 'border-primary-container bg-primary-container text-on-primary-container'
					: 'border-outline-variant bg-surface-container-high text-on-surface hover:border-primary-container'}"
				onclick={() => selectSource('us')}
			>
				{$_('awsExplorer.sourceUs')}
			</button>
			<button
				class="rounded border px-2 py-1 text-[12px] transition-colors {source === 'co'
					? 'border-primary-container bg-primary-container text-on-primary-container'
					: 'border-outline-variant bg-surface-container-high text-on-surface hover:border-primary-container'}"
				onclick={() => selectSource('co')}
			>
				{$_('awsExplorer.sourceCo')}
			</button>
		</div>

		<p class="text-body-sm text-on-surface-variant">
			{$_(source === 'us' ? 'awsExplorer.searchHint' : 'awsExplorer.searchHintCo')}
		</p>
		<div class="flex gap-2">
			<input
				type="text"
				placeholder={$_('awsExplorer.zipPlaceholder')}
				class="cyan-glow w-40 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
				bind:value={zip}
				onkeydown={(e) => e.key === 'Enter' && searchZip()}
			/>
			<button
				class="rounded bg-primary-container px-3 py-1 text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
				disabled={geocodeStatus === 'loading' || !zip.trim()}
				onclick={searchZip}
			>
				{geocodeStatus === 'loading' ? $_('awsExplorer.searching') : $_('awsExplorer.search')}
			</button>
		</div>
		{#if geocodeStatus === 'not-found'}
			<p class="flex items-center gap-1 text-[11px] text-dbz-heavy">
				<span class="material-symbols-outlined text-[14px]">warning</span>
				{$_('awsExplorer.zipNotFound')}
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
			{sites}
			center={SOURCES[source].center}
			zoom={SOURCES[source].zoom}
			highlighted={nearest.map((s) => s.code)}
			selected={selectedSite}
			onselect={selectSite}
		/>
	</section>

	{#if selectedSite}
		<section class="flex flex-col gap-2 border-t border-outline-variant pt-3">
			<label class="flex flex-col gap-1">
				<span class="text-[11px] text-on-surface-variant"
					>{$_('awsExplorer.dateForSite', { values: { site: selectedSite } })}</span
				>
				<input
					type="date"
					class="cyan-glow w-44 rounded border border-outline-variant bg-surface-container-high px-2 py-1 text-primary-container focus:ring-0"
					bind:value={dateStr}
				/>
			</label>

			{#if scansStatus === 'loading'}
				<p class="text-[11px] text-on-surface-variant">{$_('awsExplorer.loadingScans')}</p>
			{:else if scansStatus === 'error'}
				<div class="text-[11px] text-dbz-heavy">
					<p class="flex items-center gap-1">
						<span class="material-symbols-outlined text-[14px]">warning</span>
						{$_('awsExplorer.scansError')}
					</p>
					<details class="ml-[18px]">
						<summary class="cursor-pointer text-dbz-heavy/80 hover:text-dbz-heavy">
							{$_('common.showTechnicalDetail')}
						</summary>
						<p class="mt-1 break-all text-dbz-heavy/80">{scansError}</p>
					</details>
				</div>
			{:else if scansStatus === 'ready' && scans.length === 0}
				<p class="text-[11px] text-on-surface-variant">
					{$_('awsExplorer.noScans', { values: { site: selectedSite } })}
				</p>
			{:else if scansStatus === 'ready'}
				{#if source === 'co'}
					<p class="text-[11px] text-on-surface-variant">{$_('awsExplorer.selectHintCo')}</p>
				{/if}
				<ul class="flex max-h-56 flex-col gap-1 overflow-y-auto">
					{#each scans as scan (scan.key)}
						<li
							class="flex items-center justify-between gap-2 rounded border border-outline-variant bg-surface-container-high px-2 py-1"
						>
							<span class="flex items-center gap-2">
								{#if source === 'co'}
									<input
										type="checkbox"
										checked={selectedKeys.has(scan.key)}
										onchange={() => toggleSelected(scan.key)}
									/>
								{/if}
								<span class="text-on-surface">{scan.timestamp.toISOString().slice(11, 19)} UTC</span
								>
							</span>
							<span class="text-[11px] text-on-surface-variant"
								>{(scan.sizeBytes / 1e6).toFixed(1)} MB</span
							>
							<button
								class="flex items-center gap-1 rounded bg-primary-container px-2 py-0.5 text-[12px] text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
								disabled={loadingKey !== null}
								onclick={() => loadScan(scan)}
							>
								{loadingKey === scan.key ? $_('awsExplorer.loading') : $_('awsExplorer.load')}
							</button>
						</li>
					{/each}
				</ul>
				{#if source === 'co' && selectedKeys.size > 0}
					<button
						class="flex items-center justify-center gap-1 rounded bg-primary-container px-3 py-1.5 text-[12px] text-on-primary-container transition-all hover:opacity-90 active:scale-95 disabled:opacity-50"
						disabled={loadingKey !== null}
						onclick={loadSelected}
					>
						{loadingKey === 'selection'
							? $_('awsExplorer.loading')
							: $_('awsExplorer.loadSelected', { values: { count: selectedKeys.size } })}
					</button>
				{/if}
			{/if}

			{#if loadError}
				<div class="text-[11px] text-dbz-heavy">
					<p class="flex items-center gap-1">
						<span class="material-symbols-outlined text-[14px]">warning</span>
						{$_('awsExplorer.loadError')}
					</p>
					<details class="ml-[18px]">
						<summary class="cursor-pointer text-dbz-heavy/80 hover:text-dbz-heavy">
							{$_('common.showTechnicalDetail')}
						</summary>
						<p class="mt-1 break-all text-dbz-heavy/80">{loadError}</p>
					</details>
				</div>
			{/if}
		</section>
	{/if}
</div>
