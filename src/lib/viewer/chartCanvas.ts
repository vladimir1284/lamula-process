import { scaleLinear, type ScaleLinear } from 'd3-scale';

export type LinearScale = ScaleLinear<number, number>;

export interface HiDPICanvas {
	ctx: CanvasRenderingContext2D;
	dpr: number;
}

/**
 * Sizes a canvas's backing store to devicePixelRatio so vector drawing (grid, ticks, labels)
 * stays crisp on HiDPI displays, while the element's CSS box stays at the given logical size.
 * `ctx` is left with a `scale(dpr, dpr)` transform, so all *vector* drawing after this call uses
 * logical (CSS) pixel coordinates -- except `putImageData`, which always writes raw device
 * pixels regardless of the current transform, so raster blits must use device coordinates
 * (multiply by `dpr`) even after calling this.
 */
export function setupHiDPICanvas(
	canvas: HTMLCanvasElement,
	cssWidth: number,
	cssHeight: number
): HiDPICanvas {
	const dpr =
		typeof devicePixelRatio !== 'undefined' && devicePixelRatio > 0 ? devicePixelRatio : 1;
	canvas.width = Math.round(cssWidth * dpr);
	canvas.height = Math.round(cssHeight * dpr);
	canvas.style.width = `${cssWidth}px`;
	canvas.style.height = `${cssHeight}px`;
	const ctx = canvas.getContext('2d');
	if (!ctx) throw new Error('2d context unavailable');
	ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
	return { ctx, dpr };
}

export function linearScale(domain: [number, number], range: [number, number]): LinearScale {
	return scaleLinear().domain(domain).range(range);
}

/**
 * Watches an element's content width (e.g. a wrapping div sized by the surrounding flex layout)
 * so a chart can size its canvas to fill available space without relying on CSS stretching the
 * canvas itself, which is what causes blurry HiDPI rendering. Call the returned function to stop
 * observing.
 */
export function observeContainerWidth(el: Element, onWidth: (widthPx: number) => void): () => void {
	const ro = new ResizeObserver((entries) => {
		const w = entries[0]?.contentRect.width;
		if (w) onWidth(w);
	});
	ro.observe(el);
	return () => ro.disconnect();
}

/** Like `observeContainerWidth`, but reports both dimensions -- for charts whose plot area should
 * track the window's height as well as its width (e.g. the profile chart, which should keep the
 * window's own proportions rather than a fixed aspect ratio). */
export function observeContainerSize(
	el: Element,
	onSize: (widthPx: number, heightPx: number) => void
): () => void {
	const ro = new ResizeObserver((entries) => {
		const rect = entries[0]?.contentRect;
		if (rect && rect.width && rect.height) onSize(rect.width, rect.height);
	});
	ro.observe(el);
	return () => ro.disconnect();
}

export interface PlotRect {
	left: number;
	top: number;
	width: number;
	height: number;
}

export interface AxisOptions {
	xFormat?: (v: number) => string;
	yFormat?: (v: number) => string;
	/** Unit label drawn under the last x tick, e.g. "km". */
	xLabel?: string;
	/** Unit label drawn above the y axis, e.g. "km" or "dBZ". */
	yLabel?: string;
	/** Roughly how many ticks to request per axis; d3 rounds to "nice" values. */
	xTickCount?: number;
	yTickCount?: number;
	grid?: boolean;
}

const GRID_COLOR = 'rgba(255,255,255,0.12)';
const AXIS_COLOR = 'rgba(255,255,255,0.5)';
const TICK_LABEL_COLOR = 'rgba(255,255,255,0.85)';
const AXIS_LABEL_COLOR = 'rgba(255,255,255,0.6)';

/**
 * Draws grid lines, axis lines, tick labels, and unit labels for a plot area, in logical (CSS)
 * pixels. Call after `setupHiDPICanvas` so text and lines land on crisp device pixels. `xScale`
 * and `yScale` should already be built with a range matching `plot` -- reuse the same scales to
 * place data (raster/lines/points) so ticks and data always agree.
 */
export function drawAxes(
	ctx: CanvasRenderingContext2D,
	plot: PlotRect,
	xScale: LinearScale,
	yScale: LinearScale,
	opts: AxisOptions = {}
) {
	const { left, top, width, height } = plot;
	const xTicks = xScale.ticks(opts.xTickCount ?? Math.max(2, Math.round(width / 90)));
	const yTicks = yScale.ticks(opts.yTickCount ?? Math.max(2, Math.round(height / 50)));
	const xFormat = opts.xFormat ?? ((v: number) => `${v}`);
	const yFormat = opts.yFormat ?? ((v: number) => `${v}`);

	ctx.save();

	if (opts.grid !== false) {
		ctx.strokeStyle = GRID_COLOR;
		ctx.lineWidth = 1;
		for (const v of xTicks) {
			const x = Math.round(xScale(v)) + 0.5;
			ctx.beginPath();
			ctx.moveTo(x, top);
			ctx.lineTo(x, top + height);
			ctx.stroke();
		}
		for (const v of yTicks) {
			const y = Math.round(yScale(v)) + 0.5;
			ctx.beginPath();
			ctx.moveTo(left, y);
			ctx.lineTo(left + width, y);
			ctx.stroke();
		}
	}

	ctx.strokeStyle = AXIS_COLOR;
	ctx.lineWidth = 1;
	ctx.beginPath();
	ctx.moveTo(left, top);
	ctx.lineTo(left, top + height);
	ctx.lineTo(left + width, top + height);
	ctx.stroke();

	ctx.font = '11px system-ui, sans-serif';
	ctx.fillStyle = TICK_LABEL_COLOR;
	ctx.textAlign = 'right';
	ctx.textBaseline = 'middle';
	for (const v of yTicks) {
		ctx.fillText(yFormat(v), left - 6, yScale(v));
	}
	ctx.textAlign = 'center';
	ctx.textBaseline = 'top';
	for (const v of xTicks) {
		ctx.fillText(xFormat(v), xScale(v), top + height + 6);
	}

	ctx.font = '10px system-ui, sans-serif';
	ctx.fillStyle = AXIS_LABEL_COLOR;
	if (opts.xLabel) {
		ctx.textAlign = 'right';
		ctx.textBaseline = 'top';
		ctx.fillText(opts.xLabel, left + width, top + height + 18);
	}
	if (opts.yLabel) {
		ctx.textAlign = 'left';
		ctx.textBaseline = 'bottom';
		// Offset right of `left`: CrossSectionPanel draws its "A" endpoint marker centered on the
		// y-axis line right above the plot, and would otherwise sit on top of this label.
		ctx.fillText(opts.yLabel, left + 10, top - 4);
	}

	ctx.restore();
}
