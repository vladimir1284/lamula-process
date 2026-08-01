import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type {
	CrossSectionRasterOptions,
	CrossSectionRasterResult
} from '$lib/products/crossSection';
import { rasterizeCrossSection } from '$lib/products/crossSection';
import { RasterWorkerClient } from './rasterWorkerClient';

interface CrossSectionRasterReq {
	scans: Scan[];
	palette: Palette;
	opts: CrossSectionRasterOptions;
}

/**
 * Client for the cross-section rasterizer. Offloads to a Web Worker when the environment has one
 * (browser); falls back to a synchronous call otherwise (SSR, unit tests). Callers should
 * `terminate()` when done to release the worker.
 */
export class CrossSectionRenderer {
	private client = new RasterWorkerClient<CrossSectionRasterReq, CrossSectionRasterResult>(
		() => new Worker(new URL('./crossSection.worker.ts', import.meta.url), { type: 'module' }),
		(req) => rasterizeCrossSection(req.scans, req.palette, req.opts)
	);

	render(
		scans: Scan[],
		palette: Palette,
		opts: CrossSectionRasterOptions
	): Promise<CrossSectionRasterResult> {
		return this.client.render({ scans, palette, opts });
	}

	terminate(): void {
		this.client.terminate();
	}
}
