import { describe, it, expect } from 'vitest';
import { getCell } from '$lib/domain/cells';
import { makeScan } from '$lib/render/scanFixtures';
import { computeAccumulate, DEFAULT_INTERVAL_MS } from './accumulate';
import { dbzToRainRate } from './rainRate';

const WIDE = { beamWidthDeg: 1, bottomM: -100_000, topM: 100_000 };
const R30 = dbzToRainRate(30); // mm/h at dBZ 30, default Z-R
const INTERVAL_H = DEFAULT_INTERVAL_MS / 3_600_000;

function frame(timeMs: number) {
	return {
		timeMs,
		scans: [makeScan({ numRays: 4, numGates: 3, gateLengthM: 1000, angleDeg: 0, fill: () => 30 })]
	};
}

describe('computeAccumulate', () => {
	it('a single observation accumulates one interval of rain', () => {
		const { scan, unit } = computeAccumulate([frame(0)], WIDE);
		expect(unit).toBe('mm');
		// mean rate R30 over the default interval (5 min)
		expect(getCell(scan.cells, 0, 1).value).toBeCloseTo(INTERVAL_H * R30, 6);
	});

	it('two observations 5 min apart sum their contributions', () => {
		const t1 = DEFAULT_INTERVAL_MS; // exactly one interval later
		const { scan } = computeAccumulate([frame(0), frame(t1)], WIDE);
		// frame0 Δt = min(interval, t1-0) = interval; frame1 (last) Δt = interval
		expect(getCell(scan.cells, 0, 1).value).toBeCloseTo(2 * INTERVAL_H * R30, 6);
	});

	it('caps the per-observation duration at the interval across a large gap', () => {
		const bigGap = 60 * 60 * 1000; // 1 h gap, far beyond the 5-min interval
		const { scan } = computeAccumulate([frame(0), frame(bigGap)], WIDE);
		// both capped at interval → still 2·interval·R, not 1h+interval
		expect(getCell(scan.cells, 0, 1).value).toBeCloseTo(2 * INTERVAL_H * R30, 6);
	});

	it('marks cells with no echoes no-data', () => {
		const { scan } = computeAccumulate([frame(0)], {
			beamWidthDeg: 1,
			bottomM: 50_000,
			topM: 60_000
		});
		expect(getCell(scan.cells, 0, 1).flag).toBe('no-data');
	});
});
