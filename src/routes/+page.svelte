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
		ScaleEditor
	} from '$lib/viewer';
	import { standardOverlays } from '$lib/overlays';
	import type { Readout } from '$lib/viewer/readout';
	import type { RhiReadout } from '$lib/render/rasterizeRHI';

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

	const observation = $derived($snapshot.context.observation);
	const loading = $derived($snapshot.value === 'opening' || $snapshot.value === 'parsing');
	const error = $derived($snapshot.context.error);
	const recentFiles = $derived($snapshot.context.recentFiles);

	const channels = $derived(observation ? observationChannels(observation) : []);
	const channel = $derived(channels[channelIndex]?.channel);
	const elevations = $derived(channel ? listElevationsDeg(channel) : []);
	const georef = $derived(observation ? hasGeoref(observation) : false);

	const isGround = $derived(GROUND_KINDS.includes(product as GroundProductKind));
	// Products that use a standalone canvas panel (no georeferencing required).
	const usesElevation = $derived(
		product === 'PPI' || product === 'RAIN' || product === 'WIND_SPEED'
	);

	function maxRangeM(ch: NonNullable<typeof channel>): number {
		return Math.max(...ch.scans.map((s) => s.rangeToFirstGateM + (s.numGates - 1) * s.gateLengthM));
	}

	const deriveOpts = $derived<DeriveOptions>({
		elevationDeg,
		beamWidthDeg: channel?.beamWidthDeg ?? 1.0,
		siteAltM: observation?.site.altM ?? 0,
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
			siteAltM: observation?.site.altM ?? 0
		});
	});

	const site = $derived(
		observation && observation.site.lon !== undefined && observation.site.lat !== undefined
			? { lon: observation.site.lon, lat: observation.site.lat }
			: null
	);

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
					<optgroup label="Base">
						<option value="PPI">PPI</option>
						<option value="CAPPI">CAPPI</option>
					</optgroup>
					<optgroup label="Columna">
						<option value="TOPS">Topes (echo tops)</option>
						<option value="MAXS_HEIGHT">Altura del máximo</option>
						<option value="COLUMN_MAX">Máximo de columna</option>
						<option value="VIL">VIL</option>
					</optgroup>
					<optgroup label="Precip./Viento">
						<option value="RAIN">Tasa de lluvia (Z-R)</option>
						<option value="WIND_SPEED">Viento (VAD)</option>
					</optgroup>
					<optgroup label="Cortes">
						<option value="CROSS_EW">Corte Este-Oeste</option>
						<option value="CROSS_NS">Corte Norte-Sur</option>
						<option value="PROFILE">Perfil vertical</option>
						<option value="RHI">RHI</option>
					</optgroup>
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

			{#if usesElevation}
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

			{#if product === 'TOPS'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Umbral (dBZ)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={topsMinDbz}
						step="1"
					/>
				</label>
			{/if}

			{#if product === 'VIL'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Base (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={vilBottomKm}
						step="0.5"
					/>
				</label>
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Tope (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={vilTopKm}
						step="0.5"
					/>
				</label>
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">C1</span>
					<input
						type="number"
						class="w-24 rounded border border-gray-300 px-2 py-1"
						bind:value={vilC1}
						step="0.0001"
					/>
				</label>
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">C2</span>
					<input
						type="number"
						class="w-24 rounded border border-gray-300 px-2 py-1"
						bind:value={vilC2}
						step="0.0001"
					/>
				</label>
			{/if}

			{#if product === 'RAIN'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Z-R A</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={zrA}
						step="10"
					/>
				</label>
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Z-R B</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={zrB}
						step="0.1"
					/>
				</label>
			{/if}

			{#if product === 'RHI'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Azimut: {rhiAzimuthDeg}°</span>
					<div class="flex items-center gap-2">
						<input
							type="range"
							class="w-48"
							bind:value={rhiAzimuthDeg}
							min="0"
							max="359"
							step="1"
						/>
						<input
							type="number"
							class="w-20 rounded border border-gray-300 px-2 py-1"
							bind:value={rhiAzimuthDeg}
							step="1"
							min="0"
							max="359"
						/>
					</div>
				</label>
			{/if}

			{#if product === 'CROSS_EW' || product === 'CROSS_NS' || product === 'PROFILE' || product === 'RHI'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Altura máx (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={maxHeightKm}
						step="1"
					/>
				</label>
			{/if}

			{#if product === 'PROFILE'}
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">X este (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={profileXkm}
						step="1"
					/>
				</label>
				<label class="flex flex-col gap-1">
					<span class="text-gray-500">Y norte (km)</span>
					<input
						type="number"
						class="w-20 rounded border border-gray-300 px-2 py-1"
						bind:value={profileYkm}
						step="1"
					/>
				</label>
			{/if}

			{#if ground}
				<span class="self-center rounded bg-gray-100 px-2 py-1 text-gray-600"
					>unidad: {ground.unit}</span
				>
			{/if}
		</section>

		<!-- Readout -->
		<div class="text-sm text-gray-600">
			{#if readout && 'azimuthDeg' in readout}
				Az {fmt(readout.azimuthDeg)}° · Rango {fmt(readout.rangeM / 1000)} km · Valor
				{readout.value === null ? '—' : fmt(readout.value)}
				{readout.flag && readout.flag !== 'ok' ? `(${readout.flag})` : ''}
			{:else if readout && 'heightM' in readout}
				Rango {fmt(readout.rangeM / 1000)} km · Altura {fmt(readout.heightM / 1000, 2)} km · Valor
				{readout.value === null ? '—' : fmt(readout.value)}
			{:else}
				&nbsp;
			{/if}
		</div>

		<!-- Viewer -->
		<section class="h-[520px] overflow-hidden rounded border border-gray-300">
			{#if product === 'RHI' && rhiScan}
				<div class="flex flex-wrap gap-4 p-2">
					{#if rhiBaseScan}
						<div class="flex flex-col gap-1">
							<span class="text-xs text-gray-500">Azimut del corte (arrastra) · fondo: máx de columna</span>
							<RhiAzimuthPicker
								scan={rhiBaseScan}
								{palette}
								azimuthDeg={rhiAzimuthDeg}
								onchange={(a) => (rhiAzimuthDeg = a)}
							/>
						</div>
					{/if}
					<div class="min-w-[420px] flex-1">
						<p class="mb-2 text-xs text-gray-500">
							RHI reconstruido del volumen al azimut {rhiAzimuthDeg}°: un rayo por elevación ({rhiScan.numRays}
							tumbos). La resolución vertical la limita el número de elevaciones; hay huecos entre haces.
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
				<div class="p-2">
					<p class="mb-2 text-xs text-gray-500">
						Corte vertical (muestreo inverso por píxel; no georreferenciado, funciona sin posición
						de sitio).
					</p>
					<CrossSectionPanel
						scans={channel.scans}
						{palette}
						line={cutLine}
						maxHeightM={maxHeightKm * 1000}
					/>
				</div>
			{:else if product === 'PROFILE' && profile}
				<div class="flex gap-4 p-2">
					<ProfilePanel {profile} valueLabel={channel?.moment ?? 'dBZ'} />
					<p class="text-xs text-gray-500">
						Perfil vertical en (E {profileXkm} km, N {profileYkm} km): una muestra por elevación, interpolada
						por spline cúbico.
					</p>
				</div>
			{:else if isGround}
				{#if !georef || !site}
					<div
						class="flex h-full items-center justify-center p-4 text-center text-sm text-gray-500"
					>
						Este formato no trae posición del sitio (p. ej. NEXRAD L2 msg-31), no se puede
						georreferenciar el {product}. Cortes y perfil sí funcionan.
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
