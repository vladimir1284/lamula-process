<script lang="ts">
	import type { ObservationEntry } from '$lib/pipeline/observationMachine';
	import {
		windowStore,
		isChartWindow,
		WINDOW_TYPE_ICON,
		type RadarWindow,
		type MapWindowPayload,
		type ChartWindowPayloadBase
	} from '$lib/windows';
	import { PRODUCT_GROUPS, catalogLabel } from '$lib/windows/productCatalog';
	import { _ } from '$lib/i18n';

	interface Props {
		win: RadarWindow;
		observations: ObservationEntry[];
		activeObservationId: string | null;
		onSelect: (id: string) => void;
		onClose: (id: string) => void;
	}

	let { observations, activeObservationId, onSelect, onClose }: Props = $props();

	const active = $derived(
		observations.find((e) => e.observation.id === activeObservationId) ??
			observations[observations.length - 1] ??
			null
	);

	// UTC, matching the rest of the app's fixed-UTC display convention (see MapWindow's
	// formatUtcTime/formatUtcDate).
	function formatUtcDateTime(ts: string): string {
		const d = new Date(ts);
		return isNaN(d.getTime()) ? ts : d.toISOString().replace('T', ' ').slice(0, 19) + 'Z';
	}

	interface MovementRow {
		key: string;
		kind: string;
		moment: string;
		angleDeg: number;
		numRays: number;
		numGates: number;
	}

	const movementRows = $derived.by((): MovementRow[] => {
		if (!active) return [];
		const rows: MovementRow[] = [];
		for (const movement of active.observation.movements) {
			for (const channel of movement.channels) {
				for (const scan of channel.scans) {
					rows.push({
						key: `${movement.id}-${channel.id}-${scan.id}`,
						kind: movement.kind,
						moment: channel.moment,
						angleDeg: scan.angleDeg,
						numRays: scan.numRays,
						numGates: scan.numGates
					});
				}
			}
		}
		return rows;
	});

	function fmtDeg(v: number | undefined): string {
		return v === undefined ? '—' : `${v.toFixed(4)}°`;
	}

	function fmtAlt(v: number | undefined): string {
		return v === undefined ? '—' : `${v.toFixed(0)} m`;
	}

	// Reverse lookup: which open product windows are pinned (directly, as a `map` window, or
	// transitively via a chart window's source map) to a given observation -- see `+page.svelte`'s
	// per-window `observationId` resolution.
	function windowsForObservation(id: string): RadarWindow[] {
		return windowStore.windows.filter((w) => {
			if (w.type === 'map') return (w.payload as MapWindowPayload).observationId === id;
			if (isChartWindow(w)) {
				const src = windowStore.find((w.payload as ChartWindowPayloadBase).sourceMapWindowId);
				return src ? (src.payload as MapWindowPayload).observationId === id : false;
			}
			return false;
		});
	}

	function jumpTo(id: string) {
		windowStore.restore(id);
		windowStore.focus(id);
	}

	const activeOpenWindows = $derived(active ? windowsForObservation(active.observation.id) : []);
</script>

<div class="flex h-full flex-col">
	<div
		class="flex items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2 py-1.5"
	>
		<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
			>{$_('window.observationInfoTitle')}</span
		>
	</div>

	<div class="flex min-h-0 flex-1 flex-col overflow-y-auto bg-surface-container-lowest p-3">
		{#if observations.length === 0}
			<p class="px-2 text-center font-mono text-[10px] text-on-surface-variant">
				{$_('observationInfo.empty')}
			</p>
		{:else}
			{#if observations.length > 1}
				<table class="mb-3 w-full font-mono text-[11px]">
					<thead>
						<tr class="border-b border-outline-variant text-on-surface-variant">
							<th class="py-1 pr-2 text-left font-normal">{$_('observationInfo.date')}</th>
							<th class="py-1 pr-2 text-left font-normal">{$_('observationInfo.site')}</th>
							<th class="py-1 pr-2 text-left font-normal">{$_('observationInfo.design')}</th>
							<th class="py-1 text-right font-normal"></th>
						</tr>
					</thead>
					<tbody>
						{#each observations as entry (entry.observation.id)}
							<tr
								class="border-b border-outline-variant/30"
								class:text-primary-container={entry.observation.id === activeObservationId}
							>
								<td class="py-1 pr-2">{formatUtcDateTime(entry.observation.timestamp)}</td>
								<td class="py-1 pr-2">{entry.observation.site.name}</td>
								<td class="py-1 pr-2">{entry.observation.design}</td>
								<td class="py-1 text-right whitespace-nowrap">
									{#if entry.observation.id !== activeObservationId}
										<button
											type="button"
											class="rounded border border-outline-variant px-1.5 py-0.5 text-[10px] text-on-surface-variant hover:border-primary-container hover:text-primary-container"
											onclick={() => onSelect(entry.observation.id)}
										>
											{$_('observationInfo.select')}
										</button>
									{:else}
										<span class="px-1.5 py-0.5 text-[10px] text-primary-container"
											>{$_('observationInfo.active')}</span
										>
									{/if}
									<button
										type="button"
										class="material-symbols-outlined ml-1 align-middle text-[14px] text-on-surface-variant hover:text-dbz-heavy"
										onclick={() => onClose(entry.observation.id)}
									>
										close
									</button>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{/if}

			{#if active}
				<div class="grid grid-cols-2 gap-x-4 gap-y-1 font-mono text-[11px]">
					<span class="text-on-surface-variant">{$_('observationInfo.date')}</span>
					<span class="text-on-surface">{formatUtcDateTime(active.observation.timestamp)}</span>
					<span class="text-on-surface-variant">{$_('observationInfo.file')}</span>
					<span class="truncate text-on-surface">{active.fileName}</span>
					<span class="text-on-surface-variant">{$_('observationInfo.site')}</span>
					<span class="text-on-surface"
						>{active.observation.site.name} ({active.observation.site.code})</span
					>
					<span class="text-on-surface-variant">{$_('observationInfo.coordinates')}</span>
					<span class="text-on-surface"
						>{fmtDeg(active.observation.site.lat)}, {fmtDeg(active.observation.site.lon)}, {fmtAlt(
							active.observation.site.altM
						)}</span
					>
					<span class="text-on-surface-variant">{$_('observationInfo.design')}</span>
					<span class="text-on-surface">{active.observation.design}</span>
				</div>

				<div class="mt-3 border-t border-outline-variant pt-2">
					<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
						>{$_('observationInfo.movements')}</span
					>
					<table class="mt-1 w-full font-mono text-[11px]">
						<thead>
							<tr class="border-b border-outline-variant text-on-surface-variant">
								<th class="py-1 pr-2 text-left font-normal">{$_('observationInfo.movementsNo')}</th>
								<th class="py-1 pr-2 text-left font-normal"
									>{$_('observationInfo.movementsType')}</th
								>
								<th class="py-1 pr-2 text-left font-normal"
									>{$_('observationInfo.movementsChannel')}</th
								>
								<th class="py-1 pr-2 text-right font-normal"
									>{$_('observationInfo.movementsAngle')}</th
								>
								<th class="py-1 pr-2 text-right font-normal"
									>{$_('observationInfo.movementsRays')}</th
								>
								<th class="py-1 text-right font-normal">{$_('observationInfo.movementsGates')}</th>
							</tr>
						</thead>
						<tbody>
							{#each movementRows as row, i (row.key)}
								<tr class="border-b border-outline-variant/30">
									<td class="py-1 pr-2">{i + 1}</td>
									<td class="py-1 pr-2">{row.kind}</td>
									<td class="py-1 pr-2">{row.moment}</td>
									<td class="py-1 pr-2 text-right">{row.angleDeg.toFixed(1)}</td>
									<td class="py-1 pr-2 text-right">{row.numRays}</td>
									<td class="py-1 text-right">{row.numGates}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				<div class="mt-3 border-t border-outline-variant pt-2">
					<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
						>{$_('observationInfo.products')}</span
					>
					<div class="mt-1 flex flex-wrap gap-1">
						{#each PRODUCT_GROUPS.flatMap((g) => g.items) as item (item.id)}
							<span
								class="rounded border border-outline-variant px-1.5 py-0.5 font-mono text-[10px] text-on-surface-variant"
								>{$_(catalogLabel(item.id))}</span
							>
						{/each}
					</div>
				</div>

				<div class="mt-3 border-t border-outline-variant pt-2">
					<span class="font-mono text-[10px] tracking-widest text-on-surface-variant uppercase"
						>{$_('observationInfo.openWindows')}</span
					>
					{#if activeOpenWindows.length === 0}
						<p class="mt-1 font-mono text-[10px] text-on-surface-variant">
							{$_('observationInfo.noOpenWindows')}
						</p>
					{:else}
						<div class="mt-1 flex flex-col gap-1">
							{#each activeOpenWindows as ow (ow.id)}
								<button
									type="button"
									class="flex items-center gap-2 rounded border border-outline-variant px-2 py-1 text-left font-mono text-[11px] text-on-surface-variant hover:border-primary-container hover:text-primary-container"
									onclick={() => jumpTo(ow.id)}
								>
									<span class="material-symbols-outlined text-[14px]"
										>{WINDOW_TYPE_ICON[ow.type]}</span
									>
									<span class="truncate">{ow.title}</span>
								</button>
							{/each}
						</div>
					{/if}
				</div>
			{/if}
		{/if}
	</div>
</div>
