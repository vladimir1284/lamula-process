import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { parsePalette } from './parse';

const PALETTES_DIR = fileURLToPath(new URL('../../../legacy/Palettes', import.meta.url));

function readPalette(name: string) {
	return parsePalette(new Uint8Array(readFileSync(`${PALETTES_DIR}/${name}`)));
}

describe('parsePalette', () => {
	it("parses a synthetic file matching TScale.Save's exact CRLF/fixed-width format", () => {
		const text =
			'Reflectividad\r\n' +
			' 3 0\r\n' +
			'  85   0   0 117 \r\n' +
			'  90   0 236 236 d\xe9bil\r\n' +
			' 160 255 255 255 \r\n';
		// Encode char-by-char (not TextEncoder, which is UTF-8 and would turn 'é' into 2 bytes):
		// every char here is <= 0xFF, and JS string code units already equal Latin-1 byte values in
		// that range, so this reproduces a real ISO-8859-1-encoded file exactly.
		const bytes = Uint8Array.from(text, (c) => c.charCodeAt(0));

		const palette = parsePalette(bytes);
		expect(palette.name).toBe('Reflectividad');
		expect(palette.smooth).toBe(false);
		expect(palette.stops).toHaveLength(3);
		expect(palette.stops[0]).toEqual({ value: 85, color: [0, 0, 117], caption: '' });
		expect(palette.stops[1]).toEqual({ value: 90, color: [0, 236, 236], caption: 'débil' });
		expect(palette.stops[2]).toEqual({ value: 160, color: [255, 255, 255], caption: '' });
	});

	it('throws on a missing/malformed header line', () => {
		expect(() => parsePalette(new TextEncoder().encode('Name\r\nnot a header\r\n'))).toThrow(
			/size look/
		);
	});

	it('throws when a declared stop line is missing', () => {
		expect(() => parsePalette(new TextEncoder().encode('Name\r\n 2 0\r\n 1 0 0 0\r\n'))).toThrow(
			/stop line 1/
		);
	});

	it('parses every real palette shipped in legacy/Palettes/, preserving multi-word captions', () => {
		const files = readdirSync(PALETTES_DIR);
		expect(files.length).toBeGreaterThan(0);
		for (const file of files) {
			const palette = readPalette(file);
			expect(palette.name.length).toBeGreaterThan(0);
			expect(palette.stops.length).toBeGreaterThan(0);
			for (const stop of palette.stops) {
				expect(stop.color.every((c) => c >= 0 && c <= 255)).toBe(true);
			}
		}
	});

	it('matches the known DBZ.pal reflectivity scale exactly', () => {
		const palette = readPalette('DBZ.pal');
		expect(palette.name).toBe('Reflectividad');
		expect(palette.stops).toHaveLength(16);
		expect(palette.stops[0]).toEqual({ value: 85, color: [0, 0, 117], caption: '' });
		expect(palette.stops[1]).toEqual({ value: 90, color: [0, 236, 236], caption: 'débil' });
		expect(palette.stops.at(-1)).toEqual({ value: 160, color: [255, 255, 255], caption: '' });
	});

	it('preserves a multi-word caption ("medio alto") from KM.pal', () => {
		const palette = readPalette('KM.pal');
		expect(palette.name).toBe('Altura');
		const midHigh = palette.stops.find((s) => s.value === 122);
		expect(midHigh?.caption).toBe('medio alto');
	});

	it('decodes the accented palette name from MM.pal (Precipitación)', () => {
		const palette = readPalette('MM.pal');
		expect(palette.name).toBe('Precipitación');
	});
});
