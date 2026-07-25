import { asciiString } from './ascii';

// Layout verified against real KMLB fixtures, see docs/formatos.md#formato-2--nexrad-level-ii-archive-ii.
const VOLUME_HEADER_SIZE = 24;
const CTM_PREFIX_SIZE = 12;
const MSG_HEADER_SIZE = 16;
// Fixed physical frame for every message type except 31 (12-byte prefix + 16-byte header + up to
// 2400 bytes of payload, zero-padded).
const LEGACY_FRAME_SIZE = 2432;

export interface VolumeHeader {
	tapeId: string;
	julianDate: number;
	msOfDay: number;
	site: string;
}

export function parseVolumeHeader(buf: Uint8Array): VolumeHeader {
	const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
	return {
		tapeId: asciiString(buf.subarray(0, 12)),
		julianDate: view.getUint32(12),
		msOfDay: view.getUint32(16),
		site: asciiString(buf.subarray(20, 24))
	};
}

export interface MessageHeader {
	frameOff: number;
	headerOff: number;
	messageSizeHalfwords: number;
	messageType: number;
}

// Message type 31 (Digital Radar Data) is not padded: its physical frame is exactly
// 12 + message_size*2 bytes, so the next frame starts right after it. Every other type occupies a
// fixed 2432-byte frame regardless of its declared size. Verified by scanning entire real files for
// header self-consistency at every frame boundary (~7600 confirmations per docs/formatos.md).
export function* walkMessages(buf: Uint8Array): Generator<MessageHeader> {
	const view = new DataView(buf.buffer, buf.byteOffset, buf.byteLength);
	let off = VOLUME_HEADER_SIZE;

	while (off + CTM_PREFIX_SIZE + MSG_HEADER_SIZE <= buf.length) {
		const headerOff = off + CTM_PREFIX_SIZE;
		const messageSizeHalfwords = view.getUint16(headerOff);
		const messageType = view.getUint8(headerOff + 3);

		yield { frameOff: off, headerOff, messageSizeHalfwords, messageType };

		off = messageType === 31 ? headerOff + messageSizeHalfwords * 2 : off + LEGACY_FRAME_SIZE;
	}
}
