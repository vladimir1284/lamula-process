import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Scan } from '$lib/domain';
import { parseCfRadial } from './parse';

const FIXTURE = fileURLToPath(
	new URL(
		'../../../../test-fixtures/observations/ideam/netcdf-ppivol/9100SAN-20240101-001327-PPIVol-03bc.nc',
		import.meta.url
	)
);

function readFixture(): Uint8Array {
	return new Uint8Array(readFileSync(FIXTURE));
}

// Ground truth from netCDF4-python against this exact fixture (test-fixtures/reference/ideam/netcdf_probe.py).
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

describe('parseCfRadial (santa_elena/SIATA fixture)', () => {
	it('decodes site metadata straight from the file (no known-sites.json lookup)', async () => {
		const obs = await parseCfRadial(readFixture(), '9100SAN-20240101-001327-PPIVol-03bc.nc');

		expect(obs.site.code).toBe('9100SAN');
		expect(obs.site.lat).toBeCloseTo(6.19088077545166);
		expect(obs.site.lon).toBeCloseTo(-75.52862548828125);
		expect(obs.site.altM).toBe(2813);
		expect(obs.timestamp).toBe('2024-01-01T00:13:30Z');
		expect(obs.movements).toHaveLength(1);
		expect(obs.movements[0].kind).toBe('PPI');
	});

	it('decodes 7 supported moments (UH/UV/DBZV/NCPH/NCPV/SNRHC/SNRVC/VELV/WIDTHV/CCORH/CCORV/HMC dropped)', async () => {
		const obs = await parseCfRadial(readFixture(), '9100SAN-20240101-001327-PPIVol-03bc.nc');
		const moments = obs.movements[0].channels.map((c) => c.moment).sort();
		expect(moments).toEqual(['KDP', 'RhoHV', 'V', 'W', 'ZDR', 'dBZ', 'uPhiDP'].sort());
	});

	it('decodes one 147x960 PPI sweep per channel with the fixture-known geometry', async () => {
		const obs = await parseCfRadial(readFixture(), '9100SAN-20240101-001327-PPIVol-03bc.nc');
		for (const channel of obs.movements[0].channels) {
			expect(channel.scans).toHaveLength(1);
			const scan = channel.scans[0];
			expect(scan.numRays).toBe(147);
			expect(scan.numGates).toBe(960);
			expect(scan.rangeToFirstGateM).toBeCloseTo(125);
			expect(scan.gateLengthM).toBeCloseTo(250);
			expect(scan.angleDeg).toBeCloseTo(0.5);
		}
	});

	it('matches netCDF4-python-verified per-moment valid-count/min/max', async () => {
		const obs = await parseCfRadial(readFixture(), '9100SAN-20240101-001327-PPIVol-03bc.nc');
		const byMoment = new Map(obs.movements[0].channels.map((c) => [c.moment, c.scans[0]]));

		const dbz = stats(byMoment.get('dBZ')!);
		expect(dbz.count).toBe(12619);
		expect(dbz.min).toBeCloseTo(-31.5);
		expect(dbz.max).toBeCloseTo(41.5);

		const vel = stats(byMoment.get('V')!);
		expect(vel.count).toBe(5773);
		expect(vel.min).toBeCloseTo(-3.34, 2);
		expect(vel.max).toBeCloseTo(3.34, 2);

		const zdr = stats(byMoment.get('ZDR')!);
		expect(zdr.count).toBe(141120);
		expect(zdr.min).toBeCloseTo(-7.9, 1);
		expect(zdr.max).toBeCloseTo(8);

		const rhohv = stats(byMoment.get('RhoHV')!);
		expect(rhohv.count).toBe(141120);
		expect(rhohv.min).toBeCloseTo(0.1272, 3);
		expect(rhohv.max).toBeCloseTo(0.9972, 3);

		// This fixture's PHIDP is entirely fill/no-data -- a real data-availability quirk, not a bug.
		const phidp = stats(byMoment.get('uPhiDP')!);
		expect(phidp.count).toBe(0);
	});

	it('throws a clear error on a non-CfRadial classic-NetCDF file', async () => {
		// A minimal valid classic-NetCDF header (no Conventions attr) -- valid NetCDF3, wrong Conventions.
		const bytes = readFixture();
		expect(bytes.slice(0, 3).join(',')).toBe('67,68,70'); // 'C','D','F' sanity check on the fixture itself
		await expect(
			parseCfRadial(new Uint8Array([0x43, 0x44, 0x46, 0x01, 0, 0, 0, 0]), 'bad.nc')
		).rejects.toThrow();
	});
});
