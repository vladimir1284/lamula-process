<script lang="ts">
	interface Props {
		zoom: number;
		onZoom: (zoom: number) => void;
		min?: number;
		max?: number;
		step?: number;
	}

	let { zoom, onZoom, min = 0.5, max = 4, step = 0.25 }: Props = $props();

	function clamp(z: number): number {
		return Math.min(max, Math.max(min, z));
	}
</script>

<div
	class="flex h-7 shrink-0 items-center gap-1 rounded border border-outline-variant bg-surface-container-lowest px-1"
	title="Zoom"
>
	<button
		type="button"
		class="flex h-5 w-5 items-center justify-center rounded text-on-surface-variant hover:bg-surface-variant/30 hover:text-primary-container disabled:opacity-30"
		disabled={zoom <= min}
		aria-label="Reducir zoom"
		onclick={() => onZoom(clamp(zoom - step))}
	>
		<span class="material-symbols-outlined text-[14px]">remove</span>
	</button>
	<button
		type="button"
		class="w-11 shrink-0 text-center font-mono text-[10px] text-on-surface-variant hover:text-primary-container"
		title="Restablecer zoom"
		onclick={() => onZoom(1)}
	>
		{Math.round(zoom * 100)}%
	</button>
	<button
		type="button"
		class="flex h-5 w-5 items-center justify-center rounded text-on-surface-variant hover:bg-surface-variant/30 hover:text-primary-container disabled:opacity-30"
		disabled={zoom >= max}
		aria-label="Aumentar zoom"
		onclick={() => onZoom(clamp(zoom + step))}
	>
		<span class="material-symbols-outlined text-[14px]">add</span>
	</button>
</div>
