import { describe, it, expect } from 'vitest';
import { cellFlagCode } from '$lib/domain';
import { parseDataHeaderBlock, decodeMomentBlock } from './message31';

function u16be(n: number): Uint8Array {
	const b = new Uint8Array(2);
	new DataView(b.buffer).setUint16(0, n);
	return b;
}
function u32be(n: number): Uint8Array {
	const b = new Uint8Array(4);
	new DataView(b.buffer).setUint32(0, n);
	return b;
}
function i16be(n: number): Uint8Array {
	const b = new Uint8Array(2);
	new DataView(b.buffer).setInt16(0, n);
	return b;
}
function f32be(n: number): Uint8Array {
	const b = new Uint8Array(4);
	new DataView(b.buffer).setFloat32(0, n);
	return b;
}
function ascii(s: string): Uint8Array {
	return new TextEncoder().encode(s);
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

// The Data Header Block always has 9 fixed pointer slots physically present (36 bytes), even
// though data_block_count says how many are meaningfully populated -- pad with zero pointers so
// the synthetic block matches the real 68-byte layout.
function pointerSlots(...values: number[]): Uint8Array {
	const nine = [...values, ...Array(9 - values.length).fill(0)];
	return concat(...nine.map(u32be));
}

const MOMENT_HEADER = concat(
	ascii('DREF'),
	u32be(0), // reserved
	u16be(4), // number_of_gates
	u16be(250), // data_moment_range
	u16be(250), // range_sample_interval
	u16be(0), // tover
	i16be(0), // snr_threshold
	new Uint8Array([0, 8]), // control_flags, data_word_size=8
	f32be(2.0), // scale
	f32be(66.0) // offset
);

// parseDataHeaderBlock takes the *message header's* offset and reads the DHB 16 bytes past it
// (the real message-31 layout: 16-byte message header, then the 68-byte DHB) -- pad a dummy
// message header in front so pointer arithmetic in these synthetic buffers matches real usage.
const DUMMY_MSG_HEADER = new Uint8Array(16);

describe('parseDataHeaderBlock', () => {
	it('reads azimuth/elevation metadata and resolves block pointers by their own tag', () => {
		const dhb = concat(
			ascii('KMLB'), // radar_id
			u32be(0), // collection_time_ms
			u16be(0), // mjd
			u16be(1), // azimuth_number
			f32be(10.5), // azimuth_angle
			new Uint8Array([0, 0]), // compression_indicator, spare
			u16be(0), // radial_length
			new Uint8Array([0, 0]), // az_resolution_spacing, radial_status
			new Uint8Array([2, 0]), // elevation_number=2, cut_sector_number=0
			f32be(1.45), // elevation_angle
			new Uint8Array([0, 0]), // spot_blanking_status, azimuth_indexing_mode
			u16be(1), // data_block_count
			pointerSlots(68) // pointer[0] -> dhbOff + 68 (right after this 68-byte block)
		);
		const gates = new Uint8Array([0, 1, 70, 255]);
		const buf = concat(DUMMY_MSG_HEADER, dhb, MOMENT_HEADER, gates);

		const parsed = parseDataHeaderBlock(buf, 0);
		expect(parsed.azimuthNumber).toBe(1);
		expect(parsed.azimuthAngleDeg).toBeCloseTo(10.5);
		expect(parsed.elevationNumber).toBe(2);
		expect(parsed.elevationAngleDeg).toBeCloseTo(1.45);
		expect(Array.from(parsed.blocks.entries())).toEqual([['DREF', 16 + 68]]);
	});

	it('skips zero pointers', () => {
		const dhb = concat(
			ascii('KMLB'),
			u32be(0),
			u16be(0),
			u16be(1),
			f32be(0),
			new Uint8Array([0, 0]),
			u16be(0),
			new Uint8Array([0, 0]),
			new Uint8Array([1, 0]),
			f32be(0.5),
			new Uint8Array([0, 0]),
			u16be(2), // data_block_count=2, but only pointer[0] is non-zero
			pointerSlots(68, 0)
		);
		const buf = concat(DUMMY_MSG_HEADER, dhb, MOMENT_HEADER, new Uint8Array([0, 1, 70, 255]));
		const parsed = parseDataHeaderBlock(buf, 0);
		expect(Array.from(parsed.blocks.keys())).toEqual(['DREF']);
	});
});

describe('decodeMomentBlock', () => {
	it('decodes 8-bit gates: (raw-offset)/scale, raw=0 below-threshold, raw=1 range-folded', () => {
		const buf = concat(MOMENT_HEADER, new Uint8Array([0, 1, 70, 255]));
		const moment = decodeMomentBlock(buf, 0);

		expect(moment.numGates).toBe(4);
		expect(moment.rangeToFirstGateM).toBe(250);
		expect(moment.gateLengthM).toBe(250);
		expect(Array.from(moment.flags)).toEqual([
			cellFlagCode('below-threshold'),
			cellFlagCode('range-folded'),
			cellFlagCode('ok'),
			cellFlagCode('ok')
		]);
		expect(moment.values[2]).toBeCloseTo(2.0);
		expect(moment.values[3]).toBeCloseTo(94.5);
	});

	it('decodes 16-bit gates the same way', () => {
		const header = concat(
			ascii('DPHI'),
			u32be(0),
			u16be(2),
			u16be(0),
			u16be(0),
			u16be(0),
			i16be(0),
			new Uint8Array([0, 16]),
			f32be(1.0),
			f32be(0.0)
		);
		const gates = concat(u16be(0), u16be(500));
		const moment = decodeMomentBlock(concat(header, gates), 0);

		expect(moment.flags[0]).toBe(cellFlagCode('below-threshold'));
		expect(moment.values[1]).toBeCloseTo(500);
	});

	it('throws on an unexpected data word size', () => {
		const header = concat(
			ascii('DREF'),
			u32be(0),
			u16be(1),
			u16be(0),
			u16be(0),
			u16be(0),
			i16be(0),
			new Uint8Array([0, 6]),
			f32be(1.0),
			f32be(0.0)
		);
		expect(() => decodeMomentBlock(concat(header, new Uint8Array([0])), 0)).toThrow(
			/unexpected data word size/
		);
	});
});
