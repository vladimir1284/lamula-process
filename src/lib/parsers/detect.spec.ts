import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { detectParsers, parseObservation } from './detect';
import { PARSER_DESCRIPTORS } from './registry';

const FIXTURES = fileURLToPath(new URL('../../../test-fixtures/observations', import.meta.url));

function readFixture(relativePath: string): Uint8Array {
	return new Uint8Array(readFileSync(`${FIXTURES}/${relativePath}`));
}

describe('detectParsers', () => {
	it('picks rainbow5 for a real .vol fixture by extension and content', () => {
		const input = {
			fileName: 'rainbow/bandaS/2014100600013200dBZ.vol',
			bytes: readFixture('rainbow/bandaS/2014100600013200dBZ.vol')
		};
		expect(detectParsers(input).map((d) => d.id)).toEqual(['rainbow5']);
	});

	it('picks nexrad-l2 for a real gzip-wrapped Archive II fixture', () => {
		const input = {
			fileName: 'nexrad-l2/KMLB20121026_120332_V06.gz',
			bytes: readFixture('nexrad-l2/KMLB20121026_120332_V06.gz')
		};
		expect(detectParsers(input).map((d) => d.id)).toEqual(['nexrad-l2']);
	});

	it('picks insmet for a real .obs fixture by extension and content', () => {
		const input = {
			fileName: 'insmet/c02y1830.obs',
			bytes: readFixture('insmet/c02y1830.obs')
		};
		expect(detectParsers(input).map((d) => d.id)).toEqual(['insmet']);
	});

	it('matches nothing for an unrelated extension/content', () => {
		const input = { fileName: 'notes.txt', bytes: new TextEncoder().encode('hello') };
		expect(detectParsers(input)).toEqual([]);
	});

	it('picks sigmet-iris for a real IDEAM RAW fixture by filename pattern and content', () => {
		const input = {
			fileName: 'ideam/sigmet-raw/COR250601000029.RAWYSAP',
			bytes: readFixture('ideam/sigmet-raw/COR250601000029.RAWYSAP')
		};
		expect(detectParsers(input).map((d) => d.id)).toEqual(['sigmet-iris']);
	});

	it('picks netcdf-cfradial for a real IDEAM NetCDF fixture by extension and content', () => {
		const input = {
			fileName: 'ideam/netcdf-ppivol/9100SAN-20240101-001327-PPIVol-03bc.nc',
			bytes: readFixture('ideam/netcdf-ppivol/9100SAN-20240101-001327-PPIVol-03bc.nc')
		};
		expect(detectParsers(input).map((d) => d.id)).toEqual(['netcdf-cfradial']);
	});
});

describe('parseObservation', () => {
	it('rejects when no descriptor matches', async () => {
		const input = { fileName: 'notes.txt', bytes: new TextEncoder().encode('hello') };
		await expect(parseObservation(input)).rejects.toThrow(/No parser recognizes/);
	});

	it('routes a real rainbow5 fixture through to a decoded Observation', async () => {
		const input = {
			fileName: 'rainbow/bandaS/2014100600013200dBZ.vol',
			bytes: readFixture('rainbow/bandaS/2014100600013200dBZ.vol')
		};
		const obs = await parseObservation(input);
		expect(obs.site.code).toBe('HNS');
		expect(obs.movements[0].channels[0].moment).toBe('dBZ');
	});

	it('routes a real .obs fixture through to a decoded Observation', async () => {
		const input = {
			fileName: 'insmet/c02y1830.obs',
			bytes: readFixture('insmet/c02y1830.obs')
		};
		const obs = await parseObservation(input);
		expect(obs.site.code).toBe('rdCamaguey1');
		expect(obs.movements[0].channels.some((c) => c.moment === 'dBZ')).toBe(true);
	});

	it('routes a real nexrad-l2 fixture through to a decoded Observation', async () => {
		const input = {
			fileName: 'nexrad-l2/KMLB20121026_120332_V06.gz',
			bytes: readFixture('nexrad-l2/KMLB20121026_120332_V06.gz')
		};
		const obs = await parseObservation(input);
		expect(obs.site.code).toBe('KMLB');
		expect(obs.movements[0].channels.some((c) => c.moment === 'dBZ')).toBe(true);
	});

	it('routes a real IDEAM Sigmet RAW fixture through to a decoded Observation', async () => {
		const input = {
			fileName: 'ideam/sigmet-raw/COR250601000029.RAWYSAP',
			bytes: readFixture('ideam/sigmet-raw/COR250601000029.RAWYSAP')
		};
		const obs = await parseObservation(input);
		expect(obs.site.code).toBe('Corozal, Radar');
		expect(obs.movements[0].channels.some((c) => c.moment === 'dBZ')).toBe(true);
	});

	it('routes a real IDEAM NetCDF CfRadial fixture through to a decoded Observation', async () => {
		const input = {
			fileName: 'ideam/netcdf-ppivol/9100SAN-20240101-001327-PPIVol-03bc.nc',
			bytes: readFixture('ideam/netcdf-ppivol/9100SAN-20240101-001327-PPIVol-03bc.nc')
		};
		const obs = await parseObservation(input);
		expect(obs.site.code).toBe('9100SAN');
		expect(obs.movements[0].channels.some((c) => c.moment === 'dBZ')).toBe(true);
	});

	it('surfaces the last error when every matching descriptor fails', async () => {
		const alwaysThrows = {
			id: 'always-throws',
			label: 'always throws',
			canParse: () => true,
			load: async () => ({
				id: 'always-throws',
				label: 'always throws',
				parse: async () => {
					throw new Error('nope');
				}
			})
		};
		const input = { fileName: 'anything', bytes: new Uint8Array() };
		await expect(parseObservation(input, [alwaysThrows, ...PARSER_DESCRIPTORS])).rejects.toThrow(
			/No parser could read/
		);
	});
});
