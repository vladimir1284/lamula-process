import { cellFlagCode } from '$lib/domain';
import { asciiString } from './ascii';

// Data Header Block, 68 bytes immediately after the 16-byte message header. Byte offsets are
// fixed per the ICD, but which MOMENT sits at a given pointer slot is NOT reliable (dual-pol
// surveillance-only cuts fill the "VEL pointer" slot with a ZDR block, etc) -- every block must be
// identified by its own 4-byte tag, never by which pointer field pointed to it. See
// docs/formatos.md and test-fixtures/reference/nexrad-l2/l2_probe_py3.py.
export interface DataHeaderBlock {
	azimuthNumber: number;
	azimuthAngleDeg: number;
	elevationNumber: number;
	elevationAngleDeg: number;
	// tag (e.g. "DREF", "DVEL") -> absolute byte offset of that block
	blocks: Map<string, number>;
}

export function parseDataHeaderBlock(buf: Uint8Array, msgHeaderOff: number): DataHeaderBlock {
	const dhbOff = msgHeaderOff + 16;
	const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);

	const azimuthNumber = view.getUint16(dhbOff + 10);
	const azimuthAngleDeg = view.getFloat32(dhbOff + 12);
	const elevationNumber = view.getUint8(dhbOff + 22);
	const elevationAngleDeg = view.getFloat32(dhbOff + 24);
	const dataBlockCount = view.getUint16(dhbOff + 30);

	const blocks = new Map<string, number>();
	for (let i = 0; i < dataBlockCount; i++) {
		const pointer = view.getUint32(dhbOff + 32 + i * 4);
		if (pointer === 0) continue;
		const blockOff = dhbOff + pointer;
		blocks.set(asciiString(buf.subarray(blockOff, blockOff + 4)).trim(), blockOff);
	}

	return { azimuthNumber, azimuthAngleDeg, elevationNumber, elevationAngleDeg, blocks };
}

export interface MomentBlock {
	numGates: number;
	// Both read directly as meters (standard convention in public NEXRAD L2 decoders); not
	// independently re-derived against the ICD text in this project, unlike the physical-value
	// formula below which docs/formatos.md confirms against real gate values.
	rangeToFirstGateM: number;
	gateLengthM: number;
	values: Float32Array;
	flags: Uint8Array;
}

// Unlike Rainbow5 (single ambiguous raw=0 "no-data/below-threshold" sentinel), the ICD gives
// NEXRAD L2 two distinct, unambiguous codes -- use the more specific domain flag for each.
const BELOW_THRESHOLD = cellFlagCode('below-threshold');
const RANGE_FOLDED = cellFlagCode('range-folded');

// Generic Data Moment block, 28-byte header + N gates. Physical value = (raw-offset)/scale for
// raw>=2; raw=0 is below-threshold, raw=1 is range-folded -- confirmed against real KMLB bytes,
// see docs/formatos.md.
export function decodeMomentBlock(buf: Uint8Array, blockOff: number): MomentBlock {
	const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);

	const numGates = view.getUint16(blockOff + 8);
	const rangeToFirstGateM = view.getUint16(blockOff + 10);
	const gateLengthM = view.getUint16(blockOff + 12);
	const dataWordSize = view.getUint8(blockOff + 19);
	const scale = view.getFloat32(blockOff + 20);
	const offset = view.getFloat32(blockOff + 24);

	const gateDataOff = blockOff + 28;
	const values = new Float32Array(numGates);
	const flags = new Uint8Array(numGates);

	if (dataWordSize === 8) {
		for (let i = 0; i < numGates; i++) {
			const raw = buf[gateDataOff + i];
			if (raw === 0) flags[i] = BELOW_THRESHOLD;
			else if (raw === 1) flags[i] = RANGE_FOLDED;
			else values[i] = (raw - offset) / scale;
		}
	} else if (dataWordSize === 16) {
		for (let i = 0; i < numGates; i++) {
			const raw = view.getUint16(gateDataOff + i * 2);
			if (raw === 0) flags[i] = BELOW_THRESHOLD;
			else if (raw === 1) flags[i] = RANGE_FOLDED;
			else values[i] = (raw - offset) / scale;
		}
	} else {
		throw new Error(`unexpected data word size ${dataWordSize} at offset ${blockOff}`);
	}

	return { numGates, rangeToFirstGateM, gateLengthM, values, flags };
}
