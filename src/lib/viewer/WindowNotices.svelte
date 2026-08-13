<script lang="ts" module>
	export interface WindowNotice {
		id: string;
		message: string;
	}
</script>

<script lang="ts">
	import { _ } from '$lib/i18n';

	interface Props {
		notices: WindowNotice[];
	}

	let { notices }: Props = $props();

	let open = $state(false);
	let root: HTMLElement | undefined = $state();

	function handleWindowClick(e: MouseEvent) {
		if (root && !root.contains(e.target as Node)) open = false;
	}

	function handleKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') open = false;
	}
</script>

<svelte:window onclick={handleWindowClick} onkeydown={handleKeydown} />

{#if notices.length > 0}
	<div class="relative" bind:this={root}>
		<button
			type="button"
			class="flex h-7 w-7 items-center justify-center rounded border border-outline-variant bg-surface-container-lowest text-dbz-heavy hover:border-dbz-heavy"
			onclick={() => (open = !open)}
			aria-haspopup="true"
			aria-expanded={open}
			aria-label={$_('window.notices')}
			title={$_('window.notices')}
		>
			<span class="material-symbols-outlined text-[14px]">warning</span>
		</button>
		{#if open}
			<ul
				role="menu"
				class="absolute top-full right-0 z-50 mt-1 w-72 rounded border border-outline-variant bg-surface-container-high py-1 shadow-lg"
			>
				{#each notices as notice (notice.id)}
					<li
						class="flex items-start gap-2 px-3 py-2 text-left font-mono text-[11px] text-on-surface"
					>
						<span class="material-symbols-outlined shrink-0 text-[14px] text-dbz-heavy"
							>warning</span
						>
						<span>{notice.message}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</div>
{/if}
