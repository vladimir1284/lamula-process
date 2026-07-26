declare module 'bzip2-wasm' {
	export default class BZip2 {
		init(): Promise<void>;
		decompress(compressed: Uint8Array, decompressedLength?: number): Uint8Array;
		compress(decompressed: Uint8Array, blockSize?: number, compressedLength?: number): Uint8Array;
	}
}
