import type { Observation, Channel, Scan, MomentType } from '$lib/domain';
import {
	HEADER_SIZE,
	CHANNEL_DESC_SIZE,
	PPI_DESC_SIZE,
	PPI_HEADER_SIZE,
	parseFileHeader,
	readLocations,
	readChannelDesc,
	readPpiDesc,
	readPpiHeader
} from './messages';
import { MEASURE_TO_MOMENT, decodeCells } from './decode';

// dRadar, ported from Obs_Parser.py -- not independently re-derivable from bytes, this enum mapping
// is the authoritative source (the format author's own 2013 decoder).
const RADAR_NAMES: Partial<Record<number, string>> = {
	0: 'rdNone',
	1: 'rdLaBajada',
	2: 'rdPuntaDelEste',
	3: 'rdCasablanca',
	4: 'rdPicoSanJuan',
	5: 'rdCamaguey',
	6: 'rdPilon',
	7: 'rdGranPiedra',
	8: 'rdMcGill',
	9: 'rdRoma',
	10: 'rdCP2_SCMS',
	11: 'rdHolguin',
	12: 'rdVenMaracaibo',
	13: 'rdVenJeremba',
	14: 'rdVenGuasdualito',
	15: 'rdVenAyacucho',
	16: 'rdVenCarupano',
	17: 'rdVenKarum',
	18: 'rdVenSantaElena',
	19: 'rdVenGuri',
	20: 'rdCamaguey1'
};

// dWaveLength, same source: 'wl3cm'/'wl10cm'/'wl5cm' turned into meters.
const WAVELENGTH_M: Partial<Record<number, number>> = { 0: 0.03, 1: 0.1, 2: 0.05 };

async function inflateZlib(bytes: Uint8Array): Promise<Uint8Array> {
	// Copy into a fresh ArrayBuffer-backed array, same reasoning as rainbow5/blobs.ts: `bytes` may
	// be a view whose .buffer type isn't assignable to BlobPart.
	const stream = new Blob([new Uint8Array(bytes)])
		.stream()
		.pipeThrough(new DecompressionStream('deflate'));
	return new Uint8Array(await new Response(stream).arrayBuffer());
}

interface ScanGroup {
	channelIdx: number;
	moment: MomentType;
	scans: Scan[];
}

export async function parseInsmet(bytes: Uint8Array): Promise<Observation> {
	const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
	const header = parseFileHeader(view);
	const locations = readLocations(view, HEADER_SIZE, header.ppiCount);

	const channelDescOffset = HEADER_SIZE + 4 * header.ppiCount;
	const channelDescs = Array.from({ length: header.channelCount }, (_, i) =>
		readChannelDesc(view, channelDescOffset + i * CHANNEL_DESC_SIZE)
	);

	// Grouped by (source channel index, moment): a single physical channel can carry more than one
	// moment (e.g. a "batch" cut bundles dBZ+V+W together on one short-pulse channel), and the SAME
	// moment can come from more than one physical channel across different elevations (long-pulse
	// dBZ from channel 0 vs short-pulse dBZ from channel 1) -- confirmed on the real c02y1830
	// fixture, where channel 1 carries unDBZ PPIs too, each with its own met_potential. A moment-only
	// grouping (like NEXRAD L2's) would silently merge those and lose per-channel calibration.
	const groups = new Map<string, ScanGroup>();

	for (const loc of locations) {
		const desc = readPpiDesc(view, loc);
		if (desc.kindCode !== 0) {
			throw new Error(
				`.obs PPI plane kind ${desc.kindCode} (vertical/RHI) not verified against any real fixture`
			);
		}
		const moment = MEASURE_TO_MOMENT[desc.measureCode];
		if (!moment) {
			throw new Error(
				`.obs measure code ${desc.measureCode} not decoded (never seen in verified fixtures)`
			);
		}

		const ppiHeader = readPpiHeader(view, loc + PPI_DESC_SIZE);
		if (ppiHeader.packMethod !== 0 && ppiHeader.packMethod !== 2) {
			throw new Error(
				`.obs pack method ${ppiHeader.packMethod} (only pmNone/0 and pmZLib/2 verified against real fixtures)`
			);
		}

		const dataOff = loc + PPI_DESC_SIZE + PPI_HEADER_SIZE;
		const packed = bytes.subarray(dataOff, dataOff + ppiHeader.packedSize);
		// pmNone (0): stored uncompressed, packed bytes are already the payload -- ported from
		// Obs_Parser.py's dVestaPackMethod, which reserves pmDAS (1) as a third method it itself
		// never implements ("Unhadled compression method"), so only 0/2 are handled here too.
		const raw = ppiHeader.packMethod === 0 ? new Uint8Array(packed) : await inflateZlib(packed);
		if (raw.length !== ppiHeader.unpackedSize) {
			throw new Error(
				`PPI at offset ${loc}: decompressed ${raw.length} bytes, header declares ${ppiHeader.unpackedSize}`
			);
		}

		const numRays = desc.sectorCount;
		if (numRays === 0 || ppiHeader.unpackedSize % numRays !== 0) {
			throw new Error(
				`PPI at offset ${loc}: unpacked size ${ppiHeader.unpackedSize} not divisible by sector count ${numRays}`
			);
		}
		// NOT the channel descriptor's number_of_cells: verified on real fixtures that channel 1's
		// field (450/540) doesn't match the actual per-row gate count baked into the blob, which is
		// always unpackedSize/sectorCount (648000/360=1800, same as channel 0's declared count) --
		// see docs/formatos.md.
		const numGates = ppiHeader.unpackedSize / numRays;

		const channelDesc = channelDescs[desc.channel];
		if (!channelDesc) {
			throw new Error(
				`PPI references channel ${desc.channel}, but only ${channelDescs.length} channel descriptors present`
			);
		}

		const { values, flags } = decodeCells(
			raw,
			desc.measureCode,
			numRays,
			numGates,
			desc.measureCode === 1
				? { cellLengthM: channelDesc.cellLengthM, metPotential: channelDesc.metPotential }
				: undefined
		);

		// .obs stores one start/finish azimuth pair for the whole PPI plus a sector count, not a
		// per-ray angle array like Rainbow5/NEXRAD L2. Every real fixture has start=0/finish=360 with
		// sectorCount=360 (exactly 1 deg/sector), so a uniform subdivision is a safe derived value
		// here, not a guess -- revisit if a partial-sector fixture ever turns up.
		const span = desc.finishAzDeg - desc.startAzDeg;
		const rayStartAnglesDeg = new Float32Array(numRays);
		const rayStopAnglesDeg = new Float32Array(numRays);
		for (let i = 0; i < numRays; i++) {
			rayStartAnglesDeg[i] = desc.startAzDeg + (span * i) / numRays;
			rayStopAnglesDeg[i] = desc.startAzDeg + (span * (i + 1)) / numRays;
		}

		const scan: Scan = {
			id: 0, // overwritten with an index into this group's own scan list below
			angleDeg: desc.angleDeg,
			// .obs doesn't carry a range-to-first-gate field; every real fixture's radar starts
			// sampling at the antenna (range 0), same assumption the Rainbow5 fixtures happen to use.
			rangeToFirstGateM: 0,
			gateLengthM: channelDesc.cellLengthM,
			numRays,
			numGates,
			rayStartAnglesDeg,
			rayStopAnglesDeg,
			cells: { numRays, numGates, values, flags }
		};

		const key = `${desc.channel}:${moment}`;
		let group = groups.get(key);
		if (!group) {
			group = { channelIdx: desc.channel, moment, scans: [] };
			groups.set(key, group);
		}
		scan.id = group.scans.length;
		group.scans.push(scan);
	}

	if (groups.size === 0) throw new Error('.obs file has no PPI blocks');

	const channels: Channel[] = Array.from(groups.values()).map((group, id) => {
		const channelDesc = channelDescs[group.channelIdx];
		return {
			id,
			moment: group.moment,
			waveLengthM: WAVELENGTH_M[channelDesc.waveLengthCode],
			beamWidthDeg: channelDesc.beamWidthDeg,
			calibration: {
				metPotential: channelDesc.metPotential,
				deltaPotential: channelDesc.deltaPotential
			},
			scans: group.scans
		};
	});

	const siteCode = RADAR_NAMES[header.radarCode] ?? `rdUnknown${header.radarCode}`;

	return {
		id: `${siteCode}_${header.timestampIso}`,
		// .obs doesn't carry a separate human-readable site name, only this Pascal enum identifier.
		site: { name: siteCode, code: siteCode },
		timestamp: header.timestampIso,
		design: header.design,
		movements: [{ id: 0, kind: 'PPI', channels }]
	};
}
