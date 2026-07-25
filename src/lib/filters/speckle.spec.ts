import { describe, it, expect } from 'vitest';
import { createCells, setCell, getCell } from '$lib/domain';
import { removeRadialSpeckle } from './speckle';

function fillRay(numGates: number, values: number[]) {
	const cells = createCells(1, numGates);
	values.forEach((v, i) => setCell(cells, 0, i, v, 'ok'));
	return cells;
}

describe('removeRadialSpeckle', () => {
	it('erases a short run of signal (confirmed background before the run-length cap)', () => {
		// background(<=0) at 0,1, signal at 2,3, background from 4 on -- run length 2, cap 5, so the
		// filter actually checks index 4 (background) before the cap would short-circuit that check.
		const cells = fillRay(10, [-5, -5, 10, 10, -5, -5, -5, -5, -5, -5]);
		removeRadialSpeckle(cells, 0, 5);

		for (const i of [1, 2, 3, 4]) {
			expect(getCell(cells, 0, i)).toEqual({ value: 0, flag: 'no-data' });
		}
		// untouched background outside the erased span
		expect(getCell(cells, 0, 0)).toEqual({ value: -5, flag: 'ok' });
		expect(getCell(cells, 0, 5)).toEqual({ value: -5, flag: 'ok' });
	});

	it('leaves a long enough run of signal untouched', () => {
		const cells = fillRay(10, [-5, -5, 10, 10, 10, 10, 10, -5, -5, -5]);
		removeRadialSpeckle(cells, 0, 3);

		for (const i of [2, 3, 4, 5, 6]) {
			expect(getCell(cells, 0, i)).toEqual({ value: 10, flag: 'ok' });
		}
	});

	it('treats any non-ok flag as background regardless of its leftover value', () => {
		const cells = createCells(1, 6);
		setCell(cells, 0, 0, -5, 'ok');
		setCell(cells, 0, 1, 999, 'below-threshold'); // stale/placeholder value, still background
		setCell(cells, 0, 2, 10, 'ok');
		setCell(cells, 0, 3, 10, 'ok');
		setCell(cells, 0, 4, -5, 'ok');
		setCell(cells, 0, 5, -5, 'ok');

		removeRadialSpeckle(cells, 0, 5);

		expect(getCell(cells, 0, 2)).toEqual({ value: 0, flag: 'no-data' });
		expect(getCell(cells, 0, 3)).toEqual({ value: 0, flag: 'no-data' });
	});

	it('is a no-op when minRunLength is 0 or negative', () => {
		const cells = fillRay(6, [-5, -5, 10, 10, -5, -5]);
		removeRadialSpeckle(cells, 0, 0);
		expect(getCell(cells, 0, 2)).toEqual({ value: 10, flag: 'ok' });

		removeRadialSpeckle(cells, 0, -1);
		expect(getCell(cells, 0, 2)).toEqual({ value: 10, flag: 'ok' });
	});

	it('filters each ray independently', () => {
		const cells = createCells(2, 10);
		// ray 0: short run (length 2), should be erased under minRunLength=5
		[-5, -5, 10, 10, -5, -5, -5, -5, -5, -5].forEach((v, i) => setCell(cells, 0, i, v, 'ok'));
		// ray 1: long run (length 6), should survive
		[-5, -5, 10, 10, 10, 10, 10, 10, -5, -5].forEach((v, i) => setCell(cells, 1, i, v, 'ok'));

		removeRadialSpeckle(cells, 0, 5);

		expect(getCell(cells, 0, 2)).toEqual({ value: 0, flag: 'no-data' });
		expect(getCell(cells, 1, 2)).toEqual({ value: 10, flag: 'ok' });
		expect(getCell(cells, 1, 6)).toEqual({ value: 10, flag: 'ok' });
	});
});
