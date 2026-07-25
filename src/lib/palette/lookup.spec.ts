import { describe, it, expect } from 'vitest';
import type { Palette } from './types';
import { paletteIndex, colorForValue } from './lookup';

// Mirrors DBZ.pal's shape (name/captions trimmed for brevity): thresholds 85,90,...,160.
const PALETTE: Palette = {
	name: 'test',
	smooth: false,
	stops: [
		{ value: 85, color: [0, 0, 117], caption: '' },
		{ value: 90, color: [0, 236, 236], caption: 'debil' },
		{ value: 100, color: [0, 0, 245], caption: 'debil' },
		{ value: 120, color: [255, 255, 0], caption: 'fuerte' },
		{ value: 160, color: [255, 255, 255], caption: '' }
	]
};

describe('paletteIndex', () => {
	it('picks the first stop whose own threshold is >= value', () => {
		expect(paletteIndex(PALETTE, 0)).toBe(0);
		expect(paletteIndex(PALETTE, 85)).toBe(0);
		expect(paletteIndex(PALETTE, 86)).toBe(1);
		expect(paletteIndex(PALETTE, 90)).toBe(1);
		expect(paletteIndex(PALETTE, 91)).toBe(2);
		expect(paletteIndex(PALETTE, 100)).toBe(2);
	});

	it('clamps to the last stop above the highest threshold', () => {
		expect(paletteIndex(PALETTE, 160)).toBe(4);
		expect(paletteIndex(PALETTE, 255)).toBe(4);
	});
});

describe('colorForValue', () => {
	it('returns the color of the resolved stop', () => {
		expect(colorForValue(PALETTE, 0)).toEqual([0, 0, 117]);
		expect(colorForValue(PALETTE, 95)).toEqual([0, 0, 245]);
		expect(colorForValue(PALETTE, 255)).toEqual([255, 255, 255]);
	});

	it('throws for an empty palette', () => {
		expect(() => colorForValue({ name: 'empty', smooth: false, stops: [] }, 0)).toThrow(/no stops/);
	});
});
