import type { Palette, PaletteStop } from './types';

/**
 * Immutable editing helpers for the color-scale editor. The lookup (`paletteIndex`) assumes
 * stops are sorted ascending by threshold value, so every mutation re-sorts to preserve that
 * invariant.
 */

export function sortStops(palette: Palette): Palette {
	return { ...palette, stops: [...palette.stops].sort((a, b) => a.value - b.value) };
}

export function addStop(palette: Palette, stop: PaletteStop): Palette {
	return sortStops({ ...palette, stops: [...palette.stops, stop] });
}

export function removeStop(palette: Palette, index: number): Palette {
	if (index < 0 || index >= palette.stops.length) return palette;
	const stops = palette.stops.filter((_, i) => i !== index);
	return { ...palette, stops };
}

export function updateStop(palette: Palette, index: number, patch: Partial<PaletteStop>): Palette {
	if (index < 0 || index >= palette.stops.length) return palette;
	const stops = palette.stops.map((s, i) => (i === index ? { ...s, ...patch } : s));
	// re-sort in case the threshold changed
	return sortStops({ ...palette, stops });
}

export function renamePalette(palette: Palette, name: string): Palette {
	return { ...palette, name };
}
