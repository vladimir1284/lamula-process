import { describe, it, expect, vi, afterEach } from 'vitest';
import { RasterWorkerClient } from './rasterWorkerClient';

interface FakeReq {
	value: number;
}
interface FakeResult {
	doubled: number;
}

/** Minimal fake Worker: echoes back `{id, result: {doubled: value*2}}` asynchronously. */
class FakeWorker {
	onmessage: ((ev: MessageEvent) => void) | null = null;
	terminated = false;
	postMessage(msg: { id: number; value: number }) {
		queueMicrotask(() => {
			this.onmessage?.({
				data: { id: msg.id, result: { doubled: msg.value * 2 } }
			} as MessageEvent);
		});
	}
	terminate() {
		this.terminated = true;
	}
}

describe('RasterWorkerClient', () => {
	afterEach(() => {
		vi.unstubAllGlobals();
	});

	it('falls back to sync when Worker is unavailable', async () => {
		vi.stubGlobal('Worker', undefined);
		const syncFallback = vi.fn((req: FakeReq): FakeResult => ({ doubled: req.value * 3 }));
		const client = new RasterWorkerClient<FakeReq, FakeResult>(() => {
			throw new Error('should not be called');
		}, syncFallback);
		const result = await client.render({ value: 5 });
		expect(result).toEqual({ doubled: 15 });
		expect(syncFallback).toHaveBeenCalledWith({ value: 5 });
	});

	it('falls back to sync when worker construction throws', async () => {
		vi.stubGlobal('Worker', class {});
		const syncFallback = vi.fn((req: FakeReq): FakeResult => ({ doubled: req.value * 3 }));
		const client = new RasterWorkerClient<FakeReq, FakeResult>(() => {
			throw new Error('boom');
		}, syncFallback);
		const result = await client.render({ value: 4 });
		expect(result).toEqual({ doubled: 12 });
	});

	it('routes requests through the worker and resolves by correlated id', async () => {
		vi.stubGlobal('Worker', class {});
		const fake = new FakeWorker();
		const client = new RasterWorkerClient<FakeReq, FakeResult>(
			() => fake as unknown as Worker,
			() => {
				throw new Error('sync fallback should not run when worker is present');
			}
		);
		const [a, b] = await Promise.all([client.render({ value: 1 }), client.render({ value: 2 })]);
		expect(a).toEqual({ doubled: 2 });
		expect(b).toEqual({ doubled: 4 });
	});

	it('rejects the pending promise on a worker error response', async () => {
		vi.stubGlobal('Worker', class {});
		const fake = new FakeWorker();
		fake.postMessage = (msg) => {
			queueMicrotask(() => {
				fake.onmessage?.({ data: { id: msg.id, error: 'nope' } } as MessageEvent);
			});
		};
		const client = new RasterWorkerClient<FakeReq, FakeResult>(
			() => fake as unknown as Worker,
			() => {
				throw new Error('sync fallback should not run');
			}
		);
		await expect(client.render({ value: 1 })).rejects.toThrow('nope');
	});

	it('ignores a stale response whose id has already been consumed', async () => {
		vi.stubGlobal('Worker', class {});
		const fake = new FakeWorker();
		const client = new RasterWorkerClient<FakeReq, FakeResult>(
			() => fake as unknown as Worker,
			() => {
				throw new Error('sync fallback should not run');
			}
		);
		const first = await client.render({ value: 1 });
		expect(first).toEqual({ doubled: 2 });
		// Replaying the same (already-consumed) id must not throw -- pending map has no entry left.
		expect(() =>
			fake.onmessage?.({ data: { id: 1, result: { doubled: 999 } } } as MessageEvent)
		).not.toThrow();
	});

	it('terminate() releases the worker and clears pending state', () => {
		vi.stubGlobal('Worker', class {});
		const fake = new FakeWorker();
		const client = new RasterWorkerClient<FakeReq, FakeResult>(
			() => fake as unknown as Worker,
			() => {
				throw new Error('sync fallback should not run');
			}
		);
		client.terminate();
		expect(fake.terminated).toBe(true);
	});
});
