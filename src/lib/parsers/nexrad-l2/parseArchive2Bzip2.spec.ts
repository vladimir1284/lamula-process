import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Scan } from '$lib/domain';
import { parseNexradL2 } from './parse';

// Real-world file pulled from the public NOAA/AWS bucket (unlike the KMLB fixtures in
// parse.spec.ts, which happen to be uncompressed): exercises the bzip2-record decompression path
// in archive2Bzip2.ts that every file off that bucket actually needs.
const FIXTURE = fileURLToPath(
	new URL(
		'../../../../test-fixtures/observations/nexrad-l2/KBYX20260726_113948_V06',
		import.meta.url
	)
);

// Ground truth comes from running test-fixtures/reference/nexrad-l2/l2_probe_py3.py (extended
// with the same bzip2-record decompression, see its own inflate_archive2_bzip2) against this exact
// fixture: the first message-31 radial found (elevation_number=1, azimuth_number=1) and the first
// radial carrying DVEL (elevation_number=2, azimuth_number=1).
function rayStats(scan: Scan, ray: number) {
	const { values, flags, numGates } = scan.cells;
	let count = 0;
	let min = Infinity;
	let max = -Infinity;
	for (let g = 0; g < numGates; g++) {
		const i = ray * numGates + g;
		if (flags[i] !== 0) continue;
		count++;
		if (values[i] < min) min = values[i];
		if (values[i] > max) max = values[i];
	}
	return { count, min, max };
}

function channel(obs: Awaited<ReturnType<typeof parseNexradL2>>, moment: string) {
	const found = obs.movements[0].channels.find((c) => c.moment === moment);
	if (!found) throw new Error(`no ${moment} channel decoded`);
	return found;
}

describe('parseNexradL2 (real KBYX bzip2-compressed Archive II fixture)', () => {
	it('decodes the volume header, and range/gate geometry is real meters, not garbage', async () => {
		const obs = await parseNexradL2(new Uint8Array(readFileSync(FIXTURE)));

		expect(obs.site.code).toBe('KBYX');
		expect(obs.design).toBe('AR2V0006.882');
		expect(obs.timestamp).toBe('2026-07-26T11:39:48.650Z');

		const ref = channel(obs, 'dBZ').scans[0];
		expect(ref.angleDeg).toBeCloseTo(0.8212, 3);
		expect(ref.numGates).toBe(1832);
		expect(ref.rangeToFirstGateM).toBe(2125);
		expect(ref.gateLengthM).toBe(250);
		expect(ref.rayStartAnglesDeg[0]).toBeCloseTo(358.248, 2);
		const refStats = rayStats(ref, 0);
		expect(refStats.count).toBe(413);
		expect(refStats.min).toBeCloseTo(-31.5);
		expect(refStats.max).toBeCloseTo(54.5);
	});

	it('decodes the first Doppler radial (elev=2 az=1) with the same range geometry', async () => {
		const obs = await parseNexradL2(new Uint8Array(readFileSync(FIXTURE)));

		const ref = channel(obs, 'dBZ').scans[1];
		expect(ref.angleDeg).toBeCloseTo(0.4834, 3);
		expect(ref.numGates).toBe(1192);
		expect(ref.rangeToFirstGateM).toBe(2125);
		expect(ref.gateLengthM).toBe(250);
		expect(ref.rayStartAnglesDeg[0]).toBeCloseTo(13.192, 2);
		const refStats = rayStats(ref, 0);
		expect(refStats.count).toBe(127);
		expect(refStats.min).toBeCloseTo(-30.5);
		expect(refStats.max).toBeCloseTo(20.5);

		const vel = channel(obs, 'V').scans[0];
		expect(vel.rangeToFirstGateM).toBe(2125);
		expect(vel.gateLengthM).toBe(250);
		const velStats = rayStats(vel, 0);
		expect(velStats.count).toBe(58);
		expect(velStats.min).toBeCloseTo(-11.0);
		expect(velStats.max).toBeCloseTo(19.5);

		const sw = channel(obs, 'W').scans[0];
		const swStats = rayStats(sw, 0);
		expect(swStats.count).toBe(52);
		expect(swStats.min).toBeCloseTo(0.0);
		expect(swStats.max).toBeCloseTo(17.5);
	});

	it('decodes all 12 elevation cuts with sane, consistent range geometry', async () => {
		const obs = await parseNexradL2(new Uint8Array(readFileSync(FIXTURE)));

		const ref = channel(obs, 'dBZ');
		expect(ref.scans).toHaveLength(12);
		for (const scan of ref.scans) {
			expect(scan.rangeToFirstGateM).toBe(2125);
			expect(scan.gateLengthM).toBe(250);
			expect(scan.numRays).toBeGreaterThanOrEqual(360);
		}
	});
});
