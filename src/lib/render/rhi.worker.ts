/// <reference lib="webworker" />
import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type { RhiRasterOptions, RhiRasterResult } from './rasterizeRHI';
import { rasterizeRHI } from './rasterizeRHI';

export interface RhiWorkerRequest {
	id: number;
	scan: Scan;
	palette: Palette;
	opts: RhiRasterOptions;
}

export interface RhiWorkerResponse {
	id: number;
	result?: RhiRasterResult;
	error?: string;
}

// The rasterizer is a pure function (see rasterizeRHI.ts); the worker only moves it off the main
// thread. The result's RGBA buffer is transferred back to avoid a copy.
self.onmessage = (ev: MessageEvent<RhiWorkerRequest>) => {
	const { id, scan, palette, opts } = ev.data;
	try {
		const result = rasterizeRHI(scan, palette, opts);
		const res: RhiWorkerResponse = { id, result };
		(self as unknown as Worker).postMessage(res, [result.rgba.buffer]);
	} catch (e) {
		const res: RhiWorkerResponse = { id, error: e instanceof Error ? e.message : String(e) };
		(self as unknown as Worker).postMessage(res);
	}
};
