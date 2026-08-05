import { describe, it, expect } from 'vitest';
import type { Observation } from './types';
import { mergeSweeps } from './mergeSweeps';

function fakeSweep(angleDeg: number, timestamp: string, siteCode = 'TEST'): Observation {
	return {
		id: `${siteCode}_${timestamp}`,
		site: { name: siteCode, code: siteCode, lat: 1, lon: 2, altM: 3 },
		timestamp,
		design: 'test-task',
		movements: [
			{
				id: 0,
				kind: 'PPI',
				channels: [
					{
						id: 0,
						moment: 'dBZ',
						scans: [
							{
								id: 0,
								angleDeg,
								rangeToFirstGateM: 300,
								gateLengthM: 450,
								numRays: 2,
								numGates: 2,
								rayStartAnglesDeg: new Float32Array([0, 180]),
								rayStopAnglesDeg: new Float32Array([180, 360]),
								cells: {
									numRays: 2,
									numGates: 2,
									values: new Float32Array([1, 2, 3, 4]),
									flags: new Uint8Array([0, 0, 0, 0])
								}
							}
						]
					}
				]
			}
		]
	};
}

describe('mergeSweeps', () => {
	it('stitches N single-sweep observations into one multi-tilt observation, sorted by elevation', () => {
		const sweeps = [
			fakeSweep(5.0, '2026-01-01T00:02:00Z'),
			fakeSweep(0.5, '2026-01-01T00:00:00Z'),
			fakeSweep(2.0, '2026-01-01T00:01:00Z')
		];

		const { observation, skipped } = mergeSweeps(sweeps);

		expect(skipped).toEqual([]);
		expect(observation.movements).toHaveLength(1);
		expect(observation.movements[0].channels).toHaveLength(1);
		const scans = observation.movements[0].channels[0].scans;
		expect(scans.map((s) => s.angleDeg)).toEqual([0.5, 2.0, 5.0]);
		// re-indexed 0..n-1 in the merged (sorted) order, not the input order
		expect(scans.map((s) => s.id)).toEqual([0, 1, 2]);
		// earliest sweep's timestamp/site/design represent the merged volume
		expect(observation.timestamp).toBe('2026-01-01T00:00:00Z');
	});

	it('drops observations from a different site and reports them in `skipped`', () => {
		const sweeps = [
			fakeSweep(0.5, '2026-01-01T00:00:00Z', 'A'),
			fakeSweep(2.0, '2026-01-01T00:01:00Z', 'B')
		];

		const { observation, skipped } = mergeSweeps(sweeps);

		expect(skipped).toHaveLength(1);
		expect(skipped[0].site.code).toBe('B');
		expect(observation.movements[0].channels[0].scans).toHaveLength(1);
	});

	it('drops observations that already have multiple scans per channel (not single-sweep input)', () => {
		const multiScan = fakeSweep(0.5, '2026-01-01T00:00:00Z');
		multiScan.movements[0].channels[0].scans.push({
			...multiScan.movements[0].channels[0].scans[0],
			id: 1,
			angleDeg: 1.0
		});

		const { observation, skipped } = mergeSweeps([
			fakeSweep(2.0, '2026-01-01T00:01:00Z'),
			multiScan
		]);

		expect(skipped).toHaveLength(1);
		expect(observation.movements[0].channels[0].scans).toHaveLength(1);
	});

	it('groups scans by moment when multiple channels are present', () => {
		const dbz1 = fakeSweep(0.5, '2026-01-01T00:00:00Z');
		const dbz2 = fakeSweep(2.0, '2026-01-01T00:01:00Z');
		dbz1.movements[0].channels.push({ ...dbz1.movements[0].channels[0], id: 1, moment: 'V' });
		dbz2.movements[0].channels.push({ ...dbz2.movements[0].channels[0], id: 1, moment: 'V' });

		const { observation } = mergeSweeps([dbz1, dbz2]);

		expect(observation.movements[0].channels).toHaveLength(2);
		const moments = observation.movements[0].channels.map((c) => c.moment).sort();
		expect(moments).toEqual(['V', 'dBZ']);
		for (const channel of observation.movements[0].channels) {
			expect(channel.scans).toHaveLength(2);
		}
	});

	it('throws only when there is nothing valid to merge', () => {
		expect(() => mergeSweeps([])).toThrow(/no observations to merge/);
		expect(
			() =>
				mergeSweeps([
					fakeSweep(0.5, '2026-01-01T00:00:00Z', 'A'),
					fakeSweep(2.0, '2026-01-01T00:01:00Z', 'B')
				]).observation.site.code
		).not.toThrow(); // one valid (base) observation is enough, never fully empty here
	});
});
