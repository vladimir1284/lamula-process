import type Map from 'ol/Map';

/**
 * Composite an OpenLayers map's layer canvases into one flat canvas, respecting each layer's
 * opacity/transform. OL splits rendering across one `<canvas>` per layer (base map, radar raster,
 * rings, overlays) rather than a single element, so a naive "grab the first canvas" would miss
 * everything but the bottom layer. Pattern follows OL's own export-map example.
 */
export function exportMapToCanvas(map: Map): Promise<HTMLCanvasElement> {
	return new Promise((resolve, reject) => {
		map.once('rendercomplete', () => {
			try {
				const size = map.getSize();
				if (!size) {
					reject(new Error('Map has no size'));
					return;
				}
				const mapCanvas = document.createElement('canvas');
				mapCanvas.width = size[0];
				mapCanvas.height = size[1];
				const mapContext = mapCanvas.getContext('2d');
				if (!mapContext) {
					reject(new Error('2D canvas context unavailable'));
					return;
				}
				// The visor frames the map in a black container (bg-black); layers that don't cover the
				// whole viewport (no base map selected, radar opacity < 1) would otherwise leave the
				// canvas transparent there, which renders as white once the PNG leaves this app.
				mapContext.fillStyle = '#000';
				mapContext.fillRect(0, 0, mapCanvas.width, mapCanvas.height);
				const canvases = map
					.getViewport()
					.querySelectorAll<HTMLCanvasElement>('.ol-layer canvas, canvas.ol-layer');
				canvases.forEach((canvas) => {
					if (canvas.width === 0) return;
					const opacity = canvas.parentElement?.style.opacity || canvas.style.opacity;
					mapContext.globalAlpha = opacity === '' ? 1 : Number(opacity);

					const transform = canvas.style.transform;
					const matrix = transform
						? transform
								.match(/^matrix\(([^)]*)\)$/)![1]
								.split(',')
								.map(Number)
						: [
								parseFloat(canvas.style.width) / canvas.width,
								0,
								0,
								parseFloat(canvas.style.height) / canvas.height,
								0,
								0
							];
					mapContext.setTransform(matrix[0], matrix[1], matrix[2], matrix[3], matrix[4], matrix[5]);

					const backgroundColor = canvas.parentElement?.style.backgroundColor;
					if (backgroundColor) {
						mapContext.fillStyle = backgroundColor;
						mapContext.fillRect(0, 0, canvas.width, canvas.height);
					}
					mapContext.drawImage(canvas, 0, 0);
				});
				mapContext.setTransform(1, 0, 0, 1, 0, 0);
				resolve(mapCanvas);
			} catch (err) {
				reject(err);
			}
		});
		map.renderSync();
	});
}

/**
 * RHI/cross-section/profile panels blit their rasterized plot via `putImageData`, which writes the
 * raster's alpha verbatim -- gaps with no echo end up fully transparent, not the panel's dark
 * `#0b0f14` fill, and only read as opaque on screen because the visor's black container shows
 * through. Flatten onto that same backdrop so the standalone PNG matches what's on screen instead
 * of showing white gaps once opened outside the app.
 */
export function flattenOnBlack(canvas: HTMLCanvasElement): HTMLCanvasElement {
	const out = document.createElement('canvas');
	out.width = canvas.width;
	out.height = canvas.height;
	const ctx = out.getContext('2d');
	if (!ctx) throw new Error('2D canvas context unavailable');
	ctx.fillStyle = '#000';
	ctx.fillRect(0, 0, out.width, out.height);
	ctx.drawImage(canvas, 0, 0);
	return out;
}

/** Trigger a PNG download of a canvas via an object URL (mirrors the Blob/`<a download>` pattern
 * already used for JSON exports elsewhere in this app). */
export function downloadCanvasAsPng(canvas: HTMLCanvasElement, filename: string): void {
	canvas.toBlob((blob) => {
		if (!blob) return;
		const url = URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = filename;
		a.click();
		URL.revokeObjectURL(url);
	}, 'image/png');
}

/**
 * Split-view products (RHI/cross-section/profile) render the map picker and the product plot as
 * two independently-sized canvases. Compose them side by side onto one black-backed canvas so
 * "export both panels" produces a single image matching what's on screen, rather than two files.
 */
export function composeSideBySide(
	left: HTMLCanvasElement,
	right: HTMLCanvasElement,
	gapPx = 12
): HTMLCanvasElement {
	const out = document.createElement('canvas');
	out.width = left.width + gapPx + right.width;
	out.height = Math.max(left.height, right.height);
	const ctx = out.getContext('2d');
	if (!ctx) throw new Error('2D canvas context unavailable');
	ctx.fillStyle = '#000';
	ctx.fillRect(0, 0, out.width, out.height);
	ctx.drawImage(left, 0, (out.height - left.height) / 2);
	ctx.drawImage(right, left.width + gapPx, (out.height - right.height) / 2);
	return out;
}

function sanitize(part: string): string {
	return part.replace(/[^a-zA-Z0-9._-]+/g, '-');
}

/** Build a `.png` filename from view-state fragments, dropping empty/undefined ones. */
export function buildExportFilename(parts: Array<string | number | null | undefined>): string {
	const clean = parts
		.filter((p): p is string | number => p !== null && p !== undefined && p !== '')
		.map((p) => sanitize(String(p)));
	return `${clean.join('_')}.png`;
}
