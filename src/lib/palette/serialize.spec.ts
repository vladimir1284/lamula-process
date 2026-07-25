import { describe, it, expect } from 'vitest';
import type { Palette } from './types';
import { serializePalette, serializePaletteText } from './serialize';
import { parsePalette } from './parse';

const sample: Palette = {
	name: 'Reflectividad',
	smooth: false,
	stops: [
		{ value: 0, color: [0, 0, 0], caption: 'nada' },
		{ value: 20, color: [0, 128, 255], caption: 'débil' }, // é = 0xE9 in latin1
		{ value: 40, color: [255, 255, 0], caption: 'medio alto' },
		{ value: 60, color: [255, 0, 0], caption: '' }
	]
};

describe('serializePalette', () => {
	it('emits the legacy header and CRLF line endings', () => {
		const text = serializePaletteText(sample);
		const lines = text.split('\r\n');
		expect(lines[0]).toBe('Reflectividad');
		expect(lines[1]).toBe('4 0'); // size look
		expect(lines[2]).toBe('0 0 0 0 nada');
		expect(lines[4]).toBe('40 255 255 0 medio alto'); // multi-word caption preserved
		expect(text.endsWith('\r\n')).toBe(true);
		expect(text.includes('\r\n')).toBe(true);
	});

	it('encodes captions as latin1 (é -> 0xE9)', () => {
		const bytes = serializePalette(sample);
		expect(Array.from(bytes)).toContain(0xe9);
	});

	it('round-trips through parsePalette', () => {
		const reparsed = parsePalette(serializePalette(sample));
		expect(reparsed.name).toBe(sample.name);
		expect(reparsed.smooth).toBe(sample.smooth);
		expect(reparsed.stops).toEqual(sample.stops);
	});
});
