<script lang="ts">
	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import { rasterizeRHI, rhiReadoutAt, type RhiReadout } from '$lib/render/rasterizeRHI';

	interface Props {
		scan: Scan;
		palette: Palette;
		/** Max ground range shown (m). Default = outermost gate slant range. */
		maxRangeM?: number;
		/** Max height shown (m). Default 18 km. */
		maxHeightM?: number;
		onreadout?: (r: RhiReadout | null) => void;
	}

	let { scan, palette, maxRangeM, maxHeightM = 18_000, onreadout }: Props = $props();

	let canvas: HTMLCanvasElement | undefined = $state();
	const PAD = { left: 48, bottom: 28, top: 8, right: 8 };
	const PLOT_W = 720;
	const PLOT_H = 260;

	function rangeM(): number {
		return maxRangeM ?? scan.rangeToFirstGateM + (scan.numGates - 1) * scan.gateLengthM;
	}

	$effect(() => {
		const el = canvas;
		if (!el) return;
		const ctx = el.getContext('2d');
		if (!ctx) return;
		const maxR = rangeM();

		const raster = rasterizeRHI(scan, palette, {
			widthPx: PLOT_W,
			heightPx: PLOT_H,
			maxRangeM: maxR,
			maxHeightM
		});

		ctx.clearRect(0, 0, el.width, el.height);
		// background
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, el.width, el.height);

		// blit the raster into the plot area
		const img = ctx.createImageData(raster.widthPx, raster.heightPx);
		img.data.set(raster.rgba);
		ctx.putImageData(img, PAD.left, PAD.top);

		// axes
		ctx.strokeStyle = 'rgba(255,255,255,0.4)';
		ctx.fillStyle = 'rgba(255,255,255,0.7)';
		ctx.font = '10px sans-serif';
		ctx.beginPath();
		ctx.moveTo(PAD.left, PAD.top);
		ctx.lineTo(PAD.left, PAD.top + PLOT_H);
		ctx.lineTo(PAD.left + PLOT_W, PAD.top + PLOT_H);
		ctx.stroke();

		// x ticks every 50 km
		for (let m = 0; m <= maxR + 1; m += 50_000) {
			const x = PAD.left + (m / maxR) * PLOT_W;
			ctx.fillText(`${Math.round(m / 1000)}`, x - 6, PAD.top + PLOT_H + 12);
		}
		ctx.fillText('km', PAD.left + PLOT_W - 4, PAD.top + PLOT_H + 22);
		// y ticks every 3 km
		for (let m = 0; m <= maxHeightM + 1; m += 3_000) {
			const y = PAD.top + PLOT_H - (m / maxHeightM) * PLOT_H;
			ctx.fillText(`${Math.round(m / 1000)}`, 4, y + 3);
		}
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

<canvas
	bind:this={canvas}
	width={PAD.left + PLOT_W + PAD.right}
	height={PAD.top + PLOT_H + PAD.bottom}
	class="w-full"
	onmousemove={handleMove}
	onmouseleave={() => onreadout?.(null)}
></canvas>
