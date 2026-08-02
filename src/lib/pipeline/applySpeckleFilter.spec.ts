import { describe, it, expect } from 'vitest';
import type { Channel } from '$lib/domain/types';
import { getCell, setCell } from '$lib/domain';
import { makeScan } from '$lib/render/scanFixtures';
import { seedPaletteBook } from '$lib/platform';
import type { ChannelRef } from './select';
import { applySpeckleFilter } from './applySpeckleFilter';

function refFor(channel: Channel): ChannelRef {
	return { movement: { id: 0, kind: 'PPI', channels: [channel] }, channel, index: 0 };
}

describe('applySpeckleFilter', () => {
	it('erases a short signal run using the gate count converted from metres', () => {
		const scan = makeScan({ numRays: 1, numGates: 10, gateLengthM: 1000 });
		for (const [g, v] of [
			[0, -5],
			[1, -5],
			[2, 10],
			[3, 10],
			[4, -5],
			[5, -5]
		] as const) {
			setCell(scan.cells, 0, g, v, 'ok');
		}
		const channel: Channel = { id: 0, moment: 'dBZ', scans: [scan] };
		const book = seedPaletteBook();
		// dBZ's seeded palette's lowest stop must sit strictly between -5 and 10 so -5 reads as
		// background and 10 reads as signal; the 2-gate run at [2,3] must be shorter than the
		// 5000 m / 1000 m/gate = 5-gate cap.
		const lowest = book.palettes.find((p) => p.name === book.assignments['dBZ'])!.stops[0].value;
		expect(lowest).toBeGreaterThan(-5);
		expect(lowest).toBeLessThan(10);

		const [filtered] = applySpeckleFilter([refFor(channel)], book, 5000);

		expect(getCell(filtered.channel.scans[0].cells, 0, 2)).toEqual({ value: 0, flag: 'no-data' });
		expect(getCell(filtered.channel.scans[0].cells, 0, 3)).toEqual({ value: 0, flag: 'no-data' });
		// source untouched
		expect(getCell(scan.cells, 0, 2)).toEqual({ value: 10, flag: 'ok' });
	});

	it('distanceM <= 0 is a no-op and returns the input array as-is', () => {
		const channel: Channel = { id: 0, moment: 'dBZ', scans: [makeScan()] };
		const refs = [refFor(channel)];
		expect(applySpeckleFilter(refs, seedPaletteBook(), 0)).toBe(refs);
	});

	it('converts the metres threshold per-scan using each scan gate spacing', () => {
		const scan = makeScan({ numRays: 1, numGates: 6, gateLengthM: 500 });
		for (const [g, v] of [
			[0, -5],
			[1, 10],
			[2, -5],
			[3, -5],
			[4, -5],
			[5, -5]
		] as const) {
			setCell(scan.cells, 0, g, v, 'ok');
		}
		const channel: Channel = { id: 0, moment: 'dBZ', scans: [scan] };
		const book = seedPaletteBook();
		// 1500 m / 500 m-per-gate = 3-gate cap; the 1-gate run at [1] must be erased.
		const [filtered] = applySpeckleFilter([refFor(channel)], book, 1500);
		expect(getCell(filtered.channel.scans[0].cells, 0, 1)).toEqual({ value: 0, flag: 'no-data' });
	});
});
