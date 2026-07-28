import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Channel } from '$lib/domain';
import { parseInsmet } from './parse';

const FIXTURES = fileURLToPath(
	new URL('../../../../test-fixtures/observations/insmet', import.meta.url)
);

function readFixture(name: string): Uint8Array {
	return new Uint8Array(readFileSync(`${FIXTURES}/${name}`));
}

// Ground truth below comes from directly decoding these fixtures with Python (struct+zlib stdlib),
// cross-checked against test-fixtures/reference/insmet/obs_probe_py3.py and docs/formatos.md.
function stats(channel: Channel, scanIdx: number) {
	const { values, flags } = channel.scans[scanIdx].cells;
	let count = 0;
	let min = Infinity;
	let max = -Infinity;
	for (let i = 0; i < values.length; i++) {
		if (flags[i] !== 0) continue;
		count++;
		if (values[i] < min) min = values[i];
		if (values[i] > max) max = values[i];
	}
	return { count, min, max };
}

describe('parseInsmet (c01y0815.obs, VCP_31, rdCamaguey1)', () => {
	it('decodes site/design/timestamp and splits channels by (source channel, moment)', async () => {
		const obs = await parseInsmet(readFixture('c01y0815.obs'));

		expect(obs.site).toEqual({ name: 'rdCamaguey1', code: 'rdCamaguey1' });
		expect(obs.design).toBe('VCP_31');
		expect(obs.timestamp).toBe('2014-05-01T08:15:10.148Z');
		expect(obs.movements).toHaveLength(1);
		expect(obs.movements[0].kind).toBe('PPI');

		// 18 PPIs: 3 dBZ (channel 0) + 6 V + 6 W + 3 dBZ (channel 1, batch cuts) -> 4 groups.
		const channels = obs.movements[0].channels;
		expect(channels).toHaveLength(4);
		expect(channels.map((c) => c.moment).sort()).toEqual(['V', 'W', 'dBZ', 'dBZ']);
	});

	it('decodes the long-pulse reflectivity channel (channel 0) with real calibration', async () => {
		const obs = await parseInsmet(readFixture('c01y0815.obs'));
		// Both channel 0 and channel 1 produce a 3-scan 'dBZ' group here; disambiguate by
		// calibration, since that's the whole reason they're kept as separate Channel entries.
		const channel = obs.movements[0].channels.find(
			(c) => c.moment === 'dBZ' && (c.calibration?.metPotential ?? 0) < -30
		)!;

		expect(channel.waveLengthM).toBeCloseTo(0.1);
		expect(channel.beamWidthDeg).toBeCloseTo(1.5);
		expect(channel.calibration?.metPotential).toBeCloseTo(-36.9897, 3);
		expect(channel.scans[0].numRays).toBe(360);
		expect(channel.scans[0].numGates).toBe(1800);
		expect(channel.scans[0].gateLengthM).toBeCloseTo(250);
		expect(channel.scans[0].angleDeg).toBeCloseTo(0.0);
		expect(channel.scans[0].rangeToFirstGateM).toBe(0);
		expect(channel.scans[0].rayStartAnglesDeg[0]).toBeCloseTo(0);
		expect(channel.scans[0].rayStartAnglesDeg[180]).toBeCloseTo(180);

		const { count, min, max } = stats(channel, 0);
		expect(count).toBe(44903);
		expect(min).toBe(-17);
		expect(max).toBe(72);
	});

	it('decodes the short-pulse batch channel (channel 1) V/W with a different calibration', async () => {
		const obs = await parseInsmet(readFixture('c01y0815.obs'));
		const velocity = obs.movements[0].channels.find((c) => c.moment === 'V')!;
		const spectrumWidth = obs.movements[0].channels.find((c) => c.moment === 'W')!;

		expect(velocity.calibration?.metPotential).toBeCloseTo(-26.9897, 3);
		expect(velocity.scans).toHaveLength(6);
		expect(spectrumWidth.scans).toHaveLength(6);

		// channel 1's own number_of_cells field (450) is NOT the real per-row gate count -- the blob
		// always decodes to the same 1800-gate row length as channel 0 in this fixture.
		expect(velocity.scans[0].numGates).toBe(1800);
	});

	it('also produces a channel-1 dBZ group distinct from channel-0 dBZ (batch cuts)', async () => {
		const obs = await parseInsmet(readFixture('c02y1830.obs'));
		const dbzGroups = obs.movements[0].channels.filter((c) => c.moment === 'dBZ');

		expect(dbzGroups).toHaveLength(2);
		const metPotentials = dbzGroups
			.map((c) => c.calibration?.metPotential ?? 0)
			.sort((a, b) => a - b);
		expect(metPotentials[0]).toBeCloseTo(-36.9897, 3);
		expect(metPotentials[1]).toBeCloseTo(-26.9897, 3);
	});
});

describe('parseInsmet (p15g1530.obs, older format, unDB measure)', () => {
	it('decodes site/design/timestamp for the 2007 rdPilon single-channel fixture', async () => {
		const obs = await parseInsmet(readFixture('p15g1530.obs'));

		expect(obs.site).toEqual({ name: 'rdPilon', code: 'rdPilon' });
		expect(obs.design).toBe('VOL02_15');
		expect(obs.timestamp).toBe('2007-08-15T15:30:21.562Z');
		expect(obs.movements[0].channels).toHaveLength(1);
		expect(obs.movements[0].channels[0].moment).toBe('dBZ');
	});

	it('range-corrects unDB to dBZ via byte + met_potential + max(0, 20*log10(range_km))', async () => {
		const obs = await parseInsmet(readFixture('p15g1530.obs'));
		const channel = obs.movements[0].channels[0];

		expect(channel.calibration?.metPotential).toBeCloseTo(-35.0997, 3);
		expect(channel.scans[0].numRays).toBe(256);
		expect(channel.scans[0].numGates).toBe(1500);
		expect(channel.scans[0].gateLengthM).toBeCloseTo(300);

		// Ground truth from independently re-implementing dB2dBZ() in Python against the raw bytes
		// (test-fixtures/reference/insmet/Obs_Parser.py's formula), not from this parser itself.
		const { count, min, max } = stats(channel, 0);
		expect(count).toBe(6459);
		expect(min).toBeCloseTo(-13.1932, 3);
		expect(max).toBeCloseTo(56.3653, 3);
	});
});

describe('parseInsmet (c27a0815VCP31.obs, single physical channel)', () => {
	it('decodes dBZ/V/W all sourced from the one channel descriptor', async () => {
		const obs = await parseInsmet(readFixture('c27a0815VCP31.obs'));

		expect(obs.design).toBe('VCP_31_Merged');
		const channels = obs.movements[0].channels;
		expect(channels).toHaveLength(3);
		expect(channels.map((c) => c.moment).sort()).toEqual(['V', 'W', 'dBZ']);
		for (const channel of channels) {
			expect(channel.scans).toHaveLength(6);
			expect(channel.calibration?.metPotential).toBeCloseTo(-36.9897, 3);
		}
	});
});
