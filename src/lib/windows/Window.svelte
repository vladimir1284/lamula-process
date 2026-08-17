<script lang="ts">
	import type { Snippet } from 'svelte';
	import { windowStore, type CanvasSize } from './windowStore.svelte';
	import {
		MIN_WINDOW_HEIGHT,
		MIN_WINDOW_WIDTH,
		type RadarWindow,
		type WindowRect
	} from './windowTypes';
	import { pointerDrag } from './actions/pointerDrag';
	import { snapMove, snapResize, type ResizeDir } from './snap';

	interface Props {
		window: RadarWindow;
		bounds: CanvasSize;
		/** Replaces the default `win.title` text in the title bar (e.g. MapWindow's merged
		 * time/radar/product/VCP row) -- falls back to `win.title` when not provided. */
		titleContent?: Snippet;
		children: Snippet;
	}

	let { window: win, bounds, titleContent, children }: Props = $props();

	const focused = $derived(windowStore.focusedId === win.id);

	let dragStartRect: WindowRect = { x: 0, y: 0, width: 0, height: 0 };

	function clamp(v: number, min: number, max: number): number {
		return Math.min(Math.max(v, min), Math.max(min, max));
	}

	function otherRects(): WindowRect[] {
		return windowStore.windows.filter((w) => w.id !== win.id && !w.minimized).map((w) => w.rect);
	}

	function applyGuides(guides: { vertical: number[]; horizontal: number[] }) {
		windowStore.setSnapGuides(guides.vertical.length || guides.horizontal.length ? guides : null);
	}

	const titleBarDrag = {
		onStart: () => {
			windowStore.focus(win.id);
			dragStartRect = { ...win.rect };
		},
		onMove: (dx: number, dy: number) => {
			if (win.maximized) return;
			const minVisible = 48;
			let x = clamp(
				dragStartRect.x + dx,
				-(dragStartRect.width - minVisible),
				bounds.width - minVisible
			);
			let y = clamp(dragStartRect.y + dy, 0, Math.max(0, bounds.height - 32));
			const snapped = snapMove(
				{ x, y, width: dragStartRect.width, height: dragStartRect.height },
				otherRects(),
				bounds
			);
			x += snapped.dx;
			y += snapped.dy;
			applyGuides(snapped.guides);
			windowStore.move(win.id, x, y);
		},
		onEnd: () => windowStore.setSnapGuides(null)
	};

	function resizedRect(start: WindowRect, dir: ResizeDir, dx: number, dy: number): WindowRect {
		let { x, y, width, height } = start;
		if (dir.includes('e')) {
			width = Math.max(MIN_WINDOW_WIDTH, start.width + dx);
		}
		if (dir.includes('w')) {
			width = Math.max(MIN_WINDOW_WIDTH, start.width - dx);
			x = start.x + start.width - width;
		}
		if (dir.includes('s')) {
			height = Math.max(MIN_WINDOW_HEIGHT, start.height + dy);
		}
		if (dir.includes('n')) {
			height = Math.max(MIN_WINDOW_HEIGHT, start.height - dy);
			y = start.y + start.height - height;
		}
		x = Math.max(0, x);
		y = Math.max(0, y);
		width = Math.min(width, Math.max(MIN_WINDOW_WIDTH, bounds.width - x));
		height = Math.min(height, Math.max(MIN_WINDOW_HEIGHT, bounds.height - y));
		return { x, y, width, height };
	}

	function resizeDrag(dir: ResizeDir) {
		return {
			onStart: () => {
				windowStore.focus(win.id);
				dragStartRect = { ...win.rect };
			},
			onMove: (dx: number, dy: number) => {
				if (win.maximized) return;
				const raw = resizedRect(dragStartRect, dir, dx, dy);
				const { rect, guides } = snapResize(raw, dir, otherRects(), bounds);
				applyGuides(guides);
				windowStore.resize(win.id, rect);
			},
			onEnd: () => windowStore.setSnapGuides(null)
		};
	}

	const RESIZE_HANDLES: { dir: ResizeDir; class: string }[] = [
		{ dir: 'n', class: 'top-0 left-2 right-2 h-1.5 cursor-n-resize' },
		{ dir: 's', class: 'bottom-0 left-2 right-2 h-1.5 cursor-s-resize' },
		{ dir: 'e', class: 'top-2 bottom-2 right-0 w-1.5 cursor-e-resize' },
		{ dir: 'w', class: 'top-2 bottom-2 left-0 w-1.5 cursor-w-resize' },
		{ dir: 'ne', class: 'top-0 right-0 h-3 w-3 cursor-ne-resize' },
		{ dir: 'nw', class: 'top-0 left-0 h-3 w-3 cursor-nw-resize' },
		{ dir: 'se', class: 'bottom-0 right-0 h-3 w-3 cursor-se-resize' },
		{ dir: 'sw', class: 'bottom-0 left-0 h-3 w-3 cursor-sw-resize' }
	];
</script>

{#if !win.minimized}
	<div
		class="glass-panel absolute flex flex-col overflow-hidden rounded-lg border transition-shadow {focused
			? 'border-primary-container/50 shadow-[0_0_24px_rgba(59,130,246,0.08)]'
			: 'border-outline-variant'}"
		style="left:{win.rect.x}px; top:{win.rect.y}px; width:{win.rect.width}px; height:{win.rect
			.height}px; z-index:{win.z};"
		role="group"
		aria-label={win.title}
		onpointerdown={() => windowStore.focus(win.id)}
	>
		<!-- Title bar -->
		<div
			class="flex h-8 shrink-0 items-center gap-2 border-b border-outline-variant bg-surface-container-high px-2"
		>
			<div
				use:pointerDrag={titleBarDrag}
				class="flex min-w-0 flex-1 cursor-move items-center gap-2"
			>
				<span class="material-symbols-outlined shrink-0 text-[14px] text-primary-container"
					>drag_indicator</span
				>
				{#if titleContent}
					{@render titleContent()}
				{:else}
					<span class="flex-1 truncate font-mono text-[11px] text-on-surface-variant uppercase">
						{win.title}
					</span>
				{/if}
			</div>
			<button
				type="button"
				class="flex h-5 w-5 shrink-0 items-center justify-center rounded text-on-surface-variant hover:bg-surface-variant/30 hover:text-primary-container"
				title="Minimizar"
				aria-label="Minimizar"
				onclick={() => windowStore.minimize(win.id)}
			>
				<span class="material-symbols-outlined text-[14px]">remove</span>
			</button>
			<button
				type="button"
				class="flex h-5 w-5 shrink-0 items-center justify-center rounded text-on-surface-variant hover:bg-surface-variant/30 hover:text-primary-container"
				title={win.maximized ? 'Restaurar' : 'Maximizar'}
				aria-label={win.maximized ? 'Restaurar' : 'Maximizar'}
				onclick={() => windowStore.toggleMaximize(win.id, bounds)}
			>
				<span class="material-symbols-outlined text-[14px]"
					>{win.maximized ? 'fullscreen_exit' : 'fullscreen'}</span
				>
			</button>
			<button
				type="button"
				class="flex h-5 w-5 shrink-0 items-center justify-center rounded text-on-surface-variant hover:bg-error/30 hover:text-error"
				title="Cerrar"
				aria-label="Cerrar"
				onclick={() => windowStore.close(win.id)}
			>
				<span class="material-symbols-outlined text-[14px]">close</span>
			</button>
		</div>

		<!-- Content -->
		<div class="relative min-h-0 flex-1 overflow-hidden bg-surface-container-lowest">
			{@render children()}
		</div>

		{#if !win.maximized}
			{#each RESIZE_HANDLES as h (h.dir)}
				<div
					use:pointerDrag={resizeDrag(h.dir)}
					class="absolute {h.class}"
					aria-hidden="true"
				></div>
			{/each}
		{/if}
	</div>
{/if}
