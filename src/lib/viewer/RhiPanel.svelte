<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import { rhiReadoutAt, type RhiRasterResult, type RhiReadout } from '$lib/render/rasterizeRHI';
	import { RhiRenderer } from '$lib/render/rhiRenderClient';
	import { distanceUnitLabel, toDisplayDistanceM, type UnitSystem } from '$lib/units';
	import { linearScale, observeContainerWidth } from '$lib/viewer/chartCanvas';
	import PixiRasterView from '$lib/viewer/pixi/PixiRasterView.svelte';

	interface Props {
		scan: Scan;
		palette: Palette;
		/** Max ground range shown (m). Default = outermost gate slant range. */
		maxRangeM?: number;
		/** Max height shown (m). Default 18 km. */
		maxHeightM?: number;
		/** Unit system for the ground-range axis. Default metric (km). */
		unitSystem?: UnitSystem;
		/** Scales the plot area up/down from its container-fit size; >1 grows past the container so
		 * the scrolling wrapper (`overflow-auto`) shows scrollbars. Default 1 (fit container). */
		zoom?: number;
		onreadout?: (r: RhiReadout | null) => void;
	}

	let {
		scan,
		palette,
		maxRangeM,
		maxHeightM = 18_000,
		unitSystem = 'metric',
		zoom = 1,
		onreadout
	}: Props = $props();

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
	const PLOT_W = $derived(Math.max(MIN_PLOT_W, Math.round(fitWidth * zoom)));
	const PLOT_H = $derived(Math.round(BASE_PLOT_H * zoom));

	function rangeM(): number {
		return maxRangeM ?? scan.rangeToFirstGateM + (scan.numGates - 1) * scan.gateLengthM;
	}

	$effect(() => {
		const el = container;
		if (!el) return;
		return observeContainerWidth(el, (w) => {
			fitWidth = Math.max(MIN_PLOT_W, Math.round(w - PAD.left - PAD.right));
		});
	});

	const renderer = new RhiRenderer();
	onDestroy(() => renderer.terminate());
	let renderToken = 0;
	let raster: RhiRasterResult | null = $state(null);

	// Rasterize off the main thread whenever scan/palette/geometry changes. A monotonic token
	// discards a stale response if a newer render was requested before this one resolved (there's
	// no built-in worker cancellation) -- same pattern as PpiMap.svelte's PpiRenderer usage.
	$effect(() => {
		const s = scan;
		const p = palette;
		const maxR = rangeM();
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
				maxRangeM: maxR,
				maxHeightM: maxH
			})
			.then((result) => {
				if (token !== renderToken) return; // superseded
				raster = result;
			});
	});

	const xScale = $derived(
		linearScale([0, toDisplayDistanceM(rangeM(), unitSystem)], [PAD.left, PAD.left + PLOT_W])
	);
	const yScale = $derived(linearScale([0, maxHeightM / 1000], [PAD.top + PLOT_H, PAD.top]));

	function handlePlotMove(cx: number, cy: number) {
		if (!onreadout) return;
		const maxR = rangeM();
		const groundM = (cx / PLOT_W) * maxR;
		const heightM = (1 - cy / PLOT_H) * maxHeightM;
		onreadout(rhiReadoutAt(groundM, heightM, scan));
	}

	export function getCanvas(): HTMLCanvasElement | undefined {
		return pixiView?.getCanvas();
	}
</script>

<div bind:this={container} class="h-full w-full overflow-auto">
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
		onplotmove={handlePlotMove}
		onplotleave={() => onreadout?.(null)}
	/>
</div>
