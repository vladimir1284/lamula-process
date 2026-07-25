import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type { RasterOptions, RasterResult } from './rasterizePPI';
import { rasterizePPI } from './rasterizePPI';
import type { PpiWorkerRequest, PpiWorkerResponse } from './ppi.worker';

/**
 * Client for the PPI rasterizer. Offloads to a Web Worker when the environment has one
 * (browser); falls back to a synchronous call otherwise (SSR, unit tests). Callers should
 * `terminate()` when done to release the worker.
 */
export class PpiRenderer {
	private worker: Worker | null = null;
	private seq = 0;
	private pending = new Map<
		number,
		{ resolve: (r: RasterResult) => void; reject: (e: Error) => void }
	>();

	constructor() {
		if (typeof Worker !== 'undefined') {
			try {
				this.worker = new Worker(new URL('./ppi.worker.ts', import.meta.url), {
					type: 'module'
				});
				this.worker.onmessage = (ev: MessageEvent<PpiWorkerResponse>) => {
					const { id, result, error } = ev.data;
					const p = this.pending.get(id);
					if (!p) return;
					this.pending.delete(id);
					if (error) p.reject(new Error(error));
					else if (result) p.resolve(result);
				};
			} catch {
				this.worker = null; // fall back to sync
			}
		}
	}

	render(scan: Scan, palette: Palette, opts: RasterOptions): Promise<RasterResult> {
		if (!this.worker) return Promise.resolve(rasterizePPI(scan, palette, opts));
		const id = ++this.seq;
		const req: PpiWorkerRequest = { id, scan, palette, opts };
		return new Promise<RasterResult>((resolve, reject) => {
			this.pending.set(id, { resolve, reject });
			this.worker!.postMessage(req);
		});
	}

	terminate(): void {
		this.worker?.terminate();
		this.worker = null;
		this.pending.clear();
	}
}
