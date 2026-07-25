import type { Observation, MomentType, Channel, Scan } from '$lib/domain';
import { isGzipMagic } from '../sniff';
import { inflateGzip } from './gunzip';
import { parseVolumeHeader, walkMessages } from './messages';
import { parseDataHeaderBlock, decodeMomentBlock } from './message31';

// ICD Table II note 2: "1 January 1970 00:00 GMT = 1 Modified Julian Date", i.e. day 1 is
// 1970-01-01 -- confirmed against real fixtures in docs/formatos.md.
const L2_EPOCH_MS = Date.UTC(1970, 0, 1);

function julianMsToIso(julianDate: number, msOfDay: number): string {
	return new Date(L2_EPOCH_MS + (julianDate - 1) * 86_400_000 + msOfDay).toISOString();
}

const MOMENT_TAG_TO_TYPE: Partial<Record<string, MomentType>> = {
	REF: 'dBZ',
	VEL: 'V',
	SW: 'W',
	ZDR: 'ZDR',
	PHI: 'uPhiDP',
	RHO: 'RhoHV'
};

interface OpenScan {
	elevationNumber: number;
	angleDeg: number;
	rangeToFirstGateM: number;
	gateLengthM: number;
	numGates: number;
	rayAnglesDeg: number[];
	rows: Float32Array[];
	flagRows: Uint8Array[];
}

export async function parseNexradL2(bytes: Uint8Array): Promise<Observation> {
	const buf = isGzipMagic(bytes) ? await inflateGzip(bytes) : bytes;
	const volumeHeader = parseVolumeHeader(buf);
	const timestamp = julianMsToIso(volumeHeader.julianDate, volumeHeader.msOfDay);

	// Grouped by elevation_number (a per-volume cut index, NOT a unique physical angle -- split
	// cuts revisit close angles under different elevation_number values, see docs/formatos.md).
	// Each moment gets its own open cut and its own finished Scan list, since a moment may be
	// absent from some cuts (dual-pol-only vs Doppler-only cuts) -- see domain/types.ts.
	const finishedScans = new Map<MomentType, Scan[]>();
	const openScans = new Map<MomentType, OpenScan>();
	let currentElevation: number | null = null;

	function flushOpenCut(): void {
		for (const [moment, open] of openScans) {
			const numRays = open.rayAnglesDeg.length;
			const values = new Float32Array(numRays * open.numGates);
			const flags = new Uint8Array(numRays * open.numGates);
			for (let ray = 0; ray < numRays; ray++) {
				values.set(open.rows[ray], ray * open.numGates);
				flags.set(open.flagRows[ray], ray * open.numGates);
			}
			const rayAngles = Float32Array.from(open.rayAnglesDeg);
			const scan: Scan = {
				id: open.elevationNumber,
				angleDeg: open.angleDeg,
				rangeToFirstGateM: open.rangeToFirstGateM,
				gateLengthM: open.gateLengthM,
				numRays,
				numGates: open.numGates,
				// NEXRAD gives one azimuth angle per radial, not a start/stop pair like Rainbow5 --
				// duplicating rather than fabricating a span (see domain Scan.rayStartAnglesDeg).
				rayStartAnglesDeg: rayAngles,
				rayStopAnglesDeg: rayAngles,
				cells: { numRays, numGates: open.numGates, values, flags }
			};
			let scans = finishedScans.get(moment);
			if (!scans) {
				scans = [];
				finishedScans.set(moment, scans);
			}
			scans.push(scan);
		}
		openScans.clear();
	}

	for (const msg of walkMessages(buf)) {
		if (msg.messageType !== 31) continue;
		const dhb = parseDataHeaderBlock(buf, msg.headerOff);

		if (currentElevation !== null && dhb.elevationNumber !== currentElevation) {
			flushOpenCut();
		}
		currentElevation = dhb.elevationNumber;

		for (const [tag, blockOff] of dhb.blocks) {
			if (tag[0] !== 'D') continue; // 'R'-prefixed blocks (RVOL/RELV/RRAD) are constants, not gate data
			const momentType = MOMENT_TAG_TO_TYPE[tag.slice(1)];
			if (!momentType) continue; // unrecognized moment tag: skip rather than guess

			const block = decodeMomentBlock(buf, blockOff);
			let open = openScans.get(momentType);
			if (!open) {
				open = {
					elevationNumber: dhb.elevationNumber,
					angleDeg: dhb.elevationAngleDeg,
					rangeToFirstGateM: block.rangeToFirstGateM,
					gateLengthM: block.gateLengthM,
					numGates: block.numGates,
					rayAnglesDeg: [],
					rows: [],
					flagRows: []
				};
				openScans.set(momentType, open);
			}
			if (block.numGates !== open.numGates) {
				throw new Error(
					`moment ${momentType}: gate count changed mid-cut (${open.numGates} -> ${block.numGates}) ` +
						`at elevation_number ${dhb.elevationNumber}`
				);
			}
			open.rayAnglesDeg.push(dhb.azimuthAngleDeg);
			open.rows.push(block.values);
			open.flagRows.push(block.flags);
		}
	}
	flushOpenCut();

	if (finishedScans.size === 0) {
		throw new Error('no message-31 (digital radar data) found in this file');
	}

	const channels: Channel[] = Array.from(finishedScans.entries()).map(([moment, scans], id) => ({
		id,
		moment,
		scans
	}));

	return {
		id: `${volumeHeader.site}_${timestamp}`,
		site: { name: volumeHeader.site, code: volumeHeader.site },
		timestamp,
		design: volumeHeader.tapeId,
		movements: [{ id: 0, kind: 'PPI', channels }]
	};
}
