/// <reference lib="webworker" />
import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type { RasterOptions, RasterResult } from './rasterizePPI';
import { rasterizePPI } from './rasterizePPI';

export interface PpiWorkerRequest {
	id: number;
	scan: Scan;
	palette: Palette;
	opts: RasterOptions;
}

export interface PpiWorkerResponse {
	id: number;
	result?: RasterResult;
	error?: string;
}

// The rasterizer is a pure function (see rasterizePPI.ts); the worker only moves it off the main
// thread. The result's RGBA buffer is transferred back to avoid a copy.
self.onmessage = (ev: MessageEvent<PpiWorkerRequest>) => {
	const { id, scan, palette, opts } = ev.data;
	try {
		const result = rasterizePPI(scan, palette, opts);
		const res: PpiWorkerResponse = { id, result };
		(self as unknown as Worker).postMessage(res, [result.rgba.buffer]);
	} catch (e) {
		const res: PpiWorkerResponse = { id, error: e instanceof Error ? e.message : String(e) };
		(self as unknown as Worker).postMessage(res);
	}
};
