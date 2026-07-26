// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { isTauri } from '@tauri-apps/api/core';

vi.mock('@tauri-apps/api/core', () => ({ isTauri: vi.fn(() => false) }));

import {
	seedPaletteBook,
	loadPaletteBook,
	savePaletteBook,
	paletteForMoment,
	upsertPalette,
	assignMomentPalette,
	exportPaletteBook,
	importPaletteBook
} from './paletteStore';
import { defaultPalettes, defaultAssignments } from '$lib/palette/defaults';
import type { Palette } from '$lib/palette/types';

beforeEach(() => {
	localStorage.clear();
	vi.mocked(isTauri).mockReturnValue(false);
});

describe('seedPaletteBook', () => {
	it('includes one built-in palette per default and clones them (no shared refs)', () => {
		const book = seedPaletteBook();
		expect(book.palettes).toHaveLength(defaultPalettes.length);
		expect(book.palettes[0]).not.toBe(defaultPalettes[0]);
		expect(book.palettes[0].stops[0]).not.toBe(defaultPalettes[0].stops[0]);
	});

	it('assigns every moment to a palette that exists in the library', () => {
		const book = seedPaletteBook();
		const names = new Set(book.palettes.map((p) => p.name));
		for (const target of Object.values(defaultAssignments)) {
			expect(names.has(target)).toBe(true);
		}
	});
});

describe('paletteForMoment', () => {
	it('returns the assigned palette, dBZ and dBuZ sharing reflectivity', () => {
		const book = seedPaletteBook();
		expect(paletteForMoment(book, 'dBZ').name).toBe('Reflectividad');
		expect(paletteForMoment(book, 'dBuZ').name).toBe('Reflectividad');
		expect(paletteForMoment(book, 'V').name).toBe('Velocidad radial');
	});

	it('falls back to the first palette when the assignment is dangling', () => {
		const book = { ...seedPaletteBook(), assignments: { dBZ: 'does-not-exist' } };
		expect(paletteForMoment(book, 'dBZ')).toBe(book.palettes[0]);
	});
});

describe('upsertPalette', () => {
	it('replaces in place by name', () => {
		const book = seedPaletteBook();
		const edited: Palette = { ...paletteForMoment(book, 'V'), smooth: true };
		const next = upsertPalette(book, edited);
		expect(next.palettes).toHaveLength(book.palettes.length);
		expect(next.palettes.find((p) => p.name === 'Velocidad radial')?.smooth).toBe(true);
	});

	it('appends when the name is new', () => {
		const book = seedPaletteBook();
		const next = upsertPalette(book, { name: 'Custom', smooth: false, stops: [] });
		expect(next.palettes).toHaveLength(book.palettes.length + 1);
	});
});

describe('assignMomentPalette', () => {
	it('repoints a moment without touching others', () => {
		const book = seedPaletteBook();
		const next = assignMomentPalette(book, 'dBZ', 'ZDR');
		expect(next.assignments.dBZ).toBe('ZDR');
		expect(next.assignments.V).toBe(book.assignments.V);
	});
});

describe('load/save + seed-fills-gaps', () => {
	it('seeds and persists on first load', async () => {
		const book = await loadPaletteBook();
		expect(book.palettes.length).toBe(defaultPalettes.length);
		expect(localStorage.getItem('lamula-process:palette-book')).not.toBeNull();
	});

	it('keeps user edits but fills missing built-ins and assignments', async () => {
		// Store a book with only one (edited) palette and one assignment.
		const editedRefl: Palette = {
			name: 'Reflectividad',
			smooth: true,
			stops: [{ value: 0, color: [1, 2, 3], caption: 'x' }]
		};
		await savePaletteBook({ palettes: [editedRefl], assignments: { V: 'Reflectividad' } });

		const book = await loadPaletteBook();
		// user's edited Reflectividad wins over the seed
		expect(book.palettes.find((p) => p.name === 'Reflectividad')?.smooth).toBe(true);
		// missing built-ins are added back
		expect(book.palettes.find((p) => p.name === 'ZDR')).toBeDefined();
		// user's assignment wins, gaps filled from defaults
		expect(book.assignments.V).toBe('Reflectividad');
		expect(book.assignments.dBZ).toBe('Reflectividad');
		expect(book.assignments.RhoHV).toBe('RhoHV');
	});

	it('recovers from corrupt storage by returning the seed', async () => {
		localStorage.setItem('lamula-process:palette-book', '{not json');
		const book = await loadPaletteBook();
		expect(book.palettes.length).toBe(defaultPalettes.length);
	});
});

describe('export/import round-trip', () => {
	it('imported palettes and assignments win over stored', async () => {
		await loadPaletteBook(); // seed
		const blob = exportPaletteBook({
			palettes: [{ name: 'Reflectividad', smooth: true, stops: [] }],
			assignments: { dBZ: 'ZDR' }
		});
		const merged = await importPaletteBook(blob);
		expect(merged.palettes.find((p) => p.name === 'Reflectividad')?.smooth).toBe(true);
		expect(merged.assignments.dBZ).toBe('ZDR');
		// untouched built-ins survive
		expect(merged.palettes.find((p) => p.name === 'PhiDP')).toBeDefined();
	});

	it('rejects invalid JSON shape', async () => {
		await expect(importPaletteBook('[]')).rejects.toThrow(/invalid palette-book JSON/);
	});
});

describe('on Tauri (not implemented yet)', () => {
	it('load/save both throw', async () => {
		vi.mocked(isTauri).mockReturnValue(true);
		await expect(loadPaletteBook()).rejects.toThrow(/not implemented yet/);
		await expect(savePaletteBook(seedPaletteBook())).rejects.toThrow(/not implemented yet/);
	});
});
