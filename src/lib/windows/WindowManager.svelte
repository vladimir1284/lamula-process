<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import type { Snippet } from 'svelte';
	import { windowStore, type CanvasSize } from './windowStore.svelte';
	import { loadLayout, saveLayout } from './layoutStore';
	import type { RadarWindow } from './windowTypes';
	import Window from './Window.svelte';
	import StatusBar from './StatusBar.svelte';

	interface Props {
		content: Snippet<[RadarWindow]>;
		/** Current canvas size, so callers outside this component (e.g. the "Ventana" menu's
		 * Cascada/Mosaico actions) can pass it to `windowStore.cascade`/`tile`. */
		canvasSize?: CanvasSize;
	}

	let { content, canvasSize = $bindable({ width: 0, height: 0 }) }: Props = $props();

	let canvasEl: HTMLDivElement | undefined = $state();

	onMount(() => {
		const el = canvasEl;
		if (!el) return;
		const ro = new ResizeObserver((entries) => {
			const rect = entries[0]?.contentRect;
			if (rect) canvasSize = { width: rect.width, height: rect.height };
		});
		ro.observe(el);
		return () => ro.disconnect();
	});

	onMount(() => {
		let cancelled = false;
		void loadLayout().then((layout) => {
			if (!cancelled) windowStore.hydrate(layout);
		});
		return () => {
			cancelled = true;
		};
	});

	// Debounced autosave -- absorbs the high-frequency move/resize calls fired on every
	// pointermove during a drag, while still persisting promptly after open/close/focus changes.
	let saveTimer: ReturnType<typeof setTimeout> | undefined;
	$effect(() => {
		const windows = windowStore.windows;
		const focusedId = windowStore.focusedId;
		untrack(() => {
			clearTimeout(saveTimer);
			saveTimer = setTimeout(() => {
				void saveLayout({ version: 1, windows: $state.snapshot(windows), focusedId });
			}, 500);
		});
	});
</script>

<div class="flex min-h-0 flex-1 flex-col">
	<div bind:this={canvasEl} class="relative min-h-0 flex-1 overflow-hidden">
		{#each windowStore.windows as w (w.id)}
			<Window window={w} bounds={canvasSize}>
				{@render content(w)}
			</Window>
		{/each}
		{#if windowStore.snapGuides}
			{#each windowStore.snapGuides.vertical as vx (vx)}
				<div
					class="pointer-events-none absolute top-0 bottom-0 z-50 w-px bg-primary-container/70"
					style="left:{vx}px"
				></div>
			{/each}
			{#each windowStore.snapGuides.horizontal as hy (hy)}
				<div
					class="pointer-events-none absolute right-0 left-0 z-50 h-px bg-primary-container/70"
					style="top:{hy}px"
				></div>
			{/each}
		{/if}
	</div>
	<StatusBar />
</div>
