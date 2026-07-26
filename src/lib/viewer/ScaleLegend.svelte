<script lang="ts">
	import type { Palette } from '$lib/palette/types';

	interface Props {
		palette: Palette;
	}

	let { palette }: Props = $props();

	function hex(c: readonly [number, number, number]): string {
		return '#' + c.map((v) => Math.round(v).toString(16).padStart(2, '0')).join('');
	}

	// Step lookup (see palette/lookup.ts): each stop is a discrete band, so render one
	// equal-width cell per stop with its threshold beneath.
	let stops = $derived(palette.stops);
</script>

<div class="flex items-center gap-2 overflow-hidden">
	<span class="shrink-0 font-mono text-[9px] tracking-widest text-on-surface-variant uppercase"
		>{palette.name}</span
	>
	<div class="flex w-40 min-w-0 flex-col sm:w-56">
		<div class="flex h-2 overflow-hidden rounded-sm border border-outline-variant">
			{#each stops as stop, i (i)}
				<div
					class="flex-1"
					style:background-color={hex(stop.color)}
					title={`${stop.value}${stop.caption ? ` · ${stop.caption}` : ''}`}
				></div>
			{/each}
		</div>
		<div class="flex font-mono text-[10px] leading-tight text-on-surface-variant tabular-nums">
			{#each stops as stop, i (i)}
				<span class="flex-1 text-center">
					{i === 0 || i === stops.length - 1 || i % Math.ceil(stops.length / 6) === 0
						? stop.value
						: ''}
				</span>
			{/each}
		</div>
	</div>
</div>
