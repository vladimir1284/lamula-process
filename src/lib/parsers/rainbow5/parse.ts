import type { Observation, MomentType, Channel } from '$lib/domain';
import { parseXml, requireChild, requireAttr, childText, children } from '../xml';
import { splitHeader, readBlobs } from './blobs';
import { decodeRayAngles, decodeMoment } from './decode';

const KNOWN_MOMENTS: readonly MomentType[] = ['dBZ', 'dBuZ', 'V', 'W', 'ZDR', 'uPhiDP', 'RhoHV'];

function asMomentType(type: string): MomentType {
	if (!(KNOWN_MOMENTS as readonly string[]).includes(type)) {
		throw new Error(`unknown Rainbow5 moment type "${type}"`);
	}
	return type as MomentType;
}

export async function parseRainbow5(bytes: Uint8Array): Promise<Observation> {
	// Every offset below (marker index, blob tag positions) is computed on this string and reused
	// directly against `bytes` -- 'latin1' resolves to windows-1252 per the WHATWG Encoding Standard
	// (there's no way to request strict ISO-8859-1 via TextDecoder), but every byte still maps to
	// exactly one UTF-16 code unit, so string/byte offsets stay aligned regardless.
	const text = new TextDecoder('latin1').decode(bytes);
	const { headerXml, blobsStart } = splitHeader(text);
	const root = parseXml(headerXml);
	const volume = requireChild(root, 'volume');
	const scan = requireChild(volume, 'scan');
	const sensorinfo = requireChild(volume, 'sensorinfo');

	const volumeType = requireAttr(volume, 'type');
	// RHI ("corte vertical") layout has no verified fixture yet, see docs/formatos.md.
	if (volumeType !== 'vol') {
		throw new Error(
			`Rainbow5 volume type "${volumeType}" not verified against real fixtures (only "vol"/PPI is)`
		);
	}

	const blobs = await readBlobs(bytes, text, blobsStart);
	const getBlob = (id: number): Uint8Array => {
		const blob = blobs.get(id);
		if (!blob) throw new Error(`missing blob ${id}`);
		return blob;
	};

	const slices = children(scan, 'slice');
	if (slices.length === 0) throw new Error('volume has no <slice> elements');

	// <pargroup> carries scan-wide defaults; a <slice> only repeats a field when it overrides that
	// default (confirmed on real bandaS fixtures: slices 1-5 omit <stoprange>/<start_range> entirely
	// and share pargroup's 250/0, slice 6+ each redeclare their own shorter stoprange).
	const pargroup = requireChild(scan, 'pargroup');
	const sliceField = (slice: (typeof slices)[number], tag: string): string => {
		const value = childText(slice, tag) ?? childText(pargroup, tag);
		if (value === undefined) throw new Error(`neither <slice> nor <pargroup> has <${tag}>`);
		return value;
	};

	let moment: MomentType | undefined;
	const scans = slices.map((slice, index) => {
		const sliceData = requireChild(slice, 'slicedata');
		const rawdata = requireChild(sliceData, 'rawdata');
		const rayinfos = children(sliceData, 'rayinfo');

		const rays = Number(requireAttr(rawdata, 'rays'));
		const bins = Number(requireAttr(rawdata, 'bins'));
		const depth = Number(requireAttr(rawdata, 'depth'));
		const vmin = Number(requireAttr(rawdata, 'min'));
		const vmax = Number(requireAttr(rawdata, 'max'));

		const sliceMoment = asMomentType(requireAttr(rawdata, 'type'));
		if (moment !== undefined && moment !== sliceMoment) {
			throw new Error(`mixed moment types within one volume: "${moment}" and "${sliceMoment}"`);
		}
		moment = sliceMoment;

		const startAngleInfo = rayinfos.find((ri) => ri.attrs.refid === 'startangle');
		const stopAngleInfo = rayinfos.find((ri) => ri.attrs.refid === 'stopangle');
		if (!startAngleInfo || !stopAngleInfo) {
			throw new Error('slice missing startangle/stopangle rayinfo');
		}
		const rayStartAnglesDeg = decodeRayAngles(
			getBlob(Number(requireAttr(startAngleInfo, 'blobid'))),
			Number(requireAttr(startAngleInfo, 'depth'))
		);
		const rayStopAnglesDeg = decodeRayAngles(
			getBlob(Number(requireAttr(stopAngleInfo, 'blobid'))),
			Number(requireAttr(stopAngleInfo, 'depth'))
		);

		const { values, flags } = decodeMoment(
			getBlob(Number(requireAttr(rawdata, 'blobid'))),
			rays,
			bins,
			depth,
			vmin,
			vmax
		);

		const stopRangeKm = Number(sliceField(slice, 'stoprange'));
		const startRangeKm = Number(sliceField(slice, 'start_range'));
		// stoprange/start_range are declared in km in every fixture seen; bin count stays fixed per
		// slice while max range shortens at higher tilts, so gate length is derived per scan, not a
		// fixed per-channel constant -- see docs/formatos.md and domain Scan.gateLengthM.
		const gateLengthM = ((stopRangeKm - startRangeKm) * 1000) / bins;

		const angleText = childText(slice, 'posangle');
		if (angleText === undefined) throw new Error('slice missing <posangle>');

		return {
			id: Number(slice.attrs.refid ?? index),
			angleDeg: Number(angleText),
			rangeToFirstGateM: startRangeKm * 1000,
			gateLengthM,
			numRays: rays,
			numGates: bins,
			rayStartAnglesDeg,
			rayStopAnglesDeg,
			cells: { numRays: rays, numGates: bins, values, flags }
		};
	});

	if (moment === undefined) throw new Error('unreachable: no slice produced a moment type');

	const lonText = childText(sensorinfo, 'lon');
	const latText = childText(sensorinfo, 'lat');
	const altText = childText(sensorinfo, 'alt');
	const waveLenText = childText(sensorinfo, 'wavelen');
	const beamWidthText = childText(sensorinfo, 'beamwidth');
	if (!lonText || !latText || !altText || !waveLenText || !beamWidthText) {
		throw new Error('sensorinfo missing lon/lat/alt/wavelen/beamwidth');
	}

	const site = {
		name: requireAttr(sensorinfo, 'name'),
		code: requireAttr(sensorinfo, 'id'),
		lat: Number(latText),
		lon: Number(lonText),
		altM: Number(altText)
	};

	const channel: Channel = {
		id: 0,
		moment,
		waveLengthM: Number(waveLenText),
		beamWidthDeg: Number(beamWidthText),
		scans
	};

	const datetime = requireAttr(volume, 'datetime');

	return {
		id: `${site.code}_${datetime}_${moment}`,
		site,
		timestamp: datetime,
		design: requireAttr(scan, 'name'),
		movements: [{ id: 0, kind: 'PPI', channels: [channel] }]
	};
}
