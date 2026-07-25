// Plain byte-by-byte decode instead of TextDecoder: every string this format needs (tape id, site
// ICAO, moment tags) is pure 7-bit ASCII, so there's no encoding-label ambiguity to worry about.
export function asciiString(bytes: Uint8Array): string {
	let s = '';
	for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
	return s;
}
