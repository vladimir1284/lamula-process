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
	import { linearScale, observeContainerWidth } from '$lib/viewer/chartCanvas';
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
	const PAD = { left: 48, bottom: 28, top: 20, right: 8 };
	const MIN_PLOT_W = 200;
	const BASE_PLOT_H = 260;
	let fitWidth = $state(720);
	const PLOT_W = $derived(Math.max(MIN_PLOT_W, fitWidth));
	const PLOT_H = BASE_PLOT_H;

	// Rebuilding the per-scan azimuth LUTs is not free -- memoize on `scans` identity instead of
	// rebuilding it on every mousemove (the bug the original synchronous version had).
	const scanMeta = $derived(buildScanMeta(scans));

	$effect(() => {
		const el = container;
		if (!el) return;
		return observeContainerWidth(el, (w) => {
			fitWidth = Math.max(MIN_PLOT_W, Math.round(w - PAD.left - PAD.right));
		});
	});

	const renderer = new CrossSectionRenderer();
	onDestroy(() => renderer.terminate());
	let renderToken = 0;
	let raster: CrossSectionRasterResult | null = $state(null);
	let lineLengthM = $state(0);

	// Rasterize off the main thread whenever scans/palette/geometry changes. A monotonic token
	// discards a stale response if a newer render was requested before this one resolved (there's
	// no built-in worker cancellation) -- same pattern as PpiMap.svelte's PpiRenderer usage.
	$effect(() => {
		const s = scans;
		const p = palette;
		const ln = line;
		const maxH = maxHeightM;
		const w = PLOT_W;
		const h = PLOT_H;
		const dpr = devicePixelRatioOrOne();
		const token = ++renderToken;
		// Worker postMessage can't structured-clone a Svelte $state proxy -- snapshot to plain
		// objects before crossing the worker boundary.
		renderer
			.render($state.snapshot(s), $state.snapshot(p), {
				widthPx: Math.round(w * dpr),
				heightPx: Math.round(h * dpr),
				maxHeightM: maxH,
				line: $state.snapshot(ln)
			})
			.then((result) => {
				if (token !== renderToken) return; // superseded
				raster = result;
				lineLengthM = result.lineLengthM;
			});
	});

	const xScale = $derived(
		linearScale([0, toDisplayDistanceM(lineLengthM, unitSystem)], [PAD.left, PAD.left + PLOT_W])
	);
	const yScale = $derived(linearScale([0, maxHeightM / 1000], [PAD.top + PLOT_H, PAD.top]));

	function drawEndpoints(ctx: CanvasRenderingContext2D) {
		if (!markEndpoints) return;
		const drawEndpoint = (x: number, label: string, color: string) => {
			ctx.beginPath();
			ctx.arc(x, PAD.top, 5, 0, Math.PI * 2);
			ctx.fillStyle = color;
			ctx.fill();
			ctx.strokeStyle = '#0b0f14';
			ctx.lineWidth = 1.5;
			ctx.stroke();
			ctx.font = 'bold 11px monospace';
			ctx.fillStyle = color;
			ctx.fillText(label, x - 3, PAD.top - 8);
		};
		drawEndpoint(PAD.left, 'A', START_COLOR);
		drawEndpoint(PAD.left + PLOT_W, 'B', END_COLOR);
	}

	function handlePlotMove(cx: number, cy: number) {
		if (!onreadout || lineLengthM === 0) return;
		const t = cx / PLOT_W;
		const distanceM = t * lineLengthM;
		const heightM = (1 - cy / PLOT_H) * maxHeightM;
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
			xLabel: distanceUnitLabel(unitSystem),
			yLabel: 'km'
		}}
		extraOverlay={drawEndpoints}
		{zoom}
		{onZoomChange}
		onplotmove={handlePlotMove}
		onplotleave={() => onreadout?.(null)}
	/>
</div>
