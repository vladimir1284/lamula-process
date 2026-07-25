// Byte layout confirmed against real Camagüey fixtures (test-fixtures/observations/insmet/) and the
// format author's own reference decoder (test-fixtures/reference/insmet/Obs_Parser.py), see
// docs/formatos.md#formato-interno--obs-vesta.
const HEADER_PART1_SIZE = 64; // signature(20) + 4x version uint16(8) + design(36)
export const HEADER_SIZE = HEADER_PART1_SIZE + 20; // + radar/daylight/variance/dummy(4) + time f64(8) + ppi/channel count(8)
export const CHANNEL_DESC_SIZE = 32;
export const PPI_DESC_SIZE = 28;
export const PPI_HEADER_SIZE = 12;

// OLE Automation date epoch (Delphi TDateTime shares it): days since 1899-12-30.
const OLE_EPOCH_MS = Date.UTC(1899, 11, 30);

export interface ObsFileHeader {
	design: string;
	radarCode: number;
	timestampIso: string;
	ppiCount: number;
	channelCount: number;
}

export function parseFileHeader(view: DataView): ObsFileHeader {
	const designBytes = new Uint8Array(view.buffer, view.byteOffset + 28, 36);
	const nul = designBytes.indexOf(0);
	const design = new TextDecoder('latin1').decode(designBytes.subarray(0, nul === -1 ? 36 : nul));

	const radarCode = view.getUint8(64);
	const obsTimeRaw = view.getFloat64(HEADER_PART1_SIZE + 4, true);
	const ppiCount = view.getUint32(HEADER_PART1_SIZE + 12, true);
	const channelCount = view.getUint32(HEADER_PART1_SIZE + 16, true);

	return {
		design,
		radarCode,
		timestampIso: new Date(OLE_EPOCH_MS + obsTimeRaw * 86_400_000).toISOString(),
		ppiCount,
		channelCount
	};
}

export function readLocations(view: DataView, offset: number, count: number): number[] {
	const locations: number[] = [];
	for (let i = 0; i < count; i++) locations.push(view.getUint32(offset + i * 4, true));
	return locations;
}

export interface ChannelDesc {
	waveLengthCode: number;
	cellLengthM: number;
	beamWidthDeg: number;
	metPotential: number;
	deltaPotential: number;
}

// num_of_sectors/number_of_cells are deliberately not read here -- verified unreliable for the
// per-PPI blob shape, see parse.ts.
export function readChannelDesc(view: DataView, offset: number): ChannelDesc {
	return {
		waveLengthCode: view.getUint8(offset),
		cellLengthM: view.getUint32(offset + 8, true),
		beamWidthDeg: view.getFloat32(offset + 16, true),
		metPotential: view.getFloat32(offset + 20, true),
		deltaPotential: view.getFloat32(offset + 24, true)
	};
}

export interface PpiDesc {
	channel: number;
	kindCode: number;
	measureCode: number;
	angleDeg: number;
	startAzDeg: number;
	finishAzDeg: number;
	sectorCount: number;
}

function code2angleDeg(code: number): number {
	return (code * 360) / 4096;
}

export function readPpiDesc(view: DataView, offset: number): PpiDesc {
	return {
		channel: view.getUint32(offset + 12, true),
		kindCode: view.getUint8(offset + 16),
		measureCode: view.getUint8(offset + 17),
		angleDeg: code2angleDeg(view.getInt16(offset + 18, true)),
		startAzDeg: code2angleDeg(view.getInt16(offset + 20, true)),
		finishAzDeg: code2angleDeg(view.getInt16(offset + 22, true)),
		sectorCount: view.getUint32(offset + 24, true)
	};
}

export interface PpiHeader {
	packMethod: number;
	packedSize: number;
	unpackedSize: number;
}

export function readPpiHeader(view: DataView, offset: number): PpiHeader {
	return {
		packMethod: view.getUint8(offset),
		packedSize: view.getUint32(offset + 4, true),
		unpackedSize: view.getUint32(offset + 8, true)
	};
}
