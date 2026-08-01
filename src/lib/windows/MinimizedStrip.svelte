<script lang="ts">
	import { windowStore } from './windowStore.svelte';
	import { WINDOW_TYPE_ICON } from './windowTypes';

	const minimized = $derived(windowStore.windows.filter((w) => w.minimized));
</script>

{#if minimized.length > 0}
	<div class="absolute bottom-2 left-2 z-[9999] flex flex-wrap gap-2">
		{#each minimized as w (w.id)}
			<div
				class="glass-panel flex items-center gap-1.5 rounded border border-outline-variant py-1 pr-1 pl-2 {w.id ===
				windowStore.focusedId
					? 'border-primary-container/40'
					: ''}"
			>
				<button
					type="button"
					class="flex items-center gap-1.5 font-mono text-[11px] text-on-surface-variant hover:text-primary-container"
					onclick={() => windowStore.restore(w.id)}
					title="Restaurar {w.title}"
				>
					<span class="material-symbols-outlined text-[14px]">{WINDOW_TYPE_ICON[w.type]}</span>
					<span class="max-w-32 truncate">{w.title}</span>
				</button>
				<button
					type="button"
					class="flex h-4 w-4 items-center justify-center rounded text-on-surface-variant hover:bg-error/30 hover:text-error"
					onclick={() => windowStore.close(w.id)}
					aria-label="Cerrar {w.title}"
					title="Cerrar"
				>
					<span class="material-symbols-outlined text-[12px]">close</span>
				</button>
			</div>
		{/each}
	</div>
{/if}
