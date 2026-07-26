import BZip2 from 'bzip2-wasm';

// Real-time Archive II files (e.g. everything pulled from the NOAA/AWS public bucket) are LDM-
// compressed: the 24-byte Volume Header Record is followed by a sequence of records, each a
// 4-byte big-endian byte count (sign may be set on the final record; magnitude is what matters)
// followed by exactly that many bytes of a self-contained bzip2 stream ("BZh..."). Decompressing
// and concatenating every record's payload reconstructs the exact same message stream that an
// uncompressed file would have at this offset -- confirmed against real KBYX bytes (record 1
// decodes to a run of legacy metadata messages, record 2+ decode to message-31 radials, both with
// the expected 12-byte-zero CTM prefix immediately at the start of the decompressed output). Every
// downstream parser (messages.ts/message31.ts) is unchanged: this module only reconstitutes the
// logical uncompressed byte stream.
const VOLUME_HEADER_SIZE = 24;
const RECORD_LENGTH_FIELD_SIZE = 4;

// The 4 bytes right after the volume header are a record-length count, not message bytes, so the
// "BZh" magic sits one field further in than the file start.
export function isArchive2Bzip2Compressed(buf: Uint8Array): boolean {
	const off = VOLUME_HEADER_SIZE + RECORD_LENGTH_FIELD_SIZE;
	return (
		buf.length > off + 3 && buf[off] === 0x42 && buf[off + 1] === 0x5a && buf[off + 2] === 0x68 // "BZh"
	);
}

let bzip2Instance: Promise<BZip2> | null = null;
function getBzip2(): Promise<BZip2> {
	if (!bzip2Instance) {
		bzip2Instance = (async () => {
			const instance = new BZip2();
			await instance.init();
			return instance;
		})();
	}
	return bzip2Instance;
}

// A record's decompressed size isn't declared anywhere in the file; the wasm binding needs an
// upper-bound buffer size upfront (BZ2_bzBuffToBuffDecompress, no streaming). Real NEXRAD radial
// data compresses at roughly 3-6x, so start generous and grow on BZ_OUTBUFF_FULL rather than
// guess a single fixed ratio that could be wrong for an unusually dense record.
async function decompressRecord(bzip2: BZip2, chunk: Uint8Array): Promise<Uint8Array> {
	let guess = Math.max(chunk.length * 16, 1 << 20);
	const maxGuess = 1 << 27; // 128 MiB hard stop -- real records here top out under 1.5 MB
	for (;;) {
		try {
			return bzip2.decompress(chunk, guess);
		} catch (err) {
			const isBufferTooSmall = err instanceof Error && /OUTBUFF_FULL/.test(err.message);
			if (!isBufferTooSmall || guess >= maxGuess) throw err;
			guess *= 2;
		}
	}
}

export async function inflateArchive2Bzip2(buf: Uint8Array): Promise<Uint8Array> {
	const bzip2 = await getBzip2();
	const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
	const decompressedRecords: Uint8Array[] = [];
	let off = VOLUME_HEADER_SIZE;

	while (off + RECORD_LENGTH_FIELD_SIZE <= buf.length) {
		const recordLength = Math.abs(view.getInt32(off));
		off += RECORD_LENGTH_FIELD_SIZE;
		if (recordLength === 0 || off + recordLength > buf.length) break;

		const chunk = buf.subarray(off, off + recordLength);
		decompressedRecords.push(await decompressRecord(bzip2, chunk));
		off += recordLength;
	}

	const volumeHeader = buf.subarray(0, VOLUME_HEADER_SIZE);
	const totalSize = VOLUME_HEADER_SIZE + decompressedRecords.reduce((sum, r) => sum + r.length, 0);
	const out = new Uint8Array(totalSize);
	out.set(volumeHeader, 0);
	let writeOff = VOLUME_HEADER_SIZE;
	for (const record of decompressedRecords) {
		out.set(record, writeOff);
		writeOff += record.length;
	}
	return out;
}
