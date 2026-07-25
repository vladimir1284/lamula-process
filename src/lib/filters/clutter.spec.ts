import { describe, it, expect } from 'vitest';
import { createCells, setCell, getCell } from '$lib/domain';
import { suppressClutter } from './clutter';

describe('suppressClutter', () => {
	it('passes through cells where the mask is 1 and zeroes/no-datas cells where it is 0', () => {
		const cells = createCells(1, 4);
		[10, 20, 30, 40].forEach((v, i) => setCell(cells, 0, i, v, 'ok'));

		suppressClutter(cells, [1, 0, 1, 1]);

		expect(getCell(cells, 0, 0)).toEqual({ value: 10, flag: 'ok' });
		expect(getCell(cells, 0, 1)).toEqual({ value: 0, flag: 'no-data' });
		expect(getCell(cells, 0, 2)).toEqual({ value: 30, flag: 'ok' });
	});

	it('leaves the very last cell of the flat array untouched (preserved legacy off-by-one)', () => {
		const cells = createCells(1, 4);
		[10, 20, 30, 40].forEach((v, i) => setCell(cells, 0, i, v, 'ok'));

		suppressClutter(cells, [0, 0, 0, 0]);

		expect(getCell(cells, 0, 3)).toEqual({ value: 40, flag: 'ok' });
	});

	it('scales (rather than flags) a non-binary mask value', () => {
		const cells = createCells(1, 2);
		setCell(cells, 0, 0, 10, 'ok');
		setCell(cells, 0, 1, 20, 'ok');

		suppressClutter(cells, [0.5, 1]);

		expect(getCell(cells, 0, 0)).toEqual({ value: 5, flag: 'ok' });
	});

	it('throws when the mask length does not match the cell count', () => {
		const cells = createCells(1, 4);
		expect(() => suppressClutter(cells, [1, 1])).toThrow(/does not match/);
	});
});
