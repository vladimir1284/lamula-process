import type { Palette, PaletteStop } from './types';

// Direct port of TScale.Load (legacy/Units/Scale.pas): line 1 = name, line 2 = "size look", then
// `size` lines of "value R G B [caption]". `look` isn't consulted by GetValueColor in the
// original either -- see Palette.smooth in types.ts.
const STOP_LINE_RE = /^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*(.*)$/;

export function parsePalette(bytes: Uint8Array): Palette {
	// Real files are ISO-8859-1 (confirmed: `file` on legacy/Palettes/*.pal, and captions like
	// "d\xE9bil"/"Precipitaci\xF3n" only render correctly under that decoding, not UTF-8).
	const text = new TextDecoder('latin1').decode(bytes);
	const lines = text.split(/\r?\n/);

	const name = lines[0];
	if (name === undefined) throw new Error('palette file has no name line');

	const headerMatch = /^\s*(\d+)\s+(\d+)\s*$/.exec(lines[1] ?? '');
	if (!headerMatch) throw new Error(`palette file has no valid "size look" header line`);
	const size = Number(headerMatch[1]);
	const smooth = Number(headerMatch[2]) !== 0;

	const stops: PaletteStop[] = [];
	for (let i = 0; i < size; i++) {
		const line = lines[2 + i];
		const stopMatch = line !== undefined ? STOP_LINE_RE.exec(line) : null;
		if (!stopMatch) throw new Error(`palette stop line ${i} is missing or malformed: ${line}`);
		const [, value, r, g, b, caption] = stopMatch;
		stops.push({
			value: Number(value),
			color: [Number(r), Number(g), Number(b)],
			caption: caption.trim()
		});
	}

	return { name, smooth, stops };
}
