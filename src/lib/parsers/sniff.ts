export function hasExtension(fileName: string, ...extensions: string[]): boolean {
	const lower = fileName.toLowerCase();
	return extensions.some((ext) => lower.endsWith(ext.toLowerCase()));
}

export function startsWithAscii(bytes: Uint8Array, ascii: string): boolean {
	if (bytes.length < ascii.length) return false;
	for (let i = 0; i < ascii.length; i++) {
		if (bytes[i] !== ascii.charCodeAt(i)) return false;
	}
	return true;
}

// gzip magic per RFC 1952 (ID1=0x1f, ID2=0x8b); NEXRAD L2 archives ship gzip-wrapped.
export function isGzipMagic(bytes: Uint8Array): boolean {
	return bytes.length >= 2 && bytes[0] === 0x1f && bytes[1] === 0x8b;
}
