import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { readNetcdf3, findVar, ncCharsToString } from './netcdf3';

const FIXTURE = fileURLToPath(
	new URL(
		'../../../test-fixtures/observations/ideam/netcdf-ppivol/9100SAN-20240101-001327-PPIVol-03bc.nc',
		import.meta.url
	)
);

function readFixture(): Uint8Array {
	return new Uint8Array(readFileSync(FIXTURE));
}

// Ground truth below comes straight from netCDF4-python against this exact fixture (see
// test-fixtures/reference/ideam/netcdf_probe.py) -- classic NetCDF is big-endian XDR, unlike
// every other format this app parses, so byte-order bugs here won't show up as garbage, they
// show up as plausible-looking wrong numbers. Cross-check real values, not just "it parses".
describe('readNetcdf3 (real IDEAM CfRadial/PPIVol fixture)', () => {
	it('parses dims, global attrs, and site coordinates', () => {
		const file = readNetcdf3(readFixture());

		expect(file.dims.map((d) => [d.name, d.length])).toEqual([
			['time', 147],
			['range', 960],
			['sweep', 1],
			['frequency', 1],
			['string_length_sm', 10],
			['string_length_md', 25]
		]);
		expect(file.globalAttrs.Conventions).toBe('Cf/Radial instrument_parameters radar_parameters');
		expect(file.globalAttrs.instrument_name).toBe('9100SAN');

		expect(findVar(file, 'latitude').data[0]).toBeCloseTo(6.19088077545166);
		expect(findVar(file, 'longitude').data[0]).toBeCloseTo(-75.52862548828125);
		expect(findVar(file, 'altitude').data[0]).toBe(2813);
	});

	it('reads variable attributes (scale_factor/add_offset/_FillValue) correctly', () => {
		const file = readNetcdf3(readFixture());
		const dbzh = findVar(file, 'DBZH');

		expect(dbzh.attrs.units).toBe('dBZ');
		expect(dbzh.attrs._FillValue).toBe(-32768);
		expect(dbzh.attrs.scale_factor).toBeCloseTo(0.01);
		expect(dbzh.attrs.add_offset).toBe(0);
	});

	it('reads (time, range) 2D variable data flattened in ray-major order', () => {
		const file = readNetcdf3(readFixture());
		const dbzh = findVar(file, 'DBZH');

		expect(dbzh.data.length).toBe(147 * 960);
		// ray 0, gates 0..9 -- exact raw int16 codes from netCDF4-python.
		expect(Array.from(dbzh.data.slice(0, 10))).toEqual([
			-150, -550, -900, -1350, -1800, -1750, -1650, -1700, -1900, -1750
		]);
	});

	it('reads 1D coordinate variables (azimuth, range)', () => {
		const file = readNetcdf3(readFixture());
		const azimuth = findVar(file, 'azimuth');
		const range = findVar(file, 'range');

		expect(azimuth.data.length).toBe(147);
		expect(azimuth.data[0]).toBeCloseTo(313.604736328125);
		expect(azimuth.data[146]).toBeCloseTo(151.1224365234375);
		expect(Array.from(range.data.slice(0, 3))).toEqual([125, 375, 625]);
	});

	it('decodes a char-typed scalar variable via ncCharsToString', () => {
		const file = readNetcdf3(readFixture());
		expect(ncCharsToString(findVar(file, 'sweep_mode'))).toBe('ppi');
	});

	it('spot-checks a fill-value cell and a real-value cell at the last ray/gate', () => {
		const file = readNetcdf3(readFixture());
		const dbzh = findVar(file, 'DBZH');
		const zdr = findVar(file, 'ZDR');
		const idx = 146 * 960 + 959;

		expect(dbzh.data[idx]).toBe(-32768); // fill -- no data at this cell
		expect(zdr.data[idx]).toBe(470); // raw code; 470 * 0.01 = 4.70 dB
	});

	it('throws a clear error on a non-classic (64-bit-offset / CDF-5) version byte', () => {
		const bytes = readFixture();
		const mutated = new Uint8Array(bytes);
		mutated[3] = 2; // CDF\x02 = 64-bit offset, unsupported
		expect(() => readNetcdf3(mutated)).toThrow(/only classic 32-bit-offset/);
	});

	it('throws a clear error on a non-NetCDF file', () => {
		expect(() => readNetcdf3(new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7]))).toThrow(/bad magic/);
	});
});
