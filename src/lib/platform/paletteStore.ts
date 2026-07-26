import { isTauri } from '@tauri-apps/api/core';
import type { MomentType } from '$lib/domain/types';
import type { Palette } from '$lib/palette/types';
import { defaultPalettes, defaultAssignments } from '$lib/palette/defaults';

/**
 * The user's palette library plus the moment -> palette assignment, persisted in the browser.
 * Same web-only localStorage pattern as config.ts / siteData.ts -- see config.ts for the Tauri
 * caveat. Seeded from the built-in group (src/lib/palette/defaults.ts) with seed-fills-gaps
 * semantics: a palette the user already saved under a given name, and an assignment they already
 * chose for a given moment, both win over the seed, so re-seeding never clobbers hand edits.
 */

export interface PaletteBook {
	// The palette library, keyed by unique `name`.
	palettes: Palette[];
	// moment -> palette name. Values should reference a `name` present in `palettes`.
	assignments: Record<string, string>;
}

const STORAGE_KEY = 'lamula-process:palette-book';

/** Deep-ish clone so callers never mutate the shared built-in seed objects. */
function clonePalette(p: Palette): Palette {
	return { ...p, stops: p.stops.map((s) => ({ ...s, color: [...s.color] as [number, number, number] })) };
}

/** The default book (built-in palettes + default assignments), no persistence. */
export function seedPaletteBook(): PaletteBook {
	return {
		palettes: defaultPalettes.map(clonePalette),
		assignments: { ...defaultAssignments }
	};
}

/** Merge the built-in seed into a stored book: add missing palettes, fill missing assignments. */
function mergeSeed(stored: PaletteBook): PaletteBook {
	const byName = new Map(stored.palettes.map((p) => [p.name, p]));
	for (const p of defaultPalettes) {
		if (!byName.has(p.name)) byName.set(p.name, clonePalette(p));
	}
	return {
		palettes: [...byName.values()],
		// stored assignments win; seed only fills moments the user hasn't chosen yet.
		assignments: { ...defaultAssignments, ...stored.assignments }
	};
}

function isPaletteBook(x: unknown): x is PaletteBook {
	return (
		!!x &&
		typeof x === 'object' &&
		Array.isArray((x as PaletteBook).palettes) &&
		typeof (x as PaletteBook).assignments === 'object' &&
		(x as PaletteBook).assignments !== null
	);
}

export async function loadPaletteBook(): Promise<PaletteBook> {
	if (isTauri()) throw new Error('Tauri palette store not implemented yet');
	const raw = localStorage.getItem(STORAGE_KEY);
	if (!raw) {
		const seeded = seedPaletteBook();
		await savePaletteBook(seeded);
		return seeded;
	}
	let parsed: unknown;
	try {
		parsed = JSON.parse(raw);
	} catch {
		return seedPaletteBook();
	}
	const merged = mergeSeed(isPaletteBook(parsed) ? parsed : seedPaletteBook());
	await savePaletteBook(merged);
	return merged;
}

export async function savePaletteBook(book: PaletteBook): Promise<void> {
	if (isTauri()) throw new Error('Tauri palette store not implemented yet');
	localStorage.setItem(STORAGE_KEY, JSON.stringify(book));
}

/** The palette assigned to a moment, falling back to the first palette in the library. */
export function paletteForMoment(book: PaletteBook, moment: MomentType): Palette {
	const name = book.assignments[moment];
	return book.palettes.find((p) => p.name === name) ?? book.palettes[0];
}

/** Replace a palette by name (or append if new). Pure -- returns a new book. */
export function upsertPalette(book: PaletteBook, palette: Palette): PaletteBook {
	const idx = book.palettes.findIndex((p) => p.name === palette.name);
	const palettes =
		idx >= 0
			? book.palettes.map((p, i) => (i === idx ? palette : p))
			: [...book.palettes, palette];
	return { ...book, palettes };
}

/** Point a moment at a palette by name. Pure -- returns a new book. */
export function assignMomentPalette(
	book: PaletteBook,
	moment: MomentType,
	paletteName: string
): PaletteBook {
	return { ...book, assignments: { ...book.assignments, [moment]: paletteName } };
}

/** Serialize the whole book for a user-triggered download. */
export function exportPaletteBook(book: PaletteBook): string {
	return JSON.stringify(book, null, 2);
}

/** Merge an exported book blob into the stored one (imported entries win), then persist. */
export async function importPaletteBook(json: string): Promise<PaletteBook> {
	const incoming = JSON.parse(json);
	if (!isPaletteBook(incoming)) throw new Error('invalid palette-book JSON');
	const stored = await loadPaletteBook();
	const byName = new Map(stored.palettes.map((p) => [p.name, p]));
	for (const p of incoming.palettes) byName.set(p.name, p); // imported wins
	const merged: PaletteBook = {
		palettes: [...byName.values()],
		assignments: { ...stored.assignments, ...incoming.assignments }
	};
	await savePaletteBook(merged);
	return merged;
}
