<script lang="ts">
	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import { rasterizeRHI, rhiReadoutAt, type RhiReadout } from '$lib/render/rasterizeRHI';
	import { distanceUnitLabel, toDisplayDistanceM, type UnitSystem } from '$lib/units';
	import {
		setupHiDPICanvas,
		linearScale,
		drawAxes,
		observeContainerWidth
	} from '$lib/viewer/chartCanvas';

	interface Props {
		scan: Scan;
		palette: Palette;
		/** Max ground range shown (m). Default = outermost gate slant range. */
		maxRangeM?: number;
		/** Max height shown (m). Default 18 km. */
		maxHeightM?: number;
		/** Unit system for the ground-range axis. Default metric (km). */
		unitSystem?: UnitSystem;
		onreadout?: (r: RhiReadout | null) => void;
	}

	let {
		scan,
		palette,
		maxRangeM,
		maxHeightM = 18_000,
		unitSystem = 'metric',
		onreadout
	}: Props = $props();

	let container: HTMLDivElement | undefined = $state();
	let canvas: HTMLCanvasElement | undefined = $state();
	const PAD = { left: 48, bottom: 28, top: 20, right: 8 };
	const MIN_PLOT_W = 200;
	let PLOT_W = $state(720);
	const PLOT_H = 260;

	function rangeM(): number {
		return maxRangeM ?? scan.rangeToFirstGateM + (scan.numGates - 1) * scan.gateLengthM;
	}

	$effect(() => {
		const el = container;
		if (!el) return;
		return observeContainerWidth(el, (w) => {
			PLOT_W = Math.max(MIN_PLOT_W, Math.round(w - PAD.left - PAD.right));
		});
	});

	$effect(() => {
		const el = canvas;
		if (!el) return;
		const { ctx, dpr } = setupHiDPICanvas(
			el,
			PAD.left + PLOT_W + PAD.right,
			PAD.top + PLOT_H + PAD.bottom
		);
		const maxR = rangeM();

		// Rasterize at physical (device-pixel) resolution so the heatmap is as crisp as the axes.
		const raster = rasterizeRHI(scan, palette, {
			widthPx: Math.round(PLOT_W * dpr),
			heightPx: Math.round(PLOT_H * dpr),
			maxRangeM: maxR,
			maxHeightM
		});

		ctx.clearRect(0, 0, PAD.left + PLOT_W + PAD.right, PAD.top + PLOT_H + PAD.bottom);
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, PAD.left + PLOT_W + PAD.right, PAD.top + PLOT_H + PAD.bottom);

		const img = ctx.createImageData(raster.widthPx, raster.heightPx);
		img.data.set(raster.rgba);
		// putImageData always writes raw device pixels, ignoring the dpr transform above.
		ctx.putImageData(img, Math.round(PAD.left * dpr), Math.round(PAD.top * dpr));

		const xScale = linearScale(
			[0, toDisplayDistanceM(maxR, unitSystem)],
			[PAD.left, PAD.left + PLOT_W]
		);
		const yScale = linearScale([0, maxHeightM / 1000], [PAD.top + PLOT_H, PAD.top]);
		drawAxes(ctx, { left: PAD.left, top: PAD.top, width: PLOT_W, height: PLOT_H }, xScale, yScale, {
			xFormat: (v) => `${Math.round(v)}`,
			yFormat: (v) => `${Math.round(v)}`,
			xLabel: distanceUnitLabel(unitSystem),
			yLabel: 'km'
		});
	});

	function handleMove(ev: MouseEvent) {
		if (!onreadout || !canvas) return;
		const rect = canvas.getBoundingClientRect();
		const cx = ev.clientX - rect.left - PAD.left;
		const cy = ev.clientY - rect.top - PAD.top;
		if (cx < 0 || cx > PLOT_W || cy < 0 || cy > PLOT_H) {
			onreadout(null);
			return;
		}
		const maxR = rangeM();
		const groundM = (cx / PLOT_W) * maxR;
		const heightM = (1 - cy / PLOT_H) * maxHeightM;
		onreadout(rhiReadoutAt(groundM, heightM, scan));
	}

	export function getCanvas(): HTMLCanvasElement | undefined {
		return canvas;
	}
</script>

<div bind:this={container} class="w-full">
	<canvas
		bind:this={canvas}
		width={PAD.left + PLOT_W + PAD.right}
		height={PAD.top + PLOT_H + PAD.bottom}
		onmousemove={handleMove}
		onmouseleave={() => onreadout?.(null)}
	></canvas>
</div>
