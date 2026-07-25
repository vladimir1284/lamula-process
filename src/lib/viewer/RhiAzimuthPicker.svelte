<script lang="ts">
	import type { Scan } from '$lib/domain/types';
	import type { Palette } from '$lib/palette/types';
	import { rasterizePPI, normDeg } from '$lib/render';

	interface Props {
		/** Reference PPI scan drawn as the plan view (typically the lowest elevation). */
		scan: Scan;
		palette: Palette;
		/** Current cut azimuth (deg from north, clockwise). */
		azimuthDeg: number;
		onchange?: (azDeg: number) => void;
	}

	let { scan, palette, azimuthDeg, onchange }: Props = $props();

	const SIZE = 260;
	const C = SIZE / 2;
	const DEG = Math.PI / 180;

	let canvas: HTMLCanvasElement | undefined = $state();
	let dragging = $state(false);

	// Rebuild the plan-view raster only when the scan/palette change (not on every azimuth drag).
	const raster = $derived(rasterizePPI(scan, palette, { sizePx: SIZE }));

	$effect(() => {
		const el = canvas;
		if (!el) return;
		const ctx = el.getContext('2d');
		if (!ctx) return;

		ctx.clearRect(0, 0, SIZE, SIZE);
		ctx.fillStyle = '#0b0f14';
		ctx.fillRect(0, 0, SIZE, SIZE);

		const img = ctx.createImageData(raster.sizePx, raster.sizePx);
		img.data.set(raster.rgba);
		ctx.putImageData(img, 0, 0);

		// disc outline + compass letters
		ctx.strokeStyle = 'rgba(255,255,255,0.25)';
		ctx.beginPath();
		ctx.arc(C, C, C - 1, 0, 2 * Math.PI);
		ctx.stroke();
		ctx.fillStyle = 'rgba(255,255,255,0.6)';
		ctx.font = '10px sans-serif';
		ctx.fillText('N', C - 3, 10);
		ctx.fillText('S', C - 3, SIZE - 2);
		ctx.fillText('E', SIZE - 9, C + 3);
		ctx.fillText('O', 2, C + 3);

		// radial cut line: north-up, azimuth clockwise from north.
		const a = normDeg(azimuthDeg) * DEG;
		const ex = C + Math.sin(a) * (C - 1);
		const ey = C - Math.cos(a) * (C - 1);
		ctx.strokeStyle = '#ffcc00';
		ctx.lineWidth = 2;
		ctx.beginPath();
		ctx.moveTo(C, C);
		ctx.lineTo(ex, ey);
		ctx.stroke();
		ctx.fillStyle = '#ffcc00';
		ctx.beginPath();
		ctx.arc(C, C, 3, 0, 2 * Math.PI);
		ctx.fill();
	});

	function azFromEvent(ev: PointerEvent): number {
		const rect = canvas!.getBoundingClientRect();
		// canvas is drawn at SIZE but may be CSS-scaled; map back to raster coords.
		const px = ((ev.clientX - rect.left) / rect.width) * SIZE;
		const py = ((ev.clientY - rect.top) / rect.height) * SIZE;
		const east = px - C;
		const north = C - py;
		return normDeg((Math.atan2(east, north) / DEG));
	}

	function emit(ev: PointerEvent) {
		onchange?.(Math.round(azFromEvent(ev)));
	}
</script>

<canvas
	bind:this={canvas}
	width={SIZE}
	height={SIZE}
	class="cursor-crosshair rounded"
	style="touch-action: none;"
	onpointerdown={(e) => {
		dragging = true;
		canvas?.setPointerCapture(e.pointerId);
		emit(e);
	}}
	onpointermove={(e) => dragging && emit(e)}
	onpointerup={(e) => {
		dragging = false;
		canvas?.releasePointerCapture(e.pointerId);
	}}
></canvas>
