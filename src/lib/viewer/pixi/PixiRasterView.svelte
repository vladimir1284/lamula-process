<script lang="ts">
	import { onMount, onDestroy, untrack } from 'svelte';
	import { Application, BufferImageSource, Container, Graphics, Sprite, Texture } from 'pixi.js';
	import {
		setupHiDPICanvas,
		drawAxes,
		type LinearScale,
		type AxisOptions
	} from '$lib/viewer/chartCanvas';

	export interface RasterData {
		rgba: Uint8ClampedArray;
		widthPx: number;
		heightPx: number;
	}

	export interface Pad {
		left: number;
		top: number;
		right: number;
		bottom: number;
	}

	interface Props {
		plotW: number;
		plotH: number;
		pad: Pad;
		raster: RasterData | null;
		xScale: LinearScale;
		yScale: LinearScale;
		axisOpts?: AxisOptions;
		/** Extra content drawn on the Canvas2D overlay after the axes, e.g. CrossSection's A/B markers. */
		extraOverlay?: (ctx: CanvasRenderingContext2D) => void;
		/** Heatmap background fill, as a Pixi hex color. Default matches the panels' dark bg. */
		background?: number;
		/** Texture interpolation: false = nearest (blocky, exact cell boundaries, current default),
		 * true = linear (smoothed). */
		smooth?: boolean;
		/** Current zoom level (1 = fit, no min above 1). Wheel-zoom updates this via `onZoomChange`;
		 * external controls (e.g. ZoomControl's +/-/reset buttons) can also drive it directly. */
		zoom?: number;
		onZoomChange?: (zoom: number) => void;
		onplotmove?: (cx: number, cy: number) => void;
		onplotleave?: () => void;
	}

	let {
		plotW,
		plotH,
		pad,
		raster,
		xScale,
		yScale,
		axisOpts = {},
		extraOverlay,
		background = 0x0b0f14,
		smooth = false,
		zoom = 1,
		onZoomChange,
		onplotmove,
		onplotleave
	}: Props = $props();

	// Same devicePixelRatio guard as chartCanvas.ts's setupHiDPICanvas -- kept local rather than
	// exported from there, since it's one line and this is the only other call site.
	function devicePixelRatioOrOne(): number {
		return typeof devicePixelRatio !== 'undefined' && devicePixelRatio > 0 ? devicePixelRatio : 1;
	}

	const ZOOM_MAX = 8;

	/** Clamp a pan offset so the (zoomed) content can never reveal empty space past its own edges. */
	function clampPan(t: number, dim: number, k: number): number {
		if (k <= 1) return 0;
		const min = dim * (1 - k);
		return Math.min(0, Math.max(min, t));
	}

	/** d3-zoom-style rescale: keep the scale's range fixed, recompute its domain to whatever data
	 * now maps to that fixed range given the current pan/zoom transform. Feeding this into
	 * `drawAxes` keeps tick placement in perfect sync with the heatmap's own transform below. */
	// `origin` is the FIXED screen pixel the heatmapContainer's own position is anchored to for this
	// axis (`pad.left` for x, `pad.top` for y) -- i.e. `screenPx = origin + t + k*(base(v) - origin)`.
	// It is NOT always `base.range()[0]`: the y-scale's range is descending ([pad.top+plotH,
	// pad.top], since height 0 is at the bottom), so its range()[0] is the *bottom* pixel while the
	// container is actually anchored at pad.top (the top). Using `origin` explicitly instead of
	// assuming range()[0] keeps this correct for both scales instead of only working for x by
	// coincidence (found via a real clamp-overshoot bug: pad.left=48 produced a ~20km visible
	// overshoot panning to the domain edge, while pad.top=20's much smaller/steeper error was easy
	// to miss at a glance).
	function rescale(base: LinearScale, k: number, t: number, origin: number): LinearScale {
		const range = base.range();
		return base
			.copy()
			.domain(range.map((px) => base.invert(origin + (px - origin - t) / k)) as [number, number]);
	}

	let pixiCanvas: HTMLCanvasElement | undefined = $state();
	let overlayCanvas: HTMLCanvasElement | undefined = $state();

	let app: Application | null = null;
	let bg: Graphics | null = null;
	let mask: Graphics | null = null;
	let heatmapContainer: Container | null = null;
	let sprite: Sprite | null = null;
	let currentTexture: Texture | null = null;
	let currentDims = { widthPx: 0, heightPx: 0, dpr: 0, smooth: false };
	let ready = $state(false);

	// Pan offset (screen px, pre-scale) -- lives only here, not lifted to the caller. `zoom` (the
	// scale factor) IS lifted via the `zoom`/`onZoomChange` props so the existing ZoomControl
	// +/-/reset UI keeps working, now driving a real transform instead of a raster-resize multiplier.
	let tx = $state(0);
	let ty = $state(0);

	function boxSize() {
		return { w: pad.left + plotW + pad.right, h: pad.top + plotH + pad.bottom };
	}

	onMount(() => {
		let disposed = false;
		const { w, h } = boxSize();
		(async () => {
			const a = new Application();
			await a.init({
				canvas: pixiCanvas,
				preference: 'webgl',
				resolution: devicePixelRatioOrOne(),
				autoDensity: true,
				autoStart: false,
				backgroundAlpha: 0,
				width: w,
				height: h
			});
			if (disposed) {
				a.destroy(true);
				return;
			}
			app = a;
			bg = new Graphics();
			app.stage.addChild(bg);
			mask = new Graphics();
			heatmapContainer = new Container();
			heatmapContainer.position.set(pad.left, pad.top);
			heatmapContainer.mask = mask;
			app.stage.addChild(heatmapContainer);
			sprite = new Sprite(Texture.EMPTY);
			sprite.visible = false;
			heatmapContainer.addChild(sprite);
			ready = true;
		})();
		return () => {
			disposed = true;
		};
	});

	let resizeRaf = 0;
	onDestroy(() => {
		if (resizeRaf) cancelAnimationFrame(resizeRaf);
		currentTexture?.destroy(true);
		app?.destroy(true, { children: true, texture: true });
	});

	// Whenever zoom changes from OUTSIDE (ZoomControl's +/-/reset buttons), the existing pan offset
	// may no longer be valid for the new scale -- re-clamp it. `untrack` keeps this effect from also
	// depending on tx/ty themselves (it only needs to react to zoom/plotW/plotH changing); the wheel
	// and drag handlers already clamp inline for their own gesture-driven updates.
	$effect(() => {
		const k = zoom;
		const w = plotW;
		const h = plotH;
		untrack(() => {
			tx = clampPan(tx, w, k);
			ty = clampPan(ty, h, k);
		});
	});

	// Resize the Pixi canvas + background/mask + overlay canvas whenever the plot box dimensions,
	// axes, or pan/zoom transform change, coalesced to one requestAnimationFrame. A live window-drag
	// resize (or a drag-pan gesture) fires a reactive prop/state change per pointermove (can be
	// 60-120+/sec on a real display) -- resizing a WebGL renderer is a real GPU framebuffer
	// reallocation, not free, and calling it (or re-rendering) on every tick races the GPU driver on
	// real hardware (invisible on a software/SwiftShader renderer, which is why this doesn't
	// reproduce in a headless sandbox). Coalescing to rAF also guarantees the Pixi canvas and the
	// Canvas2D overlay always redraw in the same frame, never one ahead of the other.
	$effect(() => {
		const { w, h } = boxSize();
		const xs = xScale;
		const ys = yScale;
		const opts = axisOpts;
		const overlay = extraOverlay;
		const el = overlayCanvas;
		const k = zoom;
		const txv = tx;
		const tyv = ty;
		// `ready` flips true asynchronously (Pixi's Application.init is async) -- must be read here,
		// in the tracked/reactive part of the effect, so this effect re-runs once Pixi finishes
		// initializing even if no other prop changes afterward. Plain `let`s (app/bg/...) aren't
		// reactive and are only re-checked inside the rAF callback below.
		const isReady = ready;
		if (resizeRaf) cancelAnimationFrame(resizeRaf);
		resizeRaf = requestAnimationFrame(() => {
			resizeRaf = 0;
			if (isReady && app && bg && mask && heatmapContainer) {
				app.renderer.resize(w, h);
				heatmapContainer.position.set(pad.left + txv, pad.top + tyv);
				heatmapContainer.scale.set(k);
				bg.clear();
				bg.rect(0, 0, w, h).fill(background);
				mask.clear();
				mask.rect(pad.left, pad.top, plotW, plotH).fill(0xffffff);
				app.render();
			}
			if (el) {
				const { ctx } = setupHiDPICanvas(el, w, h);
				ctx.clearRect(0, 0, w, h);
				drawAxes(
					ctx,
					{ left: pad.left, top: pad.top, width: plotW, height: plotH },
					rescale(xs, k, txv, pad.left),
					rescale(ys, k, tyv, pad.top),
					opts
				);
				overlay?.(ctx);
			}
		});
	});

	// Swap the heatmap texture in place when a new raster arrives -- same-size updates reuse the
	// existing BufferImageSource (source.resource + source.update()), never destroying/recreating
	// the sprite/texture. This is the scrubbing-readiness requirement: a future frame-index change
	// only needs to call this same path faster, not restructure the scene graph.
	$effect(() => {
		const r = raster;
		if (!app || !ready || !sprite) return;
		if (!r) {
			sprite.visible = false;
			app.render();
			return;
		}
		const dpr = devicePixelRatioOrOne();
		sprite.visible = true;
		const sameDims =
			currentTexture &&
			currentDims.widthPx === r.widthPx &&
			currentDims.heightPx === r.heightPx &&
			currentDims.dpr === dpr &&
			currentDims.smooth === smooth;
		if (sameDims && currentTexture) {
			const source = currentTexture.source as BufferImageSource;
			source.resource = r.rgba;
			source.update();
		} else {
			// Pass the RAW device-pixel dims with the default resolution (1) -- do NOT also pass
			// `resolution: dpr`. TextureSource computes `pixelWidth = width * resolution`, so
			// `width` must already be the LOGICAL size for that to land on the real buffer's pixel
			// count; passing the device-pixel size *and* a resolution multiplier double-counts dpr,
			// silently doubling the sprite's rendered size at dpr=2 (worse at fractional dpr) -- this
			// was the actual cause of "data renders below the 0-height axis line": the oversized
			// sprite spilled past the plot rect's bottom edge while the Canvas2D axes stayed correct.
			// Sprite on-screen size is pinned explicitly via `sprite.setSize` below instead, so the
			// texture's own resolution doesn't matter here -- only the buffer's real pixel dims do.
			const source = new BufferImageSource({
				resource: r.rgba,
				width: r.widthPx,
				height: r.heightPx,
				scaleMode: smooth ? 'linear' : 'nearest',
				// Pixi's default format for a Uint8ClampedArray buffer is 'bgra8unorm' -- our
				// rasterizers write RGBA byte order (same convention as ImageData/putImageData), so
				// this must be explicit or red/blue channels swap.
				format: 'rgba8unorm'
			});
			const texture = new Texture({ source });
			sprite.texture = texture;
			sprite.setSize(plotW, plotH);
			currentTexture?.destroy(true);
			currentTexture = texture;
			currentDims = { widthPx: r.widthPx, heightPx: r.heightPx, dpr, smooth };
		}
		app.render();
	});

	let dragging = $state(false);
	let dragStart = { x: 0, y: 0, tx: 0, ty: 0 };

	function handlePointerDown(ev: PointerEvent) {
		if (ev.button !== 0) return;
		dragging = true;
		dragStart = { x: ev.clientX, y: ev.clientY, tx, ty };
		(ev.currentTarget as HTMLElement).setPointerCapture(ev.pointerId);
	}

	function handlePointerMove(ev: PointerEvent) {
		if (dragging) {
			const dx = ev.clientX - dragStart.x;
			const dy = ev.clientY - dragStart.y;
			tx = clampPan(dragStart.tx + dx, plotW, zoom);
			ty = clampPan(dragStart.ty + dy, plotH, zoom);
			return;
		}
		const rect = (ev.currentTarget as HTMLElement).getBoundingClientRect();
		const screenX = ev.clientX - rect.left - pad.left;
		const screenY = ev.clientY - rect.top - pad.top;
		const cx = (screenX - tx) / zoom;
		const cy = (screenY - ty) / zoom;
		if (cx < 0 || cx > plotW || cy < 0 || cy > plotH) {
			onplotleave?.();
			return;
		}
		onplotmove?.(cx, cy);
	}

	function handlePointerUp(ev: PointerEvent) {
		if (!dragging) return;
		dragging = false;
		(ev.currentTarget as HTMLElement).releasePointerCapture(ev.pointerId);
	}

	function handlePointerLeave() {
		// Pointer capture keeps delivering move/up events to this element even once the cursor
		// visually leaves it mid-drag -- don't clear the hover readout (there isn't one active
		// anyway while dragging) or otherwise react to a leave that isn't really a leave.
		if (dragging) return;
		onplotleave?.();
	}

	function handleWheel(ev: WheelEvent) {
		ev.preventDefault();
		const rect = (ev.currentTarget as HTMLElement).getBoundingClientRect();
		const cx = ev.clientX - rect.left - pad.left;
		const cy = ev.clientY - rect.top - pad.top;
		const k = zoom;
		const factor = Math.exp(-ev.deltaY * 0.001);
		const newK = Math.min(ZOOM_MAX, Math.max(1, k * factor));
		if (newK === k) return;
		tx = clampPan(cx - (cx - tx) * (newK / k), plotW, newK);
		ty = clampPan(cy - (cy - ty) * (newK / k), plotH, newK);
		onZoomChange?.(newK);
	}

	/** Flattens the Pixi heatmap + Canvas2D overlay into one caller-owned canvas, for PNG export. */
	export function getCanvas(): HTMLCanvasElement | undefined {
		if (!app || !overlayCanvas) return undefined;
		const flat = app.renderer.extract.canvas(app.stage) as HTMLCanvasElement;
		const out = document.createElement('canvas');
		out.width = flat.width;
		out.height = flat.height;
		const ctx = out.getContext('2d');
		if (!ctx) return undefined;
		ctx.drawImage(flat, 0, 0, out.width, out.height);
		ctx.drawImage(overlayCanvas, 0, 0, out.width, out.height);
		return out;
	}
</script>

<div
	class="relative"
	style="width: {pad.left + plotW + pad.right}px; height: {pad.top + plotH + pad.bottom}px"
>
	<canvas bind:this={pixiCanvas} class="absolute inset-0"></canvas>
	<canvas
		bind:this={overlayCanvas}
		class="absolute inset-0 {dragging ? 'cursor-grabbing' : 'cursor-grab'}"
		onpointerdown={handlePointerDown}
		onpointermove={handlePointerMove}
		onpointerup={handlePointerUp}
		onpointerleave={handlePointerLeave}
		onwheel={handleWheel}
	></canvas>
</div>
