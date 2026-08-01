<script lang="ts">
	import type { ChannelRef } from '$lib/pipeline';
	import { volumeToRhiScan } from '$lib/products';
	import type { Scan } from '$lib/domain/types';
	import type { Observation } from '$lib/domain/types';
	import type { PaletteBook } from '$lib/platform';
	import { paletteForMoment } from '$lib/platform';
	import { formatDistanceM, formatAltitudeM, formatReading, type UnitSystem } from '$lib/units';
	import { momentUnit } from '$lib/domain';
	import {
		RhiPanel,
		ZoomControl,
		exportMapToCanvas,
		flattenOnBlack,
		downloadCanvasAsPng,
		buildExportFilename,
		composeSideBySide
	} from '$lib/viewer';
	import type { RhiReadout } from '$lib/render/rasterizeRHI';
	import {
		windowStore,
		type RadarWindow,
		type RhiWindowPayload,
		type MapWindowPayload
	} from '$lib/windows';

	interface Props {
		win: RadarWindow;
		observation: Observation | null;
		channels: ChannelRef[];
		book: PaletteBook;
		unitSystem: UnitSystem;
		onEditScale: (paletteKey: string) => void;
	}

	let { win, observation, channels, book, unitSystem, onEditScale }: Props = $props();

	const payload = $derived(win.payload as RhiWindowPayload);

	const sourceMap = $derived(windowStore.find(payload.sourceMapWindowId));
	const sourceClosed = $derived(!sourceMap);
	const sourceChannel = $derived(
		sourceMap ? channels[(sourceMap.payload as MapWindowPayload).channelIndex]?.channel : undefined
	);

	// Freeze the last-rendered raster instead of blanking when the source map window closes, so an
	// in-progress read/export isn't destroyed out from under the user.
	let lastRhiScan: Scan | null = null;
	const rhiScan = $derived.by((): Scan | null => {
		if (!sourceChannel || sourceChannel.scans.length === 0) return lastRhiScan;
		return (lastRhiScan = volumeToRhiScan(sourceChannel.scans, payload.azimuthDeg));
	});

	const palette = $derived(paletteForMoment(book, sourceChannel?.moment ?? 'dBZ'));

	let readout = $state<RhiReadout | null>(null);
	let rhiPanelRef: ReturnType<typeof RhiPanel> | undefined = $state();
	let showExportMenu = $state(false);
	let zoom = $state(1);

	async function exportCurrentImage(mode: 'both' | 'product') {
		const filename = buildExportFilename([
			observation?.site.name,
			observation?.timestamp,
			'RHI',
			sourceChannel?.moment,
			`az${payload.azimuthDeg}`,
			mode === 'both' ? 'ambos' : undefined
		]);
		const canvas = rhiPanelRef?.getCanvas();
		if (!canvas) return;
		if (mode === 'both') {
			const map = windowStore.getInstanceApi(payload.sourceMapWindowId)?.getMap?.();
			if (map) {
				const mapCanvas = await exportMapToCanvas(map as Parameters<typeof exportMapToCanvas>[0]);
				downloadCanvasAsPng(composeSideBySide(mapCanvas, flattenOnBlack(canvas)), filename);
				return;
			}
		}
		downloadCanvasAsPng(flattenOnBlack(canvas), filename);
	}
</script>

<div class="flex h-full flex-col">
	<div
		class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
	>
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase">RHI</span>
		{#if sourceClosed}
			<span class="rounded bg-dbz-heavy/20 px-2 py-0.5 font-mono text-[10px] text-dbz-heavy">
				Origen cerrado — último cuadro
			</span>
		{/if}
		<label
			class="flex h-7 items-center gap-2 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant">AZIMUT</span>
			<input
				type="range"
				min="0"
				max="359"
				step="1"
				class="w-24"
				disabled={sourceClosed}
				bind:value={payload.azimuthDeg}
			/>
			<input
				type="number"
				min="0"
				max="359"
				step="1"
				class="w-12 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				disabled={sourceClosed}
				bind:value={payload.azimuthDeg}
			/>
			<span class="font-mono text-[9px] text-on-surface-variant">°</span>
		</label>
		<label
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant">ALT MÁX</span>
			<input
				type="number"
				step="1"
				class="w-10 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				bind:value={payload.maxHeightKm}
			/>
			<span class="font-mono text-[9px] text-on-surface-variant">km</span>
		</label>
		<ZoomControl {zoom} onZoom={(z) => (zoom = z)} />
		<button
			type="button"
			class="ml-auto flex h-7 w-7 shrink-0 items-center justify-center rounded border border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:border-primary-container hover:text-primary-container"
			onclick={() => onEditScale(sourceChannel?.moment ?? 'dBZ')}
			aria-label="Editar escala"
			title="Editar escala"
		>
			<span class="material-symbols-outlined text-[14px]">palette</span>
		</button>
		<div class="relative">
			<button
				type="button"
				class="flex h-7 w-7 items-center justify-center rounded border border-outline-variant bg-surface-container-lowest text-on-surface-variant hover:border-primary-container hover:text-primary-container"
				onclick={() => (showExportMenu = !showExportMenu)}
				aria-haspopup="true"
				aria-expanded={showExportMenu}
				aria-label="Exportar imagen"
				title="Exportar imagen"
			>
				<span class="material-symbols-outlined text-[14px]">download</span>
			</button>
			{#if showExportMenu}
				<ul
					role="menu"
					class="absolute top-full right-0 z-50 mt-1 min-w-44 rounded border border-outline-variant bg-surface-container-high py-1 shadow-lg"
				>
					<li>
						<button
							class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-[11px] text-on-surface hover:bg-surface-variant/20"
							onclick={() => {
								showExportMenu = false;
								exportCurrentImage('both');
							}}
						>
							<span class="material-symbols-outlined text-[14px]">view_column_2</span> Ambos paneles
						</button>
					</li>
					<li>
						<button
							class="flex w-full items-center gap-2 px-3 py-2 text-left font-mono text-[11px] text-on-surface hover:bg-surface-variant/20"
							onclick={() => {
								showExportMenu = false;
								exportCurrentImage('product');
							}}
						>
							<span class="material-symbols-outlined text-[14px]">image</span> Solo producto
						</button>
					</li>
				</ul>
			{/if}
		</div>
	</div>

	<div class="flex min-h-0 flex-1 flex-col bg-surface-container-lowest">
		{#if rhiScan}
			<RhiPanel
				bind:this={rhiPanelRef}
				scan={rhiScan}
				{palette}
				maxHeightM={payload.maxHeightKm * 1000}
				{unitSystem}
				{zoom}
				onZoomChange={(z) => (zoom = z)}
				onreadout={(r) => (readout = r)}
			/>
		{:else}
			<p class="px-4 text-center font-mono text-[10px] text-on-surface-variant">
				Marca el azimut en el mapa de origen para ver el RHI.
			</p>
		{/if}
	</div>

	<div
		class="grid grid-cols-3 gap-px border-t border-outline-variant bg-surface-container-low font-mono"
	>
		{#if readout}
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">RANGO</p>
				<p class="text-[11px] text-on-surface">{formatDistanceM(readout.rangeM, unitSystem)}</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">ALTURA</p>
				<p class="text-[11px] text-on-surface">{formatAltitudeM(readout.heightM, unitSystem)}</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">VALOR</p>
				<p class="text-[11px] text-dbz-heavy">
					{readout.value === null
						? '—'
						: formatReading(readout.value, momentUnit(sourceChannel?.moment ?? 'dBZ'), unitSystem)}
				</p>
			</div>
		{:else}
			<div class="col-span-3 bg-surface-container-low p-2">
				<p class="text-[11px] text-on-surface-variant">
					Pasa el cursor sobre el RHI para leer valores.
				</p>
			</div>
		{/if}
	</div>
</div>
