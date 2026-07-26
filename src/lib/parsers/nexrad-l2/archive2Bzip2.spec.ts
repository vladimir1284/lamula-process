import { describe, it, expect } from 'vitest';
import BZip2 from 'bzip2-wasm';
import { isArchive2Bzip2Compressed, inflateArchive2Bzip2 } from './archive2Bzip2';

function concat(...parts: Uint8Array[]): Uint8Array {
	const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
	let off = 0;
	for (const part of parts) {
		out.set(part, off);
		off += part.length;
	}
	return out;
}

function i32be(n: number): Uint8Array {
	const b = new Uint8Array(4);
	new DataView(b.buffer).setInt32(0, n);
	return b;
}

async function compress(bytes: Uint8Array): Promise<Uint8Array> {
	const bzip2 = new BZip2();
	await bzip2.init();
	return bzip2.compress(bytes);
}

describe('isArchive2Bzip2Compressed', () => {
	it('recognizes the record-length-prefixed BZh magic right after the 24-byte volume header', () => {
		const buf = concat(new Uint8Array(24), i32be(3), new TextEncoder().encode('BZh9...'));
		expect(isArchive2Bzip2Compressed(buf)).toBe(true);
	});

	it('rejects an uncompressed file (CTM zero-prefix right after the volume header)', () => {
		const buf = new Uint8Array(40);
		expect(isArchive2Bzip2Compressed(buf)).toBe(false);
	});

	it('rejects input too short to contain the magic', () => {
		expect(isArchive2Bzip2Compressed(new Uint8Array(20))).toBe(false);
	});
});

describe('inflateArchive2Bzip2', () => {
	it('decompresses length-prefixed bzip2 records and reassembles them after the volume header', async () => {
		const volumeHeader = new TextEncoder().encode('AR2V0006.882').slice(0, 12);
		const paddedHeader = concat(volumeHeader, new Uint8Array(12)); // pad to 24 bytes

		const record1Plain = new TextEncoder().encode('hello nexrad');
		const record2Plain = new TextEncoder().encode('second record payload');
		const record1Compressed = await compress(record1Plain);
		const record2Compressed = await compress(record2Plain);

		const buf = concat(
			paddedHeader,
			i32be(record1Compressed.length),
			record1Compressed,
			i32be(record2Compressed.length),
			record2Compressed
		);

		const out = await inflateArchive2Bzip2(buf);
		expect(out.subarray(0, 24)).toEqual(paddedHeader);
		expect(out.subarray(24, 24 + record1Plain.length)).toEqual(record1Plain);
		expect(
			out.subarray(24 + record1Plain.length, 24 + record1Plain.length + record2Plain.length)
		).toEqual(record2Plain);
	});

	it('treats a negative record-length sign (last-record flag) as a plain magnitude', async () => {
		const paddedHeader = new Uint8Array(24);
		const recordPlain = new TextEncoder().encode('final record');
		const recordCompressed = await compress(recordPlain);

		const buf = concat(paddedHeader, i32be(-recordCompressed.length), recordCompressed);

		const out = await inflateArchive2Bzip2(buf);
		expect(out.subarray(24)).toEqual(recordPlain);
	});

	it('decompresses a record larger than a single 900k bzip2 block correctly', async () => {
		// Regression guard: the `bzip2` npm package (antimatter15's pure-JS decoder) silently
		// truncates any record whose real decompressed size exceeds 900,000 bytes -- confirmed
		// against real KBYX radial records, which routinely exceed that. bzip2-wasm (real
		// libbzip2 compiled to wasm) must not have the same defect.
		const bigPlain = new Uint8Array(1_200_000);
		for (let i = 0; i < bigPlain.length; i++) bigPlain[i] = i % 251;
		const bigCompressed = await compress(bigPlain);

		const paddedHeader = new Uint8Array(24);
		const buf = concat(paddedHeader, i32be(bigCompressed.length), bigCompressed);

		const out = await inflateArchive2Bzip2(buf);
		expect(out.length).toBe(24 + bigPlain.length);
		expect(out.subarray(24)).toEqual(bigPlain);
	}, 15_000);
});
