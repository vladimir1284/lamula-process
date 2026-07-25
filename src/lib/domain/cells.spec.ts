import { describe, it, expect } from 'vitest';
import { createCells, getCell, setCell, cellIndex } from './cells';

describe('cells grid', () => {
	it('defaults every cell to value 0 / flag ok', () => {
		const cells = createCells(2, 3);
		expect(getCell(cells, 0, 0)).toEqual({ value: 0, flag: 'ok' });
		expect(getCell(cells, 1, 2)).toEqual({ value: 0, flag: 'ok' });
	});

	it('round-trips a set value and flag', () => {
		const cells = createCells(2, 3);
		setCell(cells, 1, 2, 42.5, 'range-folded');
		expect(getCell(cells, 1, 2)).toEqual({ value: 42.5, flag: 'range-folded' });
		expect(getCell(cells, 0, 0)).toEqual({ value: 0, flag: 'ok' });
	});

	it('is row-major over ray then gate', () => {
		const cells = createCells(2, 3);
		expect(cellIndex(cells, 0, 0)).toBe(0);
		expect(cellIndex(cells, 0, 2)).toBe(2);
		expect(cellIndex(cells, 1, 0)).toBe(3);
	});

	it('rejects out-of-bounds access', () => {
		const cells = createCells(2, 3);
		expect(() => getCell(cells, 2, 0)).toThrow(RangeError);
		expect(() => getCell(cells, 0, 3)).toThrow(RangeError);
		expect(() => getCell(cells, -1, 0)).toThrow(RangeError);
	});
});
