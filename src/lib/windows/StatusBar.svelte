<script lang="ts">
	import { windowStore } from './windowStore.svelte';
	import { WINDOW_TYPE_ICON } from './windowTypes';

	/** Click a tab: restore if minimized, minimize if it's the focused one (toggle), else focus it. */
	function onClickTab(id: string) {
		const w = windowStore.find(id);
		if (!w) return;
		if (w.minimized) {
			windowStore.restore(id);
		} else if (windowStore.focusedId === id) {
			windowStore.minimize(id);
		} else {
			windowStore.focus(id);
		}
	}
</script>

<div
	class="flex h-7 shrink-0 items-center gap-1 border-t border-outline-variant bg-surface-container-high px-2"
>
	<span class="material-symbols-outlined shrink-0 text-[14px] text-on-surface-variant"
		>dock_to_bottom</span
	>
	<div class="flex min-w-0 flex-1 items-center gap-1 overflow-x-auto">
		{#each windowStore.windows as w (w.id)}
			<button
				type="button"
				class="flex h-5 shrink-0 items-center gap-1.5 rounded border px-2 font-mono text-[11px] uppercase transition-colors {w.id ===
					windowStore.focusedId && !w.minimized
					? 'border-primary-container/50 bg-primary-container/15 text-primary-container'
					: 'border-outline-variant text-on-surface-variant hover:border-primary-container/40 hover:text-primary-container'} {w.minimized
					? 'opacity-60'
					: ''}"
				onclick={() => onClickTab(w.id)}
				title={w.minimized ? `Restaurar ${w.title}` : w.title}
			>
				<span class="material-symbols-outlined text-[13px]">{WINDOW_TYPE_ICON[w.type]}</span>
				<span class="max-w-32 truncate">{w.title}</span>
			</button>
		{/each}
		{#if windowStore.windows.length === 0}
			<span class="font-mono text-[11px] text-on-surface-variant/50">sin ventanas abiertas</span>
		{/if}
	</div>
</div>
