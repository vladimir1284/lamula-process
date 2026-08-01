export interface RasterWorkerResponse<TResult> {
	id: number;
	result?: TResult;
	error?: string;
}

/**
 * Generic client for a "rasterize on a worker, fall back to sync" pattern. Every rasterizer
 * worker (ppi/rhi/crossSection) speaks the same wire shape: request is `{id, ...args}`, response
 * is `{id, result?, error?}`. This class owns the id-correlation/pending-promise bookkeeping so
 * each concrete renderer only supplies how to create its worker and its sync fallback.
 */
export class RasterWorkerClient<TReq extends object, TResult> {
	private worker: Worker | null = null;
	private seq = 0;
	private pending = new Map<
		number,
		{ resolve: (r: TResult) => void; reject: (e: Error) => void }
	>();

	constructor(
		private createWorker: () => Worker,
		private syncFallback: (req: TReq) => TResult
	) {
		if (typeof Worker !== 'undefined') {
			try {
				this.worker = this.createWorker();
				this.worker.onmessage = (ev: MessageEvent<RasterWorkerResponse<TResult>>) => {
					const { id, result, error } = ev.data;
					const p = this.pending.get(id);
					if (!p) return;
					this.pending.delete(id);
					if (error) p.reject(new Error(error));
					else if (result !== undefined) p.resolve(result);
				};
			} catch {
				this.worker = null; // fall back to sync
			}
		}
	}

	render(req: TReq): Promise<TResult> {
		if (!this.worker) return Promise.resolve(this.syncFallback(req));
		const id = ++this.seq;
		return new Promise<TResult>((resolve, reject) => {
			this.pending.set(id, { resolve, reject });
			this.worker!.postMessage({ id, ...req });
		});
	}

	terminate(): void {
		this.worker?.terminate();
		this.worker = null;
		this.pending.clear();
	}
}
