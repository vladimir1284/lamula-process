import { describe, it, expect } from 'vitest';
import type { Palette } from './types';
import { addStop, removeStop, updateStop, sortStops, renamePalette } from './edit';

const base: Palette = {
	name: 'p',
	smooth: false,
	stops: [
		{ value: 0, color: [0, 0, 0], caption: 'a' },
		{ value: 40, color: [255, 0, 0], caption: 'c' }
	]
};

describe('palette edit helpers', () => {
	it('addStop inserts sorted by value', () => {
		const p = addStop(base, { value: 20, color: [0, 255, 0], caption: 'b' });
		expect(p.stops.map((s) => s.value)).toEqual([0, 20, 40]);
		expect(base.stops).toHaveLength(2); // original untouched
	});

	it('removeStop drops the given index', () => {
		const p = removeStop(base, 0);
		expect(p.stops.map((s) => s.value)).toEqual([40]);
	});

	it('updateStop patches and re-sorts on value change', () => {
		const p = updateStop(base, 0, { value: 100 });
		expect(p.stops.map((s) => s.value)).toEqual([40, 100]);
	});

	it('updateStop recolors without moving', () => {
		const p = updateStop(base, 1, { color: [1, 2, 3] });
		expect(p.stops[1].color).toEqual([1, 2, 3]);
	});

	it('sortStops orders ascending', () => {
		const messy: Palette = { ...base, stops: [base.stops[1], base.stops[0]] };
		expect(sortStops(messy).stops.map((s) => s.value)).toEqual([0, 40]);
	});

	it('renamePalette sets the name', () => {
		expect(renamePalette(base, 'x').name).toBe('x');
	});
});
