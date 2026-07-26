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
		onreadout?: (r: CrossSectionReadout | null) => void;
	}

	let {
		scans,
		palette,
		line,
		maxHeightM = 18_000,
		markEndpoints = false,
		onreadout
	}: Props = $props();

	// Same A/green, B/red convention as PpiMap's cut-line endpoint markers.
	const START_COLOR = '#22c55e';
	const END_COLOR = '#ef4444';

	let canvas: HTMLCanvasElement | undefined = $state();
	const PAD = { left: 48, bottom: 28, top: 8, right: 8 };
	const PLOT_W = 720;
	const PLOT_H = 260;

	let lineLengthM = $state(0);

	$effect(() => {
		const el = canvas;
		if (!el) return;
		const ctx = el.getContext('2d');
		if (!ctx) return;

		const raster = rasterizeCrossSection(scans, palette, {
			widthPx: PLOT_W,
			heightPx: PLOT_H,
			maxHeightM,
			line
		});
		lineLengthM = raster.lineLengthM;

		ctx.clearRect(0, 0, el.width, el.height);
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, el.width, el.height);

		const img = ctx.createImageData(raster.widthPx, raster.heightPx);
		img.data.set(raster.rgba);
		ctx.putImageData(img, PAD.left, PAD.top);

		ctx.strokeStyle = 'rgba(255,255,255,0.4)';
		ctx.fillStyle = 'rgba(255,255,255,0.7)';
		ctx.font = '10px sans-serif';
		ctx.beginPath();
		ctx.moveTo(PAD.left, PAD.top);
		ctx.lineTo(PAD.left, PAD.top + PLOT_H);
		ctx.lineTo(PAD.left + PLOT_W, PAD.top + PLOT_H);
		ctx.stroke();

		// x ticks every 50 km along the cut
		for (let m = 0; m <= lineLengthM + 1; m += 50_000) {
			const x = PAD.left + (m / lineLengthM) * PLOT_W;
			ctx.fillText(`${Math.round(m / 1000)}`, x - 6, PAD.top + PLOT_H + 12);
		}
		ctx.fillText('km', PAD.left + PLOT_W - 4, PAD.top + PLOT_H + 22);
		// y ticks every 3 km
		for (let m = 0; m <= maxHeightM + 1; m += 3_000) {
			const y = PAD.top + PLOT_H - (m / maxHeightM) * PLOT_H;
			ctx.fillText(`${Math.round(m / 1000)}`, 4, y + 3);
		}

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

<canvas
	bind:this={canvas}
	width={PAD.left + PLOT_W + PAD.right}
	height={PAD.top + PLOT_H + PAD.bottom}
	class="w-full"
	onmousemove={handleMove}
	onmouseleave={() => onreadout?.(null)}
></canvas>
