import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Scan } from '$lib/domain';
import { parseSigmetIris } from './parse';

const FIXTURES = fileURLToPath(
	new URL('../../../../test-fixtures/observations/ideam/sigmet-raw', import.meta.url)
);

function readFixture(relativePath: string): Uint8Array {
	return new Uint8Array(readFileSync(`${FIXTURES}/${relativePath}`));
}

// Mirrors rainbow5/parse.spec.ts's own pattern: ground truth here comes straight from running
// xradar (test-fixtures/reference/ideam/sigmet_probe.py) against these exact fixtures. One
// gotcha found while porting: xradar's own xarray/datatree wrapping silently drops the DB_VEL
// mask (fills masked cells with 0 instead of leaving them out), so the *raw* per-sweep
// MaskedArray (accessible via IrisRawFile directly, not the datatree wrapper) is the real oracle
// for V's valid count -- 29199 valid gates, not the full 239040 the wrapped array appears to have.
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

describe('parseSigmetIris (Corozal fixture)', () => {
	it('decodes site metadata (site position/altitude read straight from the file header)', async () => {
		const obs = await parseSigmetIris(
			readFixture('COR250601000029.RAWYSAP'),
			'COR250601000029.RAWYSAP'
		);

		expect(obs.site.name).toBe('Corozal, Radar');
		expect(obs.site.lat).toBeCloseTo(9.331, 3);
		expect(obs.site.lon).toBeCloseTo(-75.283, 3);
		expect(obs.site.altM).toBe(143);
		expect(obs.design).toBe('COR250601000029.RAWYSAP');
		expect(obs.movements).toHaveLength(1);
		expect(obs.movements[0].kind).toBe('PPI');
	});

	it('decodes exactly 6 supported moments (DB_HCLASS dropped, no MomentType slot for it)', async () => {
		const obs = await parseSigmetIris(
			readFixture('COR250601000029.RAWYSAP'),
			'COR250601000029.RAWYSAP'
		);
		const moments = obs.movements[0].channels.map((c) => c.moment).sort();
		expect(moments).toEqual(['KDP', 'RhoHV', 'V', 'ZDR', 'dBZ', 'uPhiDP'].sort());
	});

	it('decodes one 360x664 PPI sweep per channel with the fixture-known geometry', async () => {
		const obs = await parseSigmetIris(
			readFixture('COR250601000029.RAWYSAP'),
			'COR250601000029.RAWYSAP'
		);
		for (const channel of obs.movements[0].channels) {
			expect(channel.scans).toHaveLength(1);
			const scan = channel.scans[0];
			expect(scan.numRays).toBe(360);
			expect(scan.numGates).toBe(664);
			expect(scan.rangeToFirstGateM).toBe(300);
			expect(scan.gateLengthM).toBe(450);
			expect(scan.angleDeg).toBeCloseTo(1.0, 1);
		}
	});

	it('matches xradar-verified per-moment valid-count/min/max', async () => {
		const obs = await parseSigmetIris(
			readFixture('COR250601000029.RAWYSAP'),
			'COR250601000029.RAWYSAP'
		);
		const byMoment = new Map(obs.movements[0].channels.map((c) => [c.moment, c.scans[0]]));

		const dbz = stats(byMoment.get('dBZ')!);
		expect(dbz.count).toBe(239040);
		expect(dbz.min).toBeCloseTo(-32);
		expect(dbz.max).toBeCloseTo(59);

		const zdr = stats(byMoment.get('ZDR')!);
		expect(zdr.count).toBe(239040);
		expect(zdr.min).toBeCloseTo(-8);
		expect(zdr.max).toBeCloseTo(7.875);

		const phidp = stats(byMoment.get('uPhiDP')!);
		expect(phidp.count).toBe(239040);
		expect(phidp.min).toBeCloseTo(-0.7086614173228346);
		expect(phidp.max).toBeCloseTo(180);

		const kdp = stats(byMoment.get('KDP')!);
		expect(kdp.count).toBe(74157);
		expect(kdp.min).toBeCloseTo(-28.142589118198874, 1);
		expect(kdp.max).toBeCloseTo(15.303057731820028, 1);

		const rhohv = stats(byMoment.get('RhoHV')!);
		expect(rhohv.count).toBe(74077);
		expect(rhohv.min).toBeCloseTo(0);
		expect(rhohv.max).toBeCloseTo(1);

		// V's *true* oracle count is 29199 (see file header comment) -- the masked, not the
		// xarray-wrapped, count.
		const vel = stats(byMoment.get('V')!);
		expect(vel.count).toBe(29199);
		expect(vel.min).toBeCloseTo(-6.6625, 3);
		expect(vel.max).toBeCloseTo(6.6625, 3);
	});

	it('throws a clear error on a non-Sigmet-RAW file', async () => {
		const garbage = new Uint8Array(20000);
		await expect(parseSigmetIris(garbage, 'garbage.RAW0000')).rejects.toThrow(
			/not a RAW ingest file/
		);
	});
});
