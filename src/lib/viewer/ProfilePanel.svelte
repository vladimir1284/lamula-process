<script lang="ts">
	import type { ProfileResult } from '$lib/products/profile';

	interface Props {
		profile: ProfileResult;
		/** Value-axis label, e.g. 'dBZ'. */
		valueLabel?: string;
	}

	let { profile, valueLabel = 'dBZ' }: Props = $props();

	let canvas: HTMLCanvasElement | undefined = $state();
	const PAD = { left: 44, bottom: 28, top: 8, right: 12 };
	const PLOT_W = 240;
	const PLOT_H = 300;

	$effect(() => {
		const el = canvas;
		if (!el) return;
		const ctx = el.getContext('2d');
		if (!ctx) return;

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

		const xOf = (v: number) => PAD.left + ((v - vMin) / (vMax - vMin)) * PLOT_W;
		const yOf = (m: number) => PAD.top + PLOT_H - (m / topM) * PLOT_H;

		ctx.clearRect(0, 0, el.width, el.height);
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, el.width, el.height);

		// axes
		ctx.strokeStyle = 'rgba(255,255,255,0.4)';
		ctx.fillStyle = 'rgba(255,255,255,0.7)';
		ctx.font = '10px sans-serif';
		ctx.beginPath();
		ctx.moveTo(PAD.left, PAD.top);
		ctx.lineTo(PAD.left, PAD.top + PLOT_H);
		ctx.lineTo(PAD.left + PLOT_W, PAD.top + PLOT_H);
		ctx.stroke();
		// y ticks every 3 km
		for (let m = 0; m <= topM + 1; m += 3_000) {
			ctx.fillText(`${Math.round(m / 1000)}`, 4, yOf(m) + 3);
		}
		ctx.fillText('km', 4, PAD.top + 8);
		ctx.fillText(valueLabel, PAD.left + PLOT_W - 20, PAD.top + PLOT_H + 22);

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
</script>

<canvas
	bind:this={canvas}
	width={PAD.left + PLOT_W + PAD.right}
	height={PAD.top + PLOT_H + PAD.bottom}
	class="w-full"
></canvas>
