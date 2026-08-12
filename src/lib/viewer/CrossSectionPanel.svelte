<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import {
		buildScanMeta,
		sampleCrossSection,
		type CutLine,
		type CrossSample,
		type CrossSectionRasterResult
	} from '$lib/products/crossSection';
	import { CrossSectionRenderer } from '$lib/render/crossSectionRenderClient';
	import { distanceUnitLabel, toDisplayDistanceM, type UnitSystem } from '$lib/units';
	import { linearScale, observeContainerSize } from '$lib/viewer/chartCanvas';
	import PixiRasterView from '$lib/viewer/pixi/PixiRasterView.svelte';

	export interface CrossSectionReadout {
		distanceM: number;
		heightM: number;
		sample: CrossSample | null;
	}

	interface Props {
		/** All elevation scans of the channel (one PPI volume). */
		scans: Scan[];
		palette: Palette;
		/** The ground line to cut along (site-relative metres). */
		line: CutLine;
		/** Max height shown (m). Default 18 km. */
		maxHeightM?: number;
		/** Draw the A (start) / B (end) endpoint markers -- matches PpiMap's cut-line markers. */
		markEndpoints?: boolean;
		/** Unit system for the distance axis. Default metric (km). */
		unitSystem?: UnitSystem;
		/** 'horizontal' (default): distance along the x-axis, height along the y-axis, fit to the
		 * container's width. 'vertical': rotated 90° -- height along the x-axis (0 at the edge
		 * touching the map, growing outward), distance along the y-axis (north/`line.by` at the
		 * top, matching the map's north-up convention), fit to the container's height. For docking
		 * a N-S cut beside the map instead of above it. */
		orientation?: 'horizontal' | 'vertical';
		/** Axis lines + tick labels. Default true. Set false for a compact docked panel that has no
		 * room for tick text -- the grid (if `showGrid`) is drawn either way. */
		axisLines?: boolean;
		/** Grid lines. Default true. */
		showGrid?: boolean;
		/** Fixed thickness (px) of the height/altitude axis -- the panel's height when horizontal,
		 * width when vertical. Default 260. */
		thicknessPx?: number;
		/** Texture interpolation: false = nearest (blocky), true = linear (smoothed). */
		smooth?: boolean;
		/** Current zoom level (real pan/zoom transform scale, 1 = fit). Wheel-zoom on the plot
		 * updates this via `onZoomChange`; external controls (ZoomControl) can also drive it. */
		zoom?: number;
		onZoomChange?: (zoom: number) => void;
		onreadout?: (r: CrossSectionReadout | null) => void;
	}

	let {
		scans,
		palette,
		line,
		maxHeightM = 18_000,
		markEndpoints = false,
		unitSystem = 'metric',
		orientation = 'horizontal',
		axisLines = true,
		showGrid = true,
		thicknessPx = 260,
		smooth = false,
		zoom = 1,
		onZoomChange,
		onreadout
	}: Props = $props();

	// Same A/green, B/red convention as PpiMap's cut-line endpoint markers.
	const START_COLOR = '#22c55e';
	const END_COLOR = '#ef4444';

	// Same devicePixelRatio guard as chartCanvas.ts's setupHiDPICanvas -- kept local since it's one
	// line and PixiRasterView needs the identical value independently for its own texture upload.
	function devicePixelRatioOrOne(): number {
		return typeof devicePixelRatio !== 'undefined' && devicePixelRatio > 0 ? devicePixelRatio : 1;
	}

	let container: HTMLDivElement | undefined = $state();
	let pixiView: { getCanvas: () => HTMLCanvasElement | undefined } | undefined = $state();
	// No room needed for tick text once axisLines is off -- shrink the padding to a thin margin
	// instead of wasting it as dead space around the grid.
	const PAD = $derived(
		axisLines ? { left: 48, bottom: 28, top: 20, right: 8 } : { left: 4, bottom: 4, top: 4, right: 4 }
	);
	// The distance axis fits whichever container dimension it runs along (width when horizontal,
	// height when vertical); the height/altitude axis is a fixed thickness either way.
	const MIN_ALONG_PX = 100;
	let fitAlong = $state(720);
	const alongPx = $derived(Math.max(MIN_ALONG_PX, fitAlong));
	const PLOT_W = $derived(orientation === 'horizontal' ? alongPx : thicknessPx);
	const PLOT_H = $derived(orientation === 'horizontal' ? thicknessPx : alongPx);

	// Rebuilding the per-scan azimuth LUTs is not free -- memoize on `scans` identity instead of
	// rebuilding it on every mousemove (the bug the original synchronous version had).
	const scanMeta = $derived(buildScanMeta(scans));

	$effect(() => {
		const el = container;
		const o = orientation;
		if (!el) return;
		return observeContainerSize(el, (w, h) => {
			const size = o === 'horizontal' ? w : h;
			const pad = o === 'horizontal' ? PAD.left + PAD.right : PAD.top + PAD.bottom;
			fitAlong = Math.max(MIN_ALONG_PX, Math.round(size - pad));
		});
	});

	const renderer = new CrossSectionRenderer();
	onDestroy(() => renderer.terminate());
	let renderToken = 0;
	let raster: CrossSectionRasterResult | null = $state(null);
	let lineLengthM = $state(0);

	// Rasterizer output is always width=distance, height=altitude (the worker doesn't know about
	// screen orientation) -- for a vertical panel, rotate the buffer 90° here: new column = old row
	// reversed (altitude 0 lands at the edge nearest the map, growing outward) and new row = old
	// column reversed (distance 1 / `line.by`, e.g. north for `northSouthLine`, lands at the top,
	// matching the map's north-up convention).
	function rotate90(r: CrossSectionRasterResult): CrossSectionRasterResult {
		const { rgba, widthPx: w, heightPx: h } = r;
		const out = new Uint8ClampedArray(w * h * 4);
		for (let py = 0; py < h; py++) {
			const nx = h - 1 - py;
			for (let px = 0; px < w; px++) {
				const ny = w - 1 - px;
				const so = (py * w + px) * 4;
				const doff = (ny * h + nx) * 4;
				out[doff] = rgba[so];
				out[doff + 1] = rgba[so + 1];
				out[doff + 2] = rgba[so + 2];
				out[doff + 3] = rgba[so + 3];
			}
		}
		return { rgba: out, widthPx: h, heightPx: w, lineLengthM: r.lineLengthM };
	}

	// Rasterize off the main thread whenever scans/palette/geometry changes. A monotonic token
	// discards a stale response if a newer render was requested before this one resolved (there's
	// no built-in worker cancellation) -- same pattern as PpiMap.svelte's PpiRenderer usage.
	$effect(() => {
		const s = scans;
		const p = palette;
		const ln = line;
		const maxH = maxHeightM;
		const along = alongPx;
		const o = orientation;
		const dpr = devicePixelRatioOrOne();
		const token = ++renderToken;
		// Worker postMessage can't structured-clone a Svelte $state proxy -- snapshot to plain
		// objects before crossing the worker boundary.
		renderer
			.render($state.snapshot(s), $state.snapshot(p), {
				widthPx: Math.round(along * dpr),
				heightPx: Math.round(thicknessPx * dpr),
				maxHeightM: maxH,
				line: $state.snapshot(ln)
			})
			.then((result) => {
				if (token !== renderToken) return; // superseded
				raster = o === 'vertical' ? rotate90(result) : result;
				lineLengthM = result.lineLengthM;
			});
	});

	const xScale = $derived(
		orientation === 'horizontal'
			? linearScale([0, toDisplayDistanceM(lineLengthM, unitSystem)], [PAD.left, PAD.left + PLOT_W])
			: linearScale([0, maxHeightM / 1000], [PAD.left, PAD.left + PLOT_W])
	);
	const yScale = $derived(
		orientation === 'horizontal'
			? linearScale([0, maxHeightM / 1000], [PAD.top + PLOT_H, PAD.top])
			: linearScale(
					[0, toDisplayDistanceM(lineLengthM, unitSystem)],
					[PAD.top + PLOT_H, PAD.top]
				)
	);

	function drawEndpoints(ctx: CanvasRenderingContext2D) {
		if (!markEndpoints) return;
		const drawEndpoint = (x: number, y: number, label: string, color: string) => {
			ctx.beginPath();
			ctx.arc(x, y, 5, 0, Math.PI * 2);
			ctx.fillStyle = color;
			ctx.fill();
			ctx.strokeStyle = '#0b0f14';
			ctx.lineWidth = 1.5;
			ctx.stroke();
			ctx.font = 'bold 11px monospace';
			ctx.fillStyle = color;
			ctx.fillText(label, x - 3, y - 8);
		};
		if (orientation === 'horizontal') {
			drawEndpoint(PAD.left, PAD.top, 'A', START_COLOR);
			drawEndpoint(PAD.left + PLOT_W, PAD.top, 'B', END_COLOR);
		} else {
			// Distance axis is vertical and flipped (top = `line.by`) -- see rotate90.
			drawEndpoint(PAD.left, PAD.top, 'B', END_COLOR);
			drawEndpoint(PAD.left, PAD.top + PLOT_H, 'A', START_COLOR);
		}
	}

	function handlePlotMove(cx: number, cy: number) {
		if (!onreadout || lineLengthM === 0) return;
		let t: number;
		let heightM: number;
		if (orientation === 'horizontal') {
			t = cx / PLOT_W;
			heightM = (1 - cy / PLOT_H) * maxHeightM;
		} else {
			heightM = (cx / PLOT_W) * maxHeightM;
			t = 1 - cy / PLOT_H;
		}
		const distanceM = t * lineLengthM;
		const x = line.ax + t * (line.bx - line.ax);
		const y = line.ay + t * (line.by - line.ay);
		const sample = sampleCrossSection(scanMeta, x, y, heightM);
		onreadout({ distanceM, heightM, sample });
	}

	export function getCanvas(): HTMLCanvasElement | undefined {
		return pixiView?.getCanvas();
	}
</script>

<div bind:this={container} class="h-full w-full overflow-hidden">
	<PixiRasterView
		bind:this={pixiView}
		plotW={PLOT_W}
		plotH={PLOT_H}
		pad={PAD}
		{raster}
		{xScale}
		{yScale}
		axisOpts={{
			xFormat: (v) => `${Math.round(v)}`,
			yFormat: (v) => `${Math.round(v)}`,
			xLabel: orientation === 'horizontal' ? distanceUnitLabel(unitSystem) : 'km',
			yLabel: orientation === 'horizontal' ? 'km' : distanceUnitLabel(unitSystem),
			grid: showGrid,
			axisLines
		}}
		extraOverlay={drawEndpoints}
		{smooth}
		{zoom}
		{onZoomChange}
		onplotmove={handlePlotMove}
		onplotleave={() => onreadout?.(null)}
	/>
</div>
