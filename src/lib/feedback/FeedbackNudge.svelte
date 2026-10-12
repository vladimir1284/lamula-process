<script lang="ts">
	import { _ } from '$lib/i18n';
	import { feedbackStore } from './store.svelte';

	const store = feedbackStore;
</script>

{#if store.nudgeVisible}
	<div
		class="glass-panel absolute right-3 bottom-10 z-[9000] w-72 rounded-lg border border-outline-variant p-3 font-mono shadow-[0_0_30px_rgba(0,0,0,0.5)]"
		role="dialog"
		aria-label={$_('feedback.nudge.title')}
	>
		<p class="flex items-center gap-2 text-label-mono text-primary-container uppercase">
			<span class="material-symbols-outlined text-[18px]">feedback</span>
			{$_('feedback.nudge.title')}
		</p>
		<p class="mt-1 text-body-sm text-on-surface-variant">{$_('feedback.nudge.body')}</p>
		<div class="mt-3 flex flex-wrap justify-end gap-2 text-label-mono">
			<button
				type="button"
				class="rounded border border-outline-variant px-2 py-1 text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
				onclick={() => void store.dismissNudge()}
			>
				{$_('feedback.nudge.never')}
			</button>
			<button
				type="button"
				class="rounded border border-outline-variant px-2 py-1 text-on-surface-variant transition-colors hover:border-primary-container hover:text-primary-container"
				onclick={() => void store.snoozeNudge()}
			>
				{$_('feedback.nudge.later')}
			</button>
			<button
				type="button"
				class="rounded bg-primary-container px-2 py-1 text-on-primary-container transition-all hover:opacity-90 active:scale-95"
				onclick={() => store.acceptNudge()}
			>
				{$_('feedback.nudge.accept')}
			</button>
		</div>
	</div>
{/if}
