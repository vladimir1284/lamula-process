/// <reference lib="webworker" />
import type { Scan } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import type {
	CrossSectionRasterOptions,
	CrossSectionRasterResult
} from '$lib/products/crossSection';
import { rasterizeCrossSection } from '$lib/products/crossSection';

export interface CrossSectionWorkerRequest {
	id: number;
	scans: Scan[];
	palette: Palette;
	opts: CrossSectionRasterOptions;
}

export interface CrossSectionWorkerResponse {
	id: number;
	result?: CrossSectionRasterResult;
	error?: string;
}

// The rasterizer is a pure function (see products/crossSection.ts); the worker only moves it off
// the main thread. The result's RGBA buffer is transferred back to avoid a copy.
self.onmessage = (ev: MessageEvent<CrossSectionWorkerRequest>) => {
	const { id, scans, palette, opts } = ev.data;
	try {
		const result = rasterizeCrossSection(scans, palette, opts);
		const res: CrossSectionWorkerResponse = { id, result };
		(self as unknown as Worker).postMessage(res, [result.rgba.buffer]);
	} catch (e) {
		const res: CrossSectionWorkerResponse = {
			id,
			error: e instanceof Error ? e.message : String(e)
		};
		(self as unknown as Worker).postMessage(res);
	}
};
