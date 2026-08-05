// CfRadial/PPIVol parser for IDEAM's NetCDF sites (Bogota, santa_elena/SIATA). Confirmed to be
// standard CfRadial (global attr Conventions="Cf/Radial...") over classic NETCDF3 (see
// ../netcdf3.ts and test-fixtures/reference/ideam/netcdf_probe.py). Like Sigmet/IRIS RAW, one
// file is one elevation sweep carrying several moments (unlike Rainbow5's one-moment-per-file).
import type { Observation, MomentType, Channel, CellFlag } from '$lib/domain';
import { cellFlagCode } from '$lib/domain/cells';
import { readNetcdf3, findVar, ncCharsToString, type Netcdf3File } from '../netcdf3';
import { rayCenterToStartStop } from './decode';

// CfRadial variable name -> our MomentType. UH/UV (uncorrected H/V reflectivity), DBZV/VELV/WIDTHV
// (V-channel counterparts), NCPH/NCPV (normalized coherent power), SNRHC/SNRVC, CCORH/CCORV
// (clutter correction) and HMC (hydrometeor classification) have no MomentType slot -- same
// "drop what doesn't fit the domain model" call as Sigmet/IRIS RAW's DB_HCLASS.
const MOMENT_VARS: readonly [string, MomentType][] = [
	['DBZH', 'dBZ'],
	['VELH', 'V'],
	['WIDTHH', 'W'],
	['ZDR', 'ZDR'],
	['RHOHV', 'RhoHV'],
	['PHIDP', 'uPhiDP'],
	['KDP', 'KDP']
];

function requireVar(file: Netcdf3File, name: string) {
	return findVar(file, name);
}

export async function parseCfRadial(bytes: Uint8Array, fileName: string): Promise<Observation> {
	const file = readNetcdf3(bytes);

	const conventions = String(file.globalAttrs.Conventions ?? '');
	if (!conventions.includes('Cf/Radial')) {
		throw new Error(`netcdf-cfradial: not a CfRadial file (Conventions="${conventions}")`);
	}

	const lat = requireVar(file, 'latitude').data[0];
	const lon = requireVar(file, 'longitude').data[0];
	const altM = requireVar(file, 'altitude').data[0];
	const siteCode = String(
		file.globalAttrs.instrument_name ?? file.globalAttrs.site_name ?? fileName
	);
	const timestamp = ncCharsToString(requireVar(file, 'time_coverage_start'));

	const range = requireVar(file, 'range');
	const numGates = range.data.length;
	const rangeToFirstGateM = range.data[0];
	const gateLengthM = range.data[1] - range.data[0];

	const fixedAngleDeg = requireVar(file, 'fixed_angle').data[0];
	const azimuthVar = requireVar(file, 'azimuth');
	const numRays = azimuthVar.data.length;
	const azimuthsDeg = new Float32Array(azimuthVar.data);
	const { start: rayStartAnglesDeg, stop: rayStopAnglesDeg } = rayCenterToStartStop(azimuthsDeg);

	const okCode = cellFlagCode('ok' as CellFlag);
	const noDataCode = cellFlagCode('no-data' as CellFlag);

	const channels: Channel[] = [];
	let nextId = 0;
	for (const [varName, moment] of MOMENT_VARS) {
		const v = file.variables.find((x) => x.name === varName);
		if (!v) continue;

		const fillValue = Number(v.attrs._FillValue);
		const scale = v.attrs.scale_factor !== undefined ? Number(v.attrs.scale_factor) : 1;
		const offset = v.attrs.add_offset !== undefined ? Number(v.attrs.add_offset) : 0;

		const values = new Float32Array(numRays * numGates);
		const flags = new Uint8Array(numRays * numGates);
		for (let i = 0; i < values.length; i++) {
			const raw = v.data[i];
			if (raw === fillValue) {
				flags[i] = noDataCode;
			} else {
				values[i] = raw * scale + offset;
				flags[i] = okCode;
			}
		}

		channels.push({
			id: nextId++,
			moment,
			scans: [
				{
					id: 0,
					angleDeg: fixedAngleDeg,
					rangeToFirstGateM,
					gateLengthM,
					numRays,
					numGates,
					rayStartAnglesDeg,
					rayStopAnglesDeg,
					cells: { numRays, numGates, values, flags }
				}
			]
		});
	}
	if (channels.length === 0) throw new Error('netcdf-cfradial: no supported moments found in file');

	return {
		id: `${siteCode}_${timestamp}`,
		site: { name: siteCode, code: siteCode, lat, lon, altM },
		timestamp,
		design: fileName,
		movements: [{ id: 0, kind: 'PPI', channels }]
	};
}
