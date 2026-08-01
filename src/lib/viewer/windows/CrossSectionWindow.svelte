<script lang="ts">
	import type { ChannelRef } from '$lib/pipeline';
	import { eastWestLine, northSouthLine } from '$lib/products';
	import type { Scan } from '$lib/domain/types';
	import type { Observation } from '$lib/domain/types';
	import type { PaletteBook } from '$lib/platform';
	import { paletteForMoment } from '$lib/platform';
	import { formatDistanceM, formatAltitudeM, formatReading, type UnitSystem } from '$lib/units';
	import { momentUnit } from '$lib/domain';
	import {
		CrossSectionPanel,
		ZoomControl,
		exportMapToCanvas,
		flattenOnBlack,
		downloadCanvasAsPng,
		buildExportFilename,
		composeSideBySide
	} from '$lib/viewer';
	import type { CrossSectionReadout } from '$lib/viewer/CrossSectionPanel.svelte';
	import {
		windowStore,
		type RadarWindow,
		type CrossSectionWindowPayload,
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

	const payload = $derived(win.payload as CrossSectionWindowPayload);

	const sourceMap = $derived(windowStore.find(payload.sourceMapWindowId));
	const sourceClosed = $derived(!sourceMap);
	const sourceChannel = $derived(
		sourceMap ? channels[(sourceMap.payload as MapWindowPayload).channelIndex]?.channel : undefined
	);

	let lastScans: Scan[] | null = null;
	const scans = $derived.by((): Scan[] | null => {
		if (!sourceChannel || sourceChannel.scans.length === 0) return lastScans;
		return (lastScans = sourceChannel.scans);
	});

	const palette = $derived(paletteForMoment(book, sourceChannel?.moment ?? 'dBZ'));

	function maxRangeM(sc: Scan[]): number {
		return Math.max(...sc.map((s) => s.rangeToFirstGateM + (s.numGates - 1) * s.gateLengthM));
	}

	function presetCutLine(orientation: 'EW' | 'NS'): CrossSectionWindowPayload['line'] {
		if (!scans) return null;
		const half = maxRangeM(scans);
		return orientation === 'EW' ? eastWestLine(0, half) : northSouthLine(0, half);
	}

	let readout = $state<CrossSectionReadout | null>(null);
	let panelRef: ReturnType<typeof CrossSectionPanel> | undefined = $state();
	let showExportMenu = $state(false);
	let zoom = $state(1);

	async function exportCurrentImage(mode: 'both' | 'product') {
		const filename = buildExportFilename([
			observation?.site.name,
			observation?.timestamp,
			'CROSS_LINE',
			sourceChannel?.moment,
			mode === 'both' ? 'ambos' : undefined
		]);
		const canvas = panelRef?.getCanvas();
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
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
			>CORTE</span
		>
		{#if sourceClosed}
			<span class="rounded bg-dbz-heavy/20 px-2 py-0.5 font-mono text-[10px] text-dbz-heavy">
				Origen cerrado — último cuadro
			</span>
		{/if}
		<button
			type="button"
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container disabled:opacity-40"
			disabled={sourceClosed || !scans}
			onclick={() => (payload.line = presetCutLine('EW'))}
		>
			<span class="material-symbols-outlined text-[14px]">swap_horiz</span> Este-Oeste
		</button>
		<button
			type="button"
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container disabled:opacity-40"
			disabled={sourceClosed || !scans}
			onclick={() => (payload.line = presetCutLine('NS'))}
		>
			<span class="material-symbols-outlined text-[14px]">swap_vert</span> Norte-Sur
		</button>
		{#if payload.line}
			<button
				type="button"
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container"
				onclick={() => (payload.line = null)}
			>
				<span class="material-symbols-outlined text-[14px]">restart_alt</span> Rehacer
			</button>
		{/if}
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
		{#if scans && payload.line}
			<CrossSectionPanel
				bind:this={panelRef}
				{scans}
				{palette}
				line={payload.line}
				maxHeightM={payload.maxHeightKm * 1000}
				markEndpoints={true}
				{unitSystem}
				{zoom}
				onreadout={(r) => (readout = r)}
			/>
		{:else}
			<p class="px-4 text-center font-mono text-[10px] text-on-surface-variant">
				Traza una línea en el mapa de origen (o usa Este-Oeste/Norte-Sur) para ver el corte.
			</p>
		{/if}
	</div>

	<div
		class="grid grid-cols-3 gap-px border-t border-outline-variant bg-surface-container-low font-mono"
	>
		{#if readout}
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">DISTANCIA (A→B)</p>
				<p class="text-[11px] text-on-surface">{formatDistanceM(readout.distanceM, unitSystem)}</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">ALTURA</p>
				<p class="text-[11px] text-on-surface">{formatAltitudeM(readout.heightM, unitSystem)}</p>
			</div>
			<div class="bg-surface-container-low p-2">
				<p class="text-label-caps text-on-surface-variant">VALOR</p>
				<p class="text-[11px] text-dbz-heavy">
					{readout.sample?.value == null
						? '—'
						: formatReading(
								readout.sample.value,
								momentUnit(sourceChannel?.moment ?? 'dBZ'),
								unitSystem
							)}
				</p>
			</div>
		{:else}
			<div class="col-span-3 bg-surface-container-low p-2">
				<p class="text-[11px] text-on-surface-variant">
					Pasa el cursor sobre el corte para leer valores.
				</p>
			</div>
		{/if}
	</div>
</div>
