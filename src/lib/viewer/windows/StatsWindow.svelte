<script lang="ts">
	import type { ChannelRef } from '$lib/pipeline';
	import {
		deriveGroundProduct,
		deriveOptionsFromMapPayload,
		productUsesBeamWidth
	} from '$lib/pipeline';
	import type { Observation } from '$lib/domain/types';
	import { effectiveBeamWidth } from '$lib/domain';
	import { computeStatistics, formatReportCsv, formatReportTxt } from '$lib/analysis';
	import { downloadTextFile } from '$lib/platform';
	import { buildExportFilename, WindowNotices } from '$lib/viewer';
	import {
		windowStore,
		type RadarWindow,
		type StatsWindowPayload,
		type MapWindowPayload
	} from '$lib/windows';
	import { catalogLabel } from '$lib/windows/productCatalog';
	import { _ } from '$lib/i18n';

	interface Props {
		win: RadarWindow;
		observation: Observation | null;
		channels: ChannelRef[];
		effectiveSiteAltM: number;
	}

	let { win, observation, channels, effectiveSiteAltM }: Props = $props();

	const payload = $derived(win.payload as StatsWindowPayload);

	const sourceMap = $derived(windowStore.find(payload.sourceMapWindowId));
	const sourceClosed = $derived(!sourceMap);
	const sourceMapPayload = $derived(sourceMap?.payload as MapWindowPayload | undefined);
	const sourceChannel = $derived(
		sourceMapPayload ? channels[sourceMapPayload.channelIndex]?.channel : undefined
	);

	const beamWidth = $derived(effectiveBeamWidth(sourceChannel));
	const notices = $derived(
		beamWidth.inferred && sourceMapPayload && productUsesBeamWidth(sourceMapPayload.product)
			? [
					{
						id: 'beam-width-inferred',
						message: $_('window.beamWidthInferredNotice', { values: { value: beamWidth.deg } })
					}
				]
			: []
	);

	// Recomputes the SAME ground product the source map window is currently showing, so the region
	// statistics match what's on screen (see deriveOptionsFromMapPayload's doc comment).
	const ground = $derived.by(() => {
		if (!sourceChannel || !sourceMapPayload || sourceChannel.scans.length === 0) return null;
		const opts = deriveOptionsFromMapPayload(sourceMapPayload, beamWidth.deg, effectiveSiteAltM);
		return deriveGroundProduct(sourceChannel, sourceMapPayload.product, opts);
	});

	const stats = $derived.by(() => {
		if (!payload.region || !ground || !sourceChannel) return null;
		return computeStatistics(ground.scan, {
			region: payload.region,
			moment: sourceChannel.moment,
			unit: ground.unit,
			threshold: payload.threshold
		});
	});

	const STAT_ROWS = [
		{ key: 'analysisReport.cells', get: (s: NonNullable<typeof stats>) => s.count },
		{ key: 'analysisReport.areaKm2', get: (s: NonNullable<typeof stats>) => s.areaKm2.toFixed(2) },
		{
			key: 'analysisReport.coveragePct',
			get: (s: NonNullable<typeof stats>) => s.coatingPct.toFixed(1)
		},
		{ key: 'analysisReport.max', get: (s: NonNullable<typeof stats>) => fmt(s.max) },
		{ key: 'analysisReport.min', get: (s: NonNullable<typeof stats>) => fmt(s.min) },
		{ key: 'analysisReport.mean', get: (s: NonNullable<typeof stats>) => fmt(s.meanAll) },
		{
			key: 'analysisReport.meanCovered',
			get: (s: NonNullable<typeof stats>) => fmt(s.meanCovered)
		},
		{ key: 'analysisReport.median', get: (s: NonNullable<typeof stats>) => fmt(s.median) },
		{
			key: 'analysisReport.volumeMm3',
			get: (s: NonNullable<typeof stats>) => (s.volumeMm3 === null ? '—' : s.volumeMm3.toFixed(3))
		},
		{ key: 'analysisReport.stdDev', get: (s: NonNullable<typeof stats>) => fmt(s.stdDev) }
	];

	function fmt(n: number | null): string {
		return n === null ? '—' : n.toFixed(2);
	}

	function reportMeta() {
		return {
			product: sourceMapPayload ? $_(catalogLabel(sourceMapPayload.product)) : undefined,
			timestamp: observation?.timestamp,
			generatedAt: new Date().toISOString()
		};
	}

	function exportCsv() {
		if (!stats) return;
		const filename =
			buildExportFilename([observation?.site.name, observation?.timestamp, 'STATS']) + '.csv';
		downloadTextFile(formatReportCsv([stats]), filename, 'text/csv');
	}

	function exportTxt() {
		if (!stats) return;
		const filename =
			buildExportFilename([observation?.site.name, observation?.timestamp, 'STATS']) + '.txt';
		downloadTextFile(formatReportTxt([stats], reportMeta()), filename, 'text/plain');
	}
</script>

<div class="flex h-full flex-col">
	<div
		class="flex flex-wrap items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
	>
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
			>{$_('window.statsTitle')}</span
		>
		{#if sourceClosed}
			<span class="rounded bg-dbz-heavy/20 px-2 py-0.5 font-mono text-[10px] text-dbz-heavy">
				{$_('window.sourceClosed')}
			</span>
		{/if}
		{#if payload.region}
			<button
				type="button"
				class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container"
				onclick={() => (payload.region = null)}
			>
				<span class="material-symbols-outlined text-[14px]">restart_alt</span>
				{$_('window.redo')}
			</button>
		{/if}
		<label
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2"
		>
			<span class="font-mono text-[9px] text-on-surface-variant"
				>{$_('analysisReport.threshold')}</span
			>
			<input
				type="number"
				step="1"
				class="w-14 border-none bg-transparent p-0 font-mono text-[11px] text-primary-container focus:ring-0"
				bind:value={payload.threshold}
			/>
		</label>
		<WindowNotices {notices} />
		<button
			type="button"
			class="ml-auto flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container disabled:opacity-40"
			disabled={!stats}
			onclick={exportCsv}
		>
			<span class="material-symbols-outlined text-[14px]">download</span>
			{$_('window.exportCsv')}
		</button>
		<button
			type="button"
			class="flex h-7 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-2 font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container disabled:opacity-40"
			disabled={!stats}
			onclick={exportTxt}
		>
			<span class="material-symbols-outlined text-[14px]">download</span>
			{$_('window.exportTxt')}
		</button>
	</div>

	<div class="flex min-h-0 flex-1 flex-col overflow-y-auto bg-surface-container-lowest p-3">
		{#if stats}
			<table class="w-full font-mono text-[11px]">
				<tbody>
					{#each STAT_ROWS as row (row.key)}
						<tr class="border-b border-outline-variant/30">
							<td class="py-1 pr-3 text-on-surface-variant">{$_(row.key)}</td>
							<td class="py-1 text-right text-on-surface">{row.get(stats)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		{:else}
			<p class="px-4 text-center font-mono text-[10px] text-on-surface-variant">
				{$_('window.emptyStats')}
			</p>
		{/if}
	</div>
</div>
