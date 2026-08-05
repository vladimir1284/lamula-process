import { describe, it, expect } from 'vitest';
import {
	hasExtension,
	startsWithAscii,
	isGzipMagic,
	isSigmetRawMagic,
	isNetcdf3Magic
} from './sniff';

describe('hasExtension', () => {
	it('matches case-insensitively against any given extension', () => {
		expect(hasExtension('scan.VOL', '.vol')).toBe(true);
		expect(hasExtension('scan.ar2.bz2', '.ar2', '.ar2.bz2')).toBe(true);
		expect(hasExtension('scan.gz', '.vol')).toBe(false);
	});
});

describe('startsWithAscii', () => {
	it('matches a literal ascii prefix', () => {
		const bytes = new TextEncoder().encode('<volume version="5.34.56">');
		expect(startsWithAscii(bytes, '<volume')).toBe(true);
		expect(startsWithAscii(bytes, '<scan')).toBe(false);
	});

	it('rejects input shorter than the prefix', () => {
		expect(startsWithAscii(new TextEncoder().encode('<vo'), '<volume')).toBe(false);
	});
});

describe('isGzipMagic', () => {
	it('recognizes the gzip magic bytes', () => {
		expect(isGzipMagic(new Uint8Array([0x1f, 0x8b, 0x08, 0x00]))).toBe(true);
		expect(isGzipMagic(new Uint8Array([0x00, 0x00]))).toBe(false);
		expect(isGzipMagic(new Uint8Array([0x1f]))).toBe(false);
	});
});

describe('isSigmetRawMagic', () => {
	it('recognizes structure_identifier=27 (PRODUCT_HDR) at byte 0', () => {
		expect(isSigmetRawMagic(new Uint8Array([27, 0, 0, 0]))).toBe(true);
		expect(isSigmetRawMagic(new Uint8Array([23, 0]))).toBe(false); // INGEST_HEADER, not RAW
		expect(isSigmetRawMagic(new Uint8Array([27]))).toBe(false); // too short
	});
});

describe('isNetcdf3Magic', () => {
	it('recognizes the "CDF" + version magic', () => {
		expect(isNetcdf3Magic(new Uint8Array([0x43, 0x44, 0x46, 0x01]))).toBe(true);
		expect(isNetcdf3Magic(new Uint8Array([0x43, 0x44, 0x46, 0x02]))).toBe(true);
		expect(isNetcdf3Magic(new Uint8Array([0x89, 0x48, 0x44, 0x46]))).toBe(false); // HDF5 magic
		expect(isNetcdf3Magic(new Uint8Array([0x43, 0x44, 0x46]))).toBe(false); // too short
	});
});
