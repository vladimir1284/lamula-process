<script lang="ts">
	import type { ProfileResult } from '$lib/products/profile';
	import {
		setupHiDPICanvas,
		linearScale,
		drawAxes,
		observeContainerSize
	} from '$lib/viewer/chartCanvas';

	interface Props {
		profile: ProfileResult;
		/** Value-axis label, e.g. 'dBZ'. */
		valueLabel?: string;
		/** Scales the plot area up/down from its container-fit size; >1 grows past the container so
		 * the scrolling wrapper (`overflow-auto`) shows scrollbars. Default 1 (fit container). */
		zoom?: number;
	}

	let { profile, valueLabel = 'dBZ', zoom = 1 }: Props = $props();

	let container: HTMLDivElement | undefined = $state();
	let canvas: HTMLCanvasElement | undefined = $state();
	const PAD = { left: 44, bottom: 28, top: 20, right: 12 };
	const MIN_PLOT_W = 160;
	const MIN_PLOT_H = 160;
	let fitWidth = $state(240);
	let fitHeight = $state(300);
	const PLOT_W = $derived(Math.max(MIN_PLOT_W, Math.round(fitWidth * zoom)));
	const PLOT_H = $derived(Math.max(MIN_PLOT_H, Math.round(fitHeight * zoom)));

	$effect(() => {
		const el = container;
		if (!el) return;
		// Track both dimensions of the window's content area, not just width, so the plot keeps
		// the window's own proportions instead of a fixed aspect ratio.
		return observeContainerSize(el, (w, h) => {
			fitWidth = Math.max(MIN_PLOT_W, Math.round(w - PAD.left - PAD.right));
			fitHeight = Math.max(MIN_PLOT_H, Math.round(h - PAD.top - PAD.bottom));
		});
	});

	$effect(() => {
		const el = canvas;
		if (!el) return;
		const { ctx } = setupHiDPICanvas(
			el,
			PAD.left + PLOT_W + PAD.right,
			PAD.top + PLOT_H + PAD.bottom
		);

		const { heightsM, values, samples } = profile;
		const topM = heightsM.length > 0 ? heightsM[heightsM.length - 1] : 20000;
		// value range from the data (guard against a flat/empty profile)
		let vMin = Infinity;
		let vMax = -Infinity;
		for (const v of values) {
			if (v < vMin) vMin = v;
			if (v > vMax) vMax = v;
		}
		if (!isFinite(vMin) || vMax - vMin < 1e-6) {
			vMin = 0;
			vMax = 1;
		}

		const xScale = linearScale([vMin, vMax], [PAD.left, PAD.left + PLOT_W]);
		const yScale = linearScale([0, topM / 1000], [PAD.top + PLOT_H, PAD.top]);
		const xOf = (v: number) => xScale(v);
		const yOf = (m: number) => yScale(m / 1000);

		ctx.clearRect(0, 0, PAD.left + PLOT_W + PAD.right, PAD.top + PLOT_H + PAD.bottom);
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, PAD.left + PLOT_W + PAD.right, PAD.top + PLOT_H + PAD.bottom);

		drawAxes(ctx, { left: PAD.left, top: PAD.top, width: PLOT_W, height: PLOT_H }, xScale, yScale, {
			xFormat: (v) => `${Math.round(v)}`,
			yFormat: (v) => `${Math.round(v)}`,
			xLabel: valueLabel,
			yLabel: 'km'
		});

		// spline curve
		ctx.strokeStyle = '#4ea1ff';
		ctx.beginPath();
		for (let i = 0; i < heightsM.length; i++) {
			const x = xOf(values[i]);
			const y = yOf(heightsM[i]);
			if (i === 0) ctx.moveTo(x, y);
			else ctx.lineTo(x, y);
		}
		ctx.stroke();

		// sample markers
		ctx.fillStyle = '#ffd166';
		for (const s of samples) {
			ctx.beginPath();
			ctx.arc(xOf(s.value), yOf(s.heightM), 2.5, 0, Math.PI * 2);
			ctx.fill();
		}
	});

	export function getCanvas(): HTMLCanvasElement | undefined {
		return canvas;
	}
</script>

<div bind:this={container} class="h-full w-full overflow-auto">
	<canvas
		bind:this={canvas}
		width={PAD.left + PLOT_W + PAD.right}
		height={PAD.top + PLOT_H + PAD.bottom}
	></canvas>
</div>
