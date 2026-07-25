export async function inflateGzip(bytes: Uint8Array): Promise<Uint8Array> {
	// Copy into a fresh ArrayBuffer-backed array, same reasoning as rainbow5/blobs.ts: `bytes` may
	// be a view whose .buffer type isn't assignable to BlobPart.
	const stream = new Blob([new Uint8Array(bytes)])
		.stream()
		.pipeThrough(new DecompressionStream('gzip'));
	return new Uint8Array(await new Response(stream).arrayBuffer());
}
