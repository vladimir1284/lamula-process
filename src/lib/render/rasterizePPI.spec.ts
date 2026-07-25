import { describe, it, expect } from 'vitest';
import type { Palette } from '$lib/palette/types';
import { setCell } from '$lib/domain/cells';
import { makeScan } from './scanFixtures';
import { rasterizePPI } from './rasterizePPI';

const palette: Palette = {
	name: 'test',
	smooth: false,
	stops: [
		{ value: 0, color: [0, 0, 255], caption: 'low' },
		{ value: 100, color: [0, 255, 0], caption: 'mid' },
		{ value: 200, color: [255, 0, 0], caption: 'high' }
	]
};

function pixel(r: ReturnType<typeof rasterizePPI>, px: number, py: number) {
	const o = (py * r.sizePx + px) * 4;
	return [r.rgba[o], r.rgba[o + 1], r.rgba[o + 2], r.rgba[o + 3]];
}

describe('rasterizePPI', () => {
	it('paints inside the disc and leaves the corners transparent', () => {
		const scan = makeScan({ numRays: 8, numGates: 3, gateLengthM: 1000, fill: () => 150 });
		const r = rasterizePPI(scan, palette, { sizePx: 16 });
		expect(r.maxRangeM).toBeCloseTo(2000, 6);
		// centre pixel is inside the disc -> opaque, value 150 -> red (index 2)
		const c = pixel(r, 8, 8);
		expect(c[3]).toBe(255);
		expect([c[0], c[1], c[2]]).toEqual([255, 0, 0]);
		// top-left corner is outside the disc -> transparent
		expect(pixel(r, 0, 0)[3]).toBe(0);
		expect(pixel(r, 15, 15)[3]).toBe(0);
	});

	it('places north up: the pixel just north of centre samples ray 0', () => {
		// value = ray*100+gate; ray 0 = North. Colour ray 0 gate 0 uniquely low (blue), rest high.
		const scan = makeScan({
			numRays: 8,
			numGates: 3,
			gateLengthM: 1000,
			fill: (ray) => (ray === 0 ? 0 : 150)
		});
		const r = rasterizePPI(scan, palette, { sizePx: 32 });
		// a pixel a bit above centre (north) should hit ray 0 -> value 0 -> blue
		const north = pixel(r, 16, 14);
		expect(north[3]).toBe(255);
		expect([north[0], north[1], north[2]]).toEqual([0, 0, 255]);
	});

	it('leaves below-threshold gates transparent by default, opaque when included', () => {
		const scan = makeScan({ numRays: 8, numGates: 3, gateLengthM: 1000, fill: () => 150 });
		for (let ray = 0; ray < scan.numRays; ray++)
			for (let g = 0; g < scan.numGates; g++) setCell(scan.cells, ray, g, 150, 'below-threshold');

		const off = rasterizePPI(scan, palette, { sizePx: 16 });
		expect(pixel(off, 8, 8)[3]).toBe(0);

		const on = rasterizePPI(scan, palette, { sizePx: 16, includeBelowThreshold: true });
		expect(pixel(on, 8, 8)[3]).toBe(255);
	});
});
