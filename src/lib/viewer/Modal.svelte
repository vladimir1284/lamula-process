<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		open: boolean;
		title?: string;
		maxWidthClass?: string;
		onclose: () => void;
		children: Snippet;
	}

	let { open, title, maxWidthClass = 'max-w-2xl', onclose, children }: Props = $props();

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') onclose();
	}
</script>

<svelte:window onkeydown={open ? onKeydown : undefined} />

{#if open}
	<div class="fixed inset-0 z-[9999] flex items-center justify-center p-4">
		<button
			class="absolute inset-0 cursor-default border-0 bg-black/60 backdrop-blur-sm"
			onclick={onclose}
			aria-label="Cerrar"
		></button>
		<div
			class="glass-panel relative max-h-[90vh] w-full {maxWidthClass} overflow-auto rounded-xl shadow-[0_0_40px_rgba(0,0,0,0.6)]"
			role="dialog"
			aria-modal="true"
			aria-label={title}
		>
			{#if title}
				<div
					class="flex items-center justify-between border-b border-outline-variant bg-surface-container-high px-4 py-2.5"
				>
					<span
						class="flex items-center gap-2 font-mono text-label-mono tracking-tight text-on-surface-variant uppercase"
					>
						<span class="material-symbols-outlined text-[18px] text-primary-container"
							>edit_location</span
						>
						{title}
					</span>
					<button
						class="text-on-surface-variant transition-colors hover:text-primary-container"
						onclick={onclose}
						aria-label="Cerrar"
					>
						<span class="material-symbols-outlined text-[20px]">close</span>
					</button>
				</div>
			{/if}
			<div class="p-4">
				{@render children()}
			</div>
		</div>
	</div>
{/if}
