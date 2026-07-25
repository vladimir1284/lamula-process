// Blob container framing, see docs/formatos.md#formato-1--rainbow-50-gematronikleonardo-selex.
// `text` must be the whole file latin-1 decoded (1 byte <-> 1 code unit, so string offsets and
// byte offsets coincide exactly) -- that lets us regex-match the ASCII tag lines while still
// slicing the arbitrary binary payload out of the original `bytes` array.
const END_XML_MARKER = '<!-- END XML -->';
const BLOB_TAG_RE = /^<BLOB blobid="(\d+)" size="(\d+)" compression="(\w*)">\n/;
const BLOB_CLOSE = '\n</BLOB>';

export function splitHeader(text: string): { headerXml: string; blobsStart: number } {
	const marker = text.indexOf(END_XML_MARKER);
	if (marker === -1) throw new Error('missing "<!-- END XML -->" marker');
	const headerXml = text.slice(0, marker);
	let blobsStart = marker + END_XML_MARKER.length;
	if (text[blobsStart] === '\n') blobsStart += 1;
	return { headerXml, blobsStart };
}

async function inflateZlib(bytes: Uint8Array): Promise<Uint8Array> {
	// Copy into a fresh ArrayBuffer-backed array: `bytes` is a subarray view whose .buffer type
	// (ArrayBufferLike) isn't assignable to BlobPart, which requires a plain ArrayBuffer.
	const stream = new Blob([new Uint8Array(bytes)])
		.stream()
		.pipeThrough(new DecompressionStream('deflate'));
	return new Uint8Array(await new Response(stream).arrayBuffer());
}

// Sequentially walks every <BLOB blobid=.. size=.. compression=..>...</BLOB> block from `start`
// to EOF. blobid is a single counter across the WHOLE file (not reset per slice), so the result
// is keyed by that absolute id rather than by read order.
export async function readBlobs(
	bytes: Uint8Array,
	text: string,
	start: number
): Promise<Map<number, Uint8Array>> {
	const blobs = new Map<number, Uint8Array>();
	let off = start;

	while (off < text.length) {
		const tagMatch = BLOB_TAG_RE.exec(text.slice(off, off + 200));
		if (!tagMatch) break;

		const blobId = Number(tagMatch[1]);
		const size = Number(tagMatch[2]);
		const compression = tagMatch[3];
		const payloadOff = off + tagMatch[0].length;
		const payload = bytes.subarray(payloadOff, payloadOff + size);

		const closing = text.slice(payloadOff + size, payloadOff + size + BLOB_CLOSE.length);
		if (closing !== BLOB_CLOSE) {
			throw new Error(
				`blob ${blobId}: expected closing ${JSON.stringify(BLOB_CLOSE)}, got ${JSON.stringify(closing)}`
			);
		}

		let data: Uint8Array;
		if (compression === 'qt') {
			const view = new DataView(payload.buffer, payload.byteOffset, payload.byteLength);
			const uncompressedSize = view.getUint32(0);
			data = await inflateZlib(payload.subarray(4));
			if (data.length !== uncompressedSize) {
				throw new Error(
					`blob ${blobId}: uncompressed size mismatch, expected ${uncompressedSize}, got ${data.length}`
				);
			}
		} else if (compression === '' || compression === 'none') {
			data = payload;
		} else {
			throw new Error(`blob ${blobId}: unhandled compression "${compression}"`);
		}

		blobs.set(blobId, data);
		off = payloadOff + size + BLOB_CLOSE.length;
		if (text[off] === '\n') off += 1;
	}

	return blobs;
}
