import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type { RhiRasterOptions, RhiRasterResult } from './rasterizeRHI';
import { rasterizeRHI } from './rasterizeRHI';
import { RasterWorkerClient } from './rasterWorkerClient';

interface RhiRasterReq {
	scan: Scan;
	palette: Palette;
	opts: RhiRasterOptions;
}

/**
 * Client for the RHI rasterizer. Offloads to a Web Worker when the environment has one
 * (browser); falls back to a synchronous call otherwise (SSR, unit tests). Callers should
 * `terminate()` when done to release the worker.
 */
export class RhiRenderer {
	private client = new RasterWorkerClient<RhiRasterReq, RhiRasterResult>(
		() => new Worker(new URL('./rhi.worker.ts', import.meta.url), { type: 'module' }),
		(req) => rasterizeRHI(req.scan, req.palette, req.opts)
	);

	render(scan: Scan, palette: Palette, opts: RhiRasterOptions): Promise<RhiRasterResult> {
		return this.client.render({ scan, palette, opts });
	}

	terminate(): void {
		this.client.terminate();
	}
}
