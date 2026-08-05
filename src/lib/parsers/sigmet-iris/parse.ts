// Sigmet/IRIS RAW parser -- one file is one elevation sweep (unlike Rainbow5/NEXRAD L2, which
// each bundle a whole multi-tilt volume in one file), carrying several moments per file (like
// NEXRAD L2's message-31, unlike Rainbow5's one-moment-per-.vol). Byte layout ported from
// xradar's iris.py backend (the oracle -- no legacy Delphi source, same situation Rainbow5 was
// in) and cross-verified field-by-field against the real fixtures in
// test-fixtures/observations/ideam/sigmet-raw (see test-fixtures/reference/ideam/sigmet_probe.py).
//
// File layout (RECORD_BYTES=6144 fixed-size physical records):
//  record 0: PRODUCT_HDR -- unused, this parser never reads it (ingest_header below has
//    everything needed: site position, wavelength, PRF, range geometry).
//  record 1 (byte 6144): INGEST_HEADER (site position, task config, data-type bitmask).
//  record 2 onward: each record is [12-byte RAW_PROD_BHDR][payload]; the payload starting right
//    after record 2's bhdr is N x 76-byte INGEST_DATA_HEADER (one per moment present), then the
//    ray data stream: for ray in 0..rays-1, for moment in declaration order, one run-length
//    compressed ray block. Crossing a record boundary mid-ray always means: skip 12 bytes (the
//    new record's bhdr), then keep reading.
import type { Observation, MomentType, Channel, CellFlag } from '$lib/domain';
import { cellFlagCode } from '$lib/domain/cells';
import {
	decodeBin2,
	decodeBin4,
	decodeDbz,
	decodeZdr,
	decodePhidp,
	decodeVel,
	decodeRhohv,
	decodeKdp
} from './decode';

const RECORD_BYTES = 6144;
const BHDR_BYTES = 12;
const INGEST_HEADER_BASE = RECORD_BYTES; // record 1
const INGEST_DATA_HEADER_BYTES = 76;

// Byte offsets below are all relative to INGEST_HEADER_BASE -- verified against the real fixture
// by reading these exact positions and diffing against xradar's parsed field values (see the
// sigmet_probe.py-style checks noted in the memory doc; not re-derived from the ICD alone).
const OFF = {
	latitudeRadar: 180,
	longitudeRadar: 184,
	altitudeRadar: 200,
	siteName: 162, // 16 bytes, ASCII, null/space-padded
	dspMaskWords: [628, 636, 640, 644, 648], // uint32 each; word at 632 is extended_header_type, skip
	prf: 760,
	multiPrfModeFlag: 768,
	wavelength: 1744, // hundredths of a cm
	rangeFirstBin: 1264, // hundredths of a metre (cm)
	numberOutputBins: 1274,
	stepOutputBins: 1280 // hundredths of a metre (cm)
} as const;

// Sigmet data-type code -> our MomentType + decode fn. DB_HCLASS (55, hydrometeor
// classification) has no slot in MomentType -- it's categorical, not a physical moment -- so it's
// simply not in this table and gets skipped when building channels.
const DBZ_CODE = 2;
const VEL_CODE = 3;
const ZDR_CODE = 5;
const KDP_CODE = 14;
const PHIDP_CODE = 16;
const RHOHV_CODE = 19;

interface DataTypeHeader {
	numberRaysExpected: number;
	fixedAngleDeg: number;
	dataType: number;
	sweepStartTime: string;
}

// YMDS_TIME (12 bytes): seconds-of-day (int32), milliseconds (uint16), year/month/day (int16 each).
function decodeYmdsTime(view: DataView, byteOffset: number): string {
	const secondsOfDay = view.getInt32(byteOffset, true);
	const milliseconds = view.getUint16(byteOffset + 4, true);
	const year = view.getInt16(byteOffset + 6, true);
	const month = view.getInt16(byteOffset + 8, true);
	const day = view.getInt16(byteOffset + 10, true);
	const date = new Date(Date.UTC(year, month - 1, day, 0, 0, secondsOfDay, milliseconds));
	return date.toISOString();
}

function popcount32(n: number): number {
	let count = 0;
	let x = n >>> 0;
	while (x) {
		count += x & 1;
		x >>>= 1;
	}
	return count;
}

function readAsciiField(view: DataView, byteOffset: number, length: number): string {
	const bytes = new Uint8Array(view.buffer, view.byteOffset + byteOffset, length);
	let end = bytes.length;
	while (end > 0 && (bytes[end - 1] === 0 || bytes[end - 1] === 0x20)) end--;
	return String.fromCharCode(...bytes.subarray(0, end));
}

/** Walks the RAW file's record stream, transparently skipping each new record's 12-byte
 * RAW_PROD_BHDR -- records are a storage/transmission chunking detail, not a logical boundary
 * the ray-compression stream respects. */
class RecordCursor {
	private recordNumber: number;
	private posInRecord: number;

	constructor(
		private view: DataView,
		startAbsByteOffset: number
	) {
		this.recordNumber = Math.floor(startAbsByteOffset / RECORD_BYTES);
		this.posInRecord = startAbsByteOffset % RECORD_BYTES;
	}

	private absOffset(): number {
		return this.recordNumber * RECORD_BYTES + this.posInRecord;
	}

	/** Raw 16-bit word, always read as unsigned -- callers reinterpret signedness where it matters
	 * (compression control codes via bit 15, KDP bytes via >127 wraparound). */
	readUint16(): number {
		if (this.posInRecord + 2 > RECORD_BYTES) {
			this.recordNumber += 1;
			this.posInRecord = BHDR_BYTES;
		}
		const v = this.view.getUint16(this.absOffset(), true);
		this.posInRecord += 2;
		return v;
	}
}

/** One run-length-compressed ray, decompressed into a fixed-size word buffer. Compression codes
 * are 16-bit words: bit 15 set means "N literal words follow" (N = low 15 bits), bit 15 clear
 * means "N zero words" (no literal words follow -- the buffer is already zero-filled, so this is
 * a no-op besides advancing the position), and the sentinel value 1 (bit 15 clear) terminates the
 * ray. A ray whose very first code is that terminator has no data at all (stays all zero). */
function readRay(cursor: RecordCursor, outWords: Uint16Array): void {
	outWords.fill(0);
	let rayPos = 0;
	for (;;) {
		const code = cursor.readUint16();
		const literal = (code & 0x8000) !== 0;
		const count = code & 0x7fff;
		if (!literal && count === 1) return; // terminator (also covers "ray missing" on the first code)
		if (literal) {
			for (let i = 0; i < count; i++) outWords[rayPos + i] = cursor.readUint16();
		}
		rayPos += count;
	}
}

/** Unpacks a ray's moment words into `gateCount` raw byte codes -- 1-byte Sigmet moments pack two
 * gates per 16-bit word (low byte = even gate, high byte = odd gate). */
function unpackGateBytes(words: Uint16Array, wordOffset: number, gateCount: number): Uint8Array {
	const bytes = new Uint8Array(gateCount);
	for (let g = 0; g < gateCount; g++) {
		const word = words[wordOffset + (g >> 1)];
		bytes[g] = g % 2 === 0 ? word & 0xff : (word >> 8) & 0xff;
	}
	return bytes;
}

function toSignedByte(raw: number): number {
	return raw > 127 ? raw - 256 : raw;
}

export async function parseSigmetIris(bytes: Uint8Array, fileName: string): Promise<Observation> {
	const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
	const ih = INGEST_HEADER_BASE;

	const structureIdAtStart = view.getInt16(0, true);
	const structureIdAtIngestHeader = view.getInt16(ih, true);
	if (structureIdAtStart !== 27 || structureIdAtIngestHeader !== 23) {
		throw new Error(
			`sigmet-iris: unexpected structure identifiers (${structureIdAtStart}, ${structureIdAtIngestHeader}) -- not a RAW ingest file`
		);
	}

	let lat = decodeBin4(view.getUint32(ih + OFF.latitudeRadar, true));
	let lon = decodeBin4(view.getUint32(ih + OFF.longitudeRadar, true));
	if (lat > 180) lat -= 360;
	if (lon > 180) lon -= 360;
	const altM = view.getInt32(ih + OFF.altitudeRadar, true) / 100;
	const siteName = readAsciiField(view, ih + OFF.siteName, 16);

	const wavelengthRaw = view.getInt32(ih + OFF.wavelength, true); // hundredths of a cm
	const wavelengthCm = wavelengthRaw / 100;
	const prf = view.getInt32(ih + OFF.prf, true);
	const multiPrfModeFlag = view.getUint16(ih + OFF.multiPrfModeFlag, true);
	// Nyquist formula and its units (raw hundredths-of-cm wavelength, not /100) straight from
	// xradar's decode_data: nyquist = wavelength * prf / (10000 * 4), then x(multi_prf_mode+1).
	const nyquistMs = ((wavelengthRaw * prf) / (10000 * 4)) * (multiPrfModeFlag + 1);

	const numGates = view.getInt16(ih + OFF.numberOutputBins, true);
	const rangeToFirstGateM = view.getInt32(ih + OFF.rangeFirstBin, true) / 100;
	const gateLengthM = view.getInt32(ih + OFF.stepOutputBins, true) / 100;

	let dataTypeCount = 0;
	for (const off of OFF.dspMaskWords) {
		dataTypeCount += popcount32(view.getUint32(ih + off, true));
	}
	if (dataTypeCount === 0)
		throw new Error('sigmet-iris: no data types found in task configuration');

	const record2Base = 2 * RECORD_BYTES;
	const idhBase = record2Base + BHDR_BYTES;
	const headers: DataTypeHeader[] = [];
	for (let i = 0; i < dataTypeCount; i++) {
		const base = idhBase + i * INGEST_DATA_HEADER_BYTES;
		headers.push({
			numberRaysExpected: view.getInt16(base + 30, true),
			fixedAngleDeg: decodeBin2(view.getUint16(base + 34, true)),
			dataType: view.getUint16(base + 38, true),
			sweepStartTime: decodeYmdsTime(view, base + 12)
		});
	}

	const numRays = headers[0].numberRaysExpected;
	const rayDataStartAbs = idhBase + dataTypeCount * INGEST_DATA_HEADER_BYTES;
	const cursor = new RecordCursor(view, rayDataStartAbs);

	const rayWordCount = 6 + numGates;
	const rayStartAnglesDeg = new Float32Array(numRays);
	const rayStopAnglesDeg = new Float32Array(numRays);
	// Raw byte codes per (dataType, ray) -- decoded into physical values only for moments we keep.
	const rawByType = new Map<number, Uint8Array[]>();
	for (const h of headers) rawByType.set(h.dataType, new Array(numRays));

	const words = new Uint16Array(rayWordCount);
	for (let ray = 0; ray < numRays; ray++) {
		for (const header of headers) {
			readRay(cursor, words);
			if (header === headers[0]) {
				rayStartAnglesDeg[ray] = decodeBin2(words[0]);
				rayStopAnglesDeg[ray] = decodeBin2(words[2]);
			}
			rawByType.get(header.dataType)![ray] = unpackGateBytes(words, 6, numGates);
		}
	}

	function buildChannel(
		id: number,
		dataType: number,
		moment: MomentType,
		decode: (raw: number) => number | null
	): Channel | undefined {
		const header = headers.find((h) => h.dataType === dataType);
		const rawRays = rawByType.get(dataType);
		if (!header || !rawRays) return undefined;

		const values = new Float32Array(numRays * numGates);
		const flags = new Uint8Array(numRays * numGates);
		const okCode = cellFlagCode('ok' as CellFlag);
		const noDataCode = cellFlagCode('no-data' as CellFlag);
		for (let ray = 0; ray < numRays; ray++) {
			const rawGates = rawRays[ray];
			for (let gate = 0; gate < numGates; gate++) {
				const idx = ray * numGates + gate;
				const decoded = decode(rawGates[gate]);
				if (decoded === null) {
					flags[idx] = noDataCode;
				} else {
					values[idx] = decoded;
					flags[idx] = okCode;
				}
			}
		}

		return {
			id,
			moment,
			waveLengthM: wavelengthCm / 100,
			scans: [
				{
					id: 0,
					angleDeg: header.fixedAngleDeg,
					rangeToFirstGateM,
					gateLengthM,
					numRays,
					numGates,
					rayStartAnglesDeg,
					rayStopAnglesDeg,
					cells: { numRays, numGates, values, flags }
				}
			]
		};
	}

	const channelSpecs: [number, MomentType, (raw: number) => number | null][] = [
		[DBZ_CODE, 'dBZ', decodeDbz],
		[VEL_CODE, 'V', (raw) => decodeVel(raw, nyquistMs)],
		[ZDR_CODE, 'ZDR', decodeZdr],
		[KDP_CODE, 'KDP', (raw) => decodeKdp(toSignedByte(raw), wavelengthCm)],
		[PHIDP_CODE, 'uPhiDP', decodePhidp],
		[RHOHV_CODE, 'RhoHV', decodeRhohv]
	];

	const channels: Channel[] = [];
	let nextId = 0;
	for (const [dataType, moment, decode] of channelSpecs) {
		const channel = buildChannel(nextId, dataType, moment, decode);
		if (channel) {
			channels.push(channel);
			nextId++;
		}
	}
	if (channels.length === 0) throw new Error('sigmet-iris: no supported moments found in file');

	const timestamp = headers[0].sweepStartTime;
	return {
		id: `${siteName || fileName}_${timestamp}`,
		site: { name: siteName, code: siteName, lat, lon, altM },
		timestamp,
		design: fileName,
		movements: [{ id: 0, kind: 'PPI', channels }]
	};
}
