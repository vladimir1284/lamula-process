import { describe, it, expect } from 'vitest';
import { deflateSync } from 'node:zlib';
import { splitHeader, readBlobs } from './blobs';

function u32be(n: number): Uint8Array {
	const bytes = new Uint8Array(4);
	new DataView(bytes.buffer).setUint32(0, n);
	return bytes;
}

function concat(...parts: Uint8Array[]): Uint8Array {
	const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
	let off = 0;
	for (const part of parts) {
		out.set(part, off);
		off += part.length;
	}
	return out;
}

const ascii = (s: string) => new TextEncoder().encode(s);

describe('splitHeader', () => {
	it('splits header xml from the blob section, consuming one trailing newline', () => {
		const text = '<volume/>\n<!-- END XML -->\n<BLOB .../>';
		const { headerXml, blobsStart } = splitHeader(text);
		expect(headerXml).toBe('<volume/>\n');
		expect(text.slice(blobsStart)).toBe('<BLOB .../>');
	});

	it('throws when the end-of-xml marker is missing', () => {
		expect(() => splitHeader('no marker here')).toThrow(/missing/);
	});
});

describe('readBlobs', () => {
	it('decompresses a qt-compressed blob and passes through an uncompressed one', async () => {
		const payloadA = ascii('hello rainbow5');
		const compressedA = deflateSync(payloadA);
		const blobA = concat(
			ascii(`<BLOB blobid="0" size="${4 + compressedA.length}" compression="qt">\n`),
			u32be(payloadA.length),
			compressedA,
			ascii('\n</BLOB>\n')
		);
		const payloadB = ascii('raw bytes, no compression');
		const blobB = concat(
			ascii(`<BLOB blobid="1" size="${payloadB.length}" compression="">\n`),
			payloadB,
			ascii('\n</BLOB>')
		);
		const bytes = concat(blobA, blobB);
		const text = new TextDecoder('latin1').decode(bytes);

		const blobs = await readBlobs(bytes, text, 0);
		expect(new TextDecoder().decode(blobs.get(0))).toBe('hello rainbow5');
		expect(new TextDecoder().decode(blobs.get(1))).toBe('raw bytes, no compression');
	});

	it('throws when the decompressed size does not match the declared uncompressed size', async () => {
		const compressed = deflateSync(ascii('hello'));
		const blob = concat(
			ascii(`<BLOB blobid="0" size="${4 + compressed.length}" compression="qt">\n`),
			u32be(999),
			compressed,
			ascii('\n</BLOB>')
		);
		const text = new TextDecoder('latin1').decode(blob);
		await expect(readBlobs(blob, text, 0)).rejects.toThrow(/uncompressed size mismatch/);
	});

	it('throws on an unhandled compression value', async () => {
		const blob = concat(
			ascii('<BLOB blobid="0" size="3" compression="bz2">\n'),
			ascii('abc\n</BLOB>')
		);
		const text = new TextDecoder('latin1').decode(blob);
		await expect(readBlobs(blob, text, 0)).rejects.toThrow(/unhandled compression/);
	});

	it('throws when the closing tag bytes are wrong', async () => {
		const blob = concat(ascii('<BLOB blobid="0" size="3" compression="">\n'), ascii('abcXXXXXXXX'));
		const text = new TextDecoder('latin1').decode(blob);
		await expect(readBlobs(blob, text, 0)).rejects.toThrow(/expected closing/);
	});
});
