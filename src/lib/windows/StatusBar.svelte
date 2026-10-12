<script lang="ts">
	import { _ } from '$lib/i18n';
	import { feedbackStore } from '$lib/feedback';
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
				title={w.minimized ? $_('window.restoreNamed', { values: { title: w.title } }) : w.title}
			>
				<span class="material-symbols-outlined text-[13px]">{WINDOW_TYPE_ICON[w.type]}</span>
				<span class="max-w-32 truncate">{w.title}</span>
			</button>
		{/each}
		{#if windowStore.windows.length === 0}
			<span class="font-mono text-[11px] text-on-surface-variant/50">{$_('window.noneOpen')}</span>
		{/if}
	</div>

	{#if feedbackStore.enabled}
		<button
			type="button"
			class="flex h-5 shrink-0 items-center gap-1.5 rounded border border-outline-variant px-2 font-mono text-[11px] text-on-surface-variant uppercase transition-colors hover:border-primary-container hover:text-primary-container"
			onclick={() => feedbackStore.openDialog('mine')}
			title={feedbackStore.unreadReplies > 0
				? $_('feedback.thread.unread')
				: $_('feedback.thread.badge')}
		>
			<span class="material-symbols-outlined text-[13px]">forum</span>
			{#if feedbackStore.unreadReplies > 0}
				<span class="h-1.5 w-1.5 rounded-full bg-error"></span>
			{:else if feedbackStore.pending > 0}
				<span class="material-symbols-outlined text-[13px]">schedule_send</span>
			{/if}
		</button>
	{/if}
</div>
