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

// Sigmet/IRIS RAW: the file's first structure_header.structure_identifier (int16 LE) is always 27
// (PRODUCT_HDR) for this file class -- see src/lib/parsers/sigmet-iris/parse.ts.
export function isSigmetRawMagic(bytes: Uint8Array): boolean {
	if (bytes.length < 2) return false;
	return (bytes[0] | (bytes[1] << 8)) === 27;
}

// Classic NetCDF (NETCDF3_CLASSIC, "version 1"): magic "CDF" + a version byte. This app's
// netcdf3.ts reader only supports version 1 (32-bit offsets); other versions are still sniffed as
// a match here so the parser itself can throw a clear "unsupported version" error rather than
// registry.ts silently routing them to a different parser.
export function isNetcdf3Magic(bytes: Uint8Array): boolean {
	return (
		bytes.length >= 4 &&
		bytes[0] === 0x43 &&
		bytes[1] === 0x44 &&
		bytes[2] === 0x46 &&
		(bytes[3] === 1 || bytes[3] === 2 || bytes[3] === 5)
	);
}
