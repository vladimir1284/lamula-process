import type { Palette } from './types';

/**
 * Inverse of parsePalette: serialize a Palette back to the legacy `.pal` byte format
 * (`legacy/Units/Scale.pas` TScale.Load layout): line 1 name, line 2 "size look", then one
 * "value R G B caption" line per stop. CRLF line endings and ISO-8859-1 (latin1) encoding, to
 * match the real files (see parse.ts). Stop values are integers (the format's `\d+`), so they
 * are rounded on the way out.
 */

function encodeLatin1(text: string): Uint8Array {
	const out = new Uint8Array(text.length);
	for (let i = 0; i < text.length; i++) {
		const code = text.charCodeAt(i);
		// latin1 is 1 byte/char; anything above 0xFF can't be represented, fall back to '?'.
		out[i] = code <= 0xff ? code : 0x3f;
	}
	return out;
}

export function serializePaletteText(palette: Palette): string {
	const lines: string[] = [palette.name, `${palette.stops.length} ${palette.smooth ? 1 : 0}`];
	for (const s of palette.stops) {
		const v = Math.round(s.value);
		const r = Math.round(s.color[0]);
		const g = Math.round(s.color[1]);
		const b = Math.round(s.color[2]);
		const caption = s.caption ? ` ${s.caption}` : '';
		lines.push(`${v} ${r} ${g} ${b}${caption}`);
	}
	// trailing CRLF matches the real files (TScale.Load reads line-by-line, tolerant either way).
	return lines.join('\r\n') + '\r\n';
}

export function serializePalette(palette: Palette): Uint8Array {
	return encodeLatin1(serializePaletteText(palette));
}
