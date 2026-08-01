<script lang="ts">
	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import {
		rasterizeCrossSection,
		buildScanMeta,
		sampleCrossSection,
		type CutLine,
		type CrossSample
	} from '$lib/products/crossSection';
	import { distanceUnitLabel, toDisplayDistanceM, type UnitSystem } from '$lib/units';
	import {
		setupHiDPICanvas,
		linearScale,
		drawAxes,
		observeContainerWidth
	} from '$lib/viewer/chartCanvas';

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
		/** Scales the plot area up/down from its container-fit size; >1 grows past the container so
		 * the scrolling wrapper (`overflow-auto`) shows scrollbars. Default 1 (fit container). */
		zoom?: number;
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
		onreadout
	}: Props = $props();

	// Same A/green, B/red convention as PpiMap's cut-line endpoint markers.
	const START_COLOR = '#22c55e';
	const END_COLOR = '#ef4444';

	let container: HTMLDivElement | undefined = $state();
	let canvas: HTMLCanvasElement | undefined = $state();
	const PAD = { left: 48, bottom: 28, top: 20, right: 8 };
	const MIN_PLOT_W = 200;
	const BASE_PLOT_H = 260;
	let fitWidth = $state(720);
	const PLOT_W = $derived(Math.max(MIN_PLOT_W, Math.round(fitWidth * zoom)));
	const PLOT_H = $derived(Math.round(BASE_PLOT_H * zoom));

	let lineLengthM = $state(0);

	$effect(() => {
		const el = container;
		if (!el) return;
		return observeContainerWidth(el, (w) => {
			fitWidth = Math.max(MIN_PLOT_W, Math.round(w - PAD.left - PAD.right));
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

		// Rasterize at physical (device-pixel) resolution so the heatmap is as crisp as the axes.
		const raster = rasterizeCrossSection(scans, palette, {
			widthPx: Math.round(PLOT_W * dpr),
			heightPx: Math.round(PLOT_H * dpr),
			maxHeightM,
			line
		});
		lineLengthM = raster.lineLengthM;

		ctx.clearRect(0, 0, PAD.left + PLOT_W + PAD.right, PAD.top + PLOT_H + PAD.bottom);
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, PAD.left + PLOT_W + PAD.right, PAD.top + PLOT_H + PAD.bottom);

		const img = ctx.createImageData(raster.widthPx, raster.heightPx);
		img.data.set(raster.rgba);
		// putImageData always writes raw device pixels, ignoring the dpr transform above.
		ctx.putImageData(img, Math.round(PAD.left * dpr), Math.round(PAD.top * dpr));

		const xScale = linearScale(
			[0, toDisplayDistanceM(lineLengthM, unitSystem)],
			[PAD.left, PAD.left + PLOT_W]
		);
		const yScale = linearScale([0, maxHeightM / 1000], [PAD.top + PLOT_H, PAD.top]);
		drawAxes(ctx, { left: PAD.left, top: PAD.top, width: PLOT_W, height: PLOT_H }, xScale, yScale, {
			xFormat: (v) => `${Math.round(v)}`,
			yFormat: (v) => `${Math.round(v)}`,
			xLabel: distanceUnitLabel(unitSystem),
			yLabel: 'km'
		});

		if (markEndpoints) {
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
	});

	function handleMove(ev: MouseEvent) {
		if (!onreadout || !canvas || lineLengthM === 0) return;
		const rect = canvas.getBoundingClientRect();
		const cx = ev.clientX - rect.left - PAD.left;
		const cy = ev.clientY - rect.top - PAD.top;
		if (cx < 0 || cx > PLOT_W || cy < 0 || cy > PLOT_H) {
			onreadout(null);
			return;
		}
		const t = cx / PLOT_W;
		const distanceM = t * lineLengthM;
		const heightM = (1 - cy / PLOT_H) * maxHeightM;
		const x = line.ax + t * (line.bx - line.ax);
		const y = line.ay + t * (line.by - line.ay);
		const sample = sampleCrossSection(buildScanMeta(scans), x, y, heightM);
		onreadout({ distanceM, heightM, sample });
	}

	export function getCanvas(): HTMLCanvasElement | undefined {
		return canvas;
	}
</script>

<div bind:this={container} class="h-full w-full overflow-auto">
	<canvas
		bind:this={canvas}
		width={PAD.left + PLOT_W + PAD.right}
		height={PAD.top + PLOT_H + PAD.bottom}
		onmousemove={handleMove}
		onmouseleave={() => onreadout?.(null)}
	></canvas>
</div>
