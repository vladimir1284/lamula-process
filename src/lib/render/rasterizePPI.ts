import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import { colorForValue } from '$lib/palette/lookup';
import { CELL_FLAG_OK, CELL_FLAG_BELOW_THRESHOLD } from '$lib/domain/cells';
import {
	buildAzimuthLUT,
	gateForGroundRange,
	maxGroundRangeM,
	normDeg,
	rayIndexForAzimuth
} from './scanSample';

const DEG = Math.PI / 180;

export interface RasterOptions {
	/** Output raster is `sizePx × sizePx`. */
	sizePx: number;
	/** Half-width of the covered ground disc (m). Defaults to the scan's outermost gate. */
	maxRangeM?: number;
	/**
	 * Whether to paint gates flagged `below-threshold` with the palette's lowest colour instead
	 * of leaving them transparent (mirrors the legacy `IncludeZero` setting). Default false.
	 */
	includeBelowThreshold?: boolean;
}

export interface RasterResult {
	/** RGBA, row-major top-to-bottom, `sizePx²` pixels. Transparent outside the scan/no-data. */
	rgba: Uint8ClampedArray;
	sizePx: number;
	/** Ground half-width the raster spans (m); the raster maps [-maxRangeM, +maxRangeM]². */
	maxRangeM: number;
}

/**
 * Rasterize a PPI scan to an RGBA image over its ground disc, centred on the radar.
 *
 * Pixel → ground plane: column → East, row → North (north-up, so row 0 is the top / max
 * North). Each pixel is inverse-mapped to (range, azimuth) and coloured via the palette.
 * Non-`ok` cells and out-of-disc pixels are transparent (unless `includeBelowThreshold`).
 *
 * Pure and synchronous — the Web Worker wrapper (`ppi.worker.ts`) just forwards to this so the
 * mapping stays unit-testable without a worker/DOM.
 */
export function rasterizePPI(scan: Scan, palette: Palette, opts: RasterOptions): RasterResult {
	const size = opts.sizePx;
	const maxRange = opts.maxRangeM ?? maxGroundRangeM(scan);
	const rgba = new Uint8ClampedArray(size * size * 4);
	const lut = buildAzimuthLUT(scan);
	const { values, flags } = scan.cells;
	const numGates = scan.numGates;
	const includeBelow = opts.includeBelowThreshold ?? false;

	// Pixel size in ground metres; pixel centre offset by +0.5.
	const step = (2 * maxRange) / size;

	for (let py = 0; py < size; py++) {
		// row 0 = north (max +y), row size-1 = south.
		const gy = maxRange - (py + 0.5) * step;
		const rowBase = py * size * 4;
		for (let px = 0; px < size; px++) {
			const gx = -maxRange + (px + 0.5) * step;
			const range = Math.hypot(gx, gy);
			const gate = gateForGroundRange(scan, range);
			if (gate < 0) continue; // transparent
			const az = normDeg(Math.atan2(gx, gy) / DEG);
			const ray = rayIndexForAzimuth(lut, az);
			if (ray < 0) continue;
			const idx = ray * numGates + gate;
			const flag = flags[idx];
			// 'ok' always painted; 'below-threshold' only if requested; other flags transparent.
			if (flag !== CELL_FLAG_OK && !(includeBelow && flag === CELL_FLAG_BELOW_THRESHOLD)) continue;
			const [r, g, b] = colorForValue(palette, values[idx]);
			const o = rowBase + px * 4;
			rgba[o] = r;
			rgba[o + 1] = g;
			rgba[o + 2] = b;
			rgba[o + 3] = 255;
		}
	}

	return { rgba, sizePx: size, maxRangeM: maxRange };
}
