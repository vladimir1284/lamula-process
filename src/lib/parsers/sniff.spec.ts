import { describe, it, expect } from 'vitest';
import { hasExtension, startsWithAscii, isGzipMagic } from './sniff';

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
