import { describe, it, expect } from 'vitest';
import { parseVolumeHeader, walkMessages } from './messages';

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

describe('parseVolumeHeader', () => {
	it('reads tape id, julian date, ms of day, and site ICAO from the 24-byte header', () => {
		const buf = concat(ascii('AR2V0006.157'), u32be(15640), u32be(43934000), ascii('KMLB'));
		expect(parseVolumeHeader(buf)).toEqual({
			tapeId: 'AR2V0006.157',
			julianDate: 15640,
			msOfDay: 43934000,
			site: 'KMLB'
		});
	});
});

describe('walkMessages', () => {
	it('advances a fixed 2432-byte frame for non-31 types, and size*2 for type 31', () => {
		const volumeHeader = new Uint8Array(24);

		const frame1 = concat(
			new Uint8Array(12), // CTM prefix
			u16be(100), // message_size (irrelevant for non-31 framing)
			new Uint8Array([0, 2]), // redundant_channel, message_type=2
			new Uint8Array(12) // id_seq(2) + julian_date(2) + ms(4) + n_segments(2) + segment(2)
		);
		const frame1Padded = concat(frame1, new Uint8Array(2432 - frame1.length));

		const frame2 = concat(
			new Uint8Array(12),
			u16be(8), // size_halfwords=8 -> 8*2=16 bytes span (header only, no payload)
			new Uint8Array([0, 31]),
			new Uint8Array(12)
		);

		const buf = concat(volumeHeader, frame1Padded, frame2);
		const messages = Array.from(walkMessages(buf));

		expect(messages).toHaveLength(2);
		expect(messages[0]).toMatchObject({ frameOff: 24, messageType: 2 });
		expect(messages[1]).toMatchObject({ frameOff: 24 + 2432, messageType: 31 });
	});
});
