import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type { RasterOptions, RasterResult } from './rasterizePPI';
import { rasterizePPI } from './rasterizePPI';
import { RasterWorkerClient } from './rasterWorkerClient';

interface PpiRasterReq {
	scan: Scan;
	palette: Palette;
	opts: RasterOptions;
}

/**
 * Client for the PPI rasterizer. Offloads to a Web Worker when the environment has one
 * (browser); falls back to a synchronous call otherwise (SSR, unit tests). Callers should
 * `terminate()` when done to release the worker.
 */
export class PpiRenderer {
	private client = new RasterWorkerClient<PpiRasterReq, RasterResult>(
		() => new Worker(new URL('./ppi.worker.ts', import.meta.url), { type: 'module' }),
		(req) => rasterizePPI(req.scan, req.palette, req.opts)
	);

	render(scan: Scan, palette: Palette, opts: RasterOptions): Promise<RasterResult> {
		return this.client.render({ scan, palette, opts });
	}

	terminate(): void {
		this.client.terminate();
	}
}
