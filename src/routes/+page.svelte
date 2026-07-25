<script lang="ts">
	import { useMachine } from '@xstate/svelte';
	import { observationMachine } from '$lib/pipeline/observationMachine';
	import {
		observationChannels,
		listElevationsDeg,
		pickScanByElevation,
		hasGeoref
	} from '$lib/pipeline/select';
	import { computeCappi } from '$lib/products/cappi';
	import { makeRhiScan } from '$lib/render/rhiFixtures';
	import { defaultDbzPalette } from '$lib/palette/default';
	import type { Palette } from '$lib/palette/types';
	import type { Scan } from '$lib/domain/types';
	import { PpiMap, RhiPanel, ScaleEditor } from '$lib/viewer';
	import { standardOverlays } from '$lib/overlays';
	import type { Readout } from '$lib/viewer/readout';
	import type { RhiReadout } from '$lib/render/rasterizeRHI';

	const { snapshot, send } = useMachine(observationMachine);

	type ProductKind = 'PPI' | 'CAPPI' | 'RHI';
	let product = $state<ProductKind>('PPI');
	let channelIndex = $state(0);
	let elevationDeg = $state(0.5);
	let cappiBottomKm = $state(1);
	let cappiTopKm = $state(3);
	let palette = $state<Palette>(defaultDbzPalette);
	let readout = $state<Readout | RhiReadout | null>(null);

	const observation = $derived($snapshot.context.observation);
	const loading = $derived($snapshot.value === 'opening' || $snapshot.value === 'parsing');
	const error = $derived($snapshot.context.error);
	const recentFiles = $derived($snapshot.context.recentFiles);

	const channels = $derived(observation ? observationChannels(observation) : []);
	const channel = $derived(channels[channelIndex]?.channel);
	const elevations = $derived(channel ? listElevationsDeg(channel) : []);
	const georef = $derived(observation ? hasGeoref(observation) : false);

	// The single Scan to render for the current selection.
	const renderScan = $derived.by((): Scan | null => {
		if (!channel || channel.scans.length === 0) return null;
		if (product === 'RHI') return makeRhiScan({ fill: (_r, g) => Math.max(0, 52 - g * 0.4) });
		if (product === 'CAPPI') {
			return computeCappi(channel.scans, {
				bottomM: cappiBottomKm * 1000,
				topM: cappiTopKm * 1000,
				moment: channel.moment,
				beamWidthDeg: channel.beamWidthDeg ?? 1.0,
				siteAltM: observation?.site.altM ?? 0
			}).scan;
		}
		return pickScanByElevation(channel, elevationDeg);
	});

	const site = $derived(
		observation && observation.site.lon !== undefined && observation.site.lat !== undefined
			? { lon: observation.site.lon, lat: observation.site.lat }
			: null
	);

	// Geo overlays are built once (they load their own GeoJSON asynchronously).
	const overlays = standardOverlays();

	function fmt(n: number | null | undefined, digits = 1): string {
		return n === null || n === undefined ? '—' : n.toFixed(digits);
	}
</script>

<main class="mx-auto flex max-w-5xl flex-col gap-4 p-6">
	<div class="flex items-center justify-between">
		<h1 class="text-2xl font-semibold">LAMULA Process</h1>
		<button
			class="rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50"
			onclick={() => send({ type: 'OPEN' })}
			disabled={loading}
		>
			{loading ? 'Abriendo…' : 'Abrir archivo'}
		</button>
	</div>

	{#if error}
		<p class="text-red-600">{error}</p>
	{/if}

	{#if observation}
		<section class="rounded border border-gray-300 p-3 text-sm">
			<div class="flex flex-wrap gap-x-6 gap-y-1">
				<span><span class="text-gray-500">Sitio:</span> {observation.site.name}</span>
				<span><span class="text-gray-500">Fecha:</span> {observation.timestamp}</span>
				<span><span class="text-gray-500">Diseño:</span> {observation.design}</span>
			</div>
		</section>

		<!-- Controls -->
		<section class="flex flex-wrap items-end gap-4 text-sm">
			<label class="flex flex-col gap-1">
				<span class="text-gray-500">Producto</span>
				<select class="rounded border border-gray-300 px-2 py-1" bind:value={product}>
					<option value="PPI">PPI</option>
					<option value="CAPPI">CAPPI</option>
					<option value="RHI">RHI (sintético)</option>
				</select>
			</label>

			<label class="flex flex-col gap-1">
				<span class="text-gray-500">Canal</span>
				<select class="rounded border border-gray-300 px-2 py-1" bind:value={channelIndex}>
					{#each channels as ref (ref.index)}
						<option value={ref.index}>{ref.channel.moment} ({ref.channel.scans.length})</option>
					{/each}
				</select>
			</label>

			{#if product === 'PPI'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Elevación</span>
					<select class="rounded border border-gray-300 px-2 py-1" bind:value={elevationDeg}>
						{#each elevations as e (e)}
							<option value={e}>{e.toFixed(1)}°</option>
						{/each}
					</select>
				</label>
			{/if}

			{#if product === 'CAPPI'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Base (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={cappiBottomKm}
						step="0.5"
					/>
				</label>
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Tope (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={cappiTopKm}
						step="0.5"
					/>
				</label>
			{/if}
		</section>

		<!-- Readout -->
		<div class="text-sm text-gray-600">
			{#if readout && 'azimuthDeg' in readout}
				Az {fmt(readout.azimuthDeg)}° · Rango {fmt(readout.rangeM / 1000)} km · Valor
				{readout.value === null ? '—' : fmt(readout.value)}
				{readout.flag && readout.flag !== 'ok' ? `(${readout.flag})` : ''}
			{:else if readout && 'heightM' in readout}
				Rango {fmt(readout.rangeM / 1000)} km · Altura {fmt(readout.heightM / 1000, 2)} km · Valor {readout.value ===
				null
					? '—'
					: fmt(readout.value)}
			{:else}
				&nbsp;
			{/if}
		</div>

		<!-- Viewer -->
		<section class="h-[520px] overflow-hidden rounded border border-gray-300">
			{#if product === 'RHI'}
				{#if renderScan}
					<div class="p-2">
						<p class="mb-2 text-xs text-amber-700">
							RHI sintético — ningún formato de entrada trae RHI real; geometría verificada contra
							datos sintéticos.
						</p>
						<RhiPanel scan={renderScan} {palette} onreadout={(r) => (readout = r)} />
					</div>
				{/if}
			{:else if !georef || !site}
				<div class="flex h-full items-center justify-center p-4 text-center text-sm text-gray-500">
					Este formato no trae posición del sitio (p. ej. NEXRAD L2 msg-31), no se puede
					georreferenciar el {product}. RHI sí funciona.
				</div>
			{:else if renderScan}
				<PpiMap
					scan={renderScan}
					{palette}
					{site}
					extraLayers={overlays}
					onreadout={(r) => (readout = r)}
				/>
			{/if}
		</section>

		<!-- Scale editor -->
		<section class="rounded border border-gray-300 p-3">
			<h2 class="mb-2 font-semibold">Editor de escala</h2>
			<ScaleEditor {palette} onchange={(p) => (palette = p)} />
		</section>
	{/if}

	{#if recentFiles.length > 0}
		<section class="text-sm">
			<h2 class="font-semibold">Recientes</h2>
			<ul class="mt-1 text-gray-600">
				{#each recentFiles as name (name)}
					<li>{name}</li>
				{/each}
			</ul>
		</section>
	{/if}
</main>
