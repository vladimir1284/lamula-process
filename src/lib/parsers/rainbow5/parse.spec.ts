import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Scan } from '$lib/domain';
import { parseRainbow5 } from './parse';

const FIXTURES = fileURLToPath(
	new URL('../../../../test-fixtures/observations/rainbow', import.meta.url)
);

function readFixture(relativePath: string): Uint8Array {
	return new Uint8Array(readFileSync(`${FIXTURES}/${relativePath}`));
}

// Mirrors test-fixtures/reference/rainbow/rainbow_probe.py's own "valid"/"phys" stats: valid gates
// are flag 'ok' (code 0), phys range is the min/max over just those. Ground truth values below
// come straight from running that reference decoder against these fixtures (see docs/formatos.md).
function stats(scan: Scan) {
	const { values, flags } = scan.cells;
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

describe('parseRainbow5 (bandaS, S-band, Tegucigalpa)', () => {
	it('decodes site/design/channel metadata and all 15 elevation scans', async () => {
		const obs = await parseRainbow5(readFixture('bandaS/2014100600013200dBZ.vol'));

		expect(obs.timestamp).toBe('2014-10-06T00:06:31');
		expect(obs.design).toBe('HNS_250_ZVW_new.vol');
		expect(obs.site).toEqual({
			name: 'Tegucigalpa',
			code: 'HNS',
			lat: 13.90792,
			lon: -87.130992,
			altM: 1997
		});

		expect(obs.movements).toHaveLength(1);
		expect(obs.movements[0].kind).toBe('PPI');
		const [channel] = obs.movements[0].channels;
		expect(channel.moment).toBe('dBZ');
		expect(channel.waveLengthM).toBeCloseTo(0.10452);
		expect(channel.scans).toHaveLength(15);
	});

	it('decodes the lowest tilt (elev 0.0deg) with real gate/angle/value data', async () => {
		const obs = await parseRainbow5(readFixture('bandaS/2014100600013200dBZ.vol'));
		const scan = obs.movements[0].channels[0].scans[0];

		expect(scan.angleDeg).toBeCloseTo(0.0);
		expect(scan.numRays).toBe(361);
		expect(scan.numGates).toBe(500);
		expect(scan.gateLengthM).toBeCloseTo(500);
		expect(scan.rangeToFirstGateM).toBe(0);
		expect(scan.rayStartAnglesDeg[0]).toBeCloseTo(68.03, 1);
		expect(scan.rayStartAnglesDeg[360]).toBeCloseTo(68.02, 1);

		const { count, min, max } = stats(scan);
		expect(count).toBe(28530);
		expect(min).toBeCloseTo(-31.5);
		expect(max).toBeCloseTo(50.5);
	});

	it('decodes the highest tilt (elev 30.0deg), where max range shrinks but gate size stays fixed', async () => {
		const obs = await parseRainbow5(readFixture('bandaS/2014100600013200dBZ.vol'));
		const scan = obs.movements[0].channels[0].scans[14];

		expect(scan.angleDeg).toBeCloseTo(30.0);
		expect(scan.numRays).toBe(361);
		expect(scan.numGates).toBe(80);
		expect(scan.gateLengthM).toBeCloseTo(500);

		const { count, min, max } = stats(scan);
		expect(count).toBe(9276);
		expect(min).toBeCloseTo(-31.5);
		expect(max).toBeCloseTo(3.0);
	});
});

describe('parseRainbow5 (bandaX, X-band, La Ceiba)', () => {
	it('decodes dBZ across its 4 elevations with the smaller 250m gate size', async () => {
		const obs = await parseRainbow5(readFixture('bandaX/2014051515354300dBZ.vol'));

		expect(obs.site).toEqual({
			name: 'La Ceiba',
			code: 'HNX',
			lat: 15.77182,
			lon: -86.80327,
			altM: 29
		});
		const [channel] = obs.movements[0].channels;
		expect(channel.waveLengthM).toBeCloseTo(0.03189);
		expect(channel.scans).toHaveLength(4);

		const first = channel.scans[0];
		expect(first.gateLengthM).toBeCloseTo(250);
		const firstStats = stats(first);
		expect(firstStats.count).toBe(3698);
		expect(firstStats.min).toBeCloseTo(-31.5);
		expect(firstStats.max).toBeCloseTo(40.5);

		const last = channel.scans[3];
		const lastStats = stats(last);
		expect(lastStats.count).toBe(7452);
		expect(lastStats.max).toBeCloseTo(49.0);
	});

	it('decodes RhoHV (depth=8, [0,1] range)', async () => {
		const obs = await parseRainbow5(readFixture('bandaX/2014051515354300RhoHV.vol'));
		const [channel] = obs.movements[0].channels;
		expect(channel.moment).toBe('RhoHV');

		const first = stats(channel.scans[0]);
		expect(first.count).toBe(4380);
		expect(first.min).toBeCloseTo(0.008, 2);
		expect(first.max).toBeCloseTo(1.0);

		const last = stats(channel.scans[3]);
		expect(last.min).toBeCloseTo(0.02, 2);
	});

	it('decodes uPhiDP, the only depth=16 moment in the fixtures', async () => {
		const obs = await parseRainbow5(readFixture('bandaX/2014051515354300uPhiDP.vol'));
		const [channel] = obs.movements[0].channels;
		expect(channel.moment).toBe('uPhiDP');

		const first = stats(channel.scans[0]);
		expect(first.count).toBe(4380);
		expect(first.min).toBeCloseTo(0.121, 2);
		expect(first.max).toBeCloseTo(359.962, 1);

		const last = stats(channel.scans[3]);
		expect(last.min).toBeCloseTo(0.209, 2);
		expect(last.max).toBeCloseTo(359.896, 1);
	});
});
