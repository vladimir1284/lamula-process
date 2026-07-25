import type { Palette } from './types';

// Direct port of TScale.GetIndex (legacy/Units/Scale.pas): step lookup, not interpolation --
// advance past every stop whose own threshold is still below `value`, clamped at the last stop.
export function paletteIndex(palette: Palette, value: number): number {
	let i = 0;
	while (i < palette.stops.length - 1 && value > palette.stops[i].value) i++;
	return i;
}

// Direct port of TScale.GetValueColor.
export function colorForValue(palette: Palette, value: number): readonly [number, number, number] {
	if (palette.stops.length === 0) throw new Error('palette has no stops');
	return palette.stops[paletteIndex(palette, value)].color;
}
