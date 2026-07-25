import type { RasterResult } from '$lib/render/rasterizePPI';

/**
 * Browser-only helpers turning a rasterized scan (RGBA) into something OpenLayers'
 * `ol/source/ImageStatic` can consume. Row 0 of the raster is North (top), which matches
 * ImageStatic mapping the image's top edge to the extent's max-Y — no flip needed.
 */

export function rasterToCanvas(result: RasterResult): HTMLCanvasElement {
	const canvas = document.createElement('canvas');
	canvas.width = result.sizePx;
	canvas.height = result.sizePx;
	const ctx = canvas.getContext('2d');
	if (!ctx) throw new Error('2D canvas context unavailable');
	// Build via createImageData + set() so the backing buffer is always a plain ArrayBuffer
	// (avoids the SharedArrayBuffer widening the ImageData(data,…) overload trips on).
	const img = ctx.createImageData(result.sizePx, result.sizePx);
	img.data.set(result.rgba);
	ctx.putImageData(img, 0, 0);
	return canvas;
}

export function rasterToDataURL(result: RasterResult): string {
	return rasterToCanvas(result).toDataURL('image/png');
}
