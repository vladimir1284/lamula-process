import type { ParserDescriptor } from './types';
import {
	hasExtension,
	isGzipMagic,
	isNetcdf3Magic,
	isSigmetRawMagic,
	startsWithAscii
} from './sniff';

// IDEAM's Sigmet RAW filenames end in ".RAW" plus a 4-character hex-ish suffix (e.g.
// "COR250601000029.RAWYSAP"), so a plain `.raw` suffix check (hasExtension) never matches --
// this is the one format in this registry that needs its own filename pattern instead.
const SIGMET_RAW_FILENAME_RE = /\.raw[0-9a-z]{0,8}$/i;

// Extension check first (cheap, unambiguous when present), magic bytes as fallback for
// extensionless input (e.g. dropped from a File System Access API picker without a rename).
export const PARSER_DESCRIPTORS: readonly ParserDescriptor[] = [
	{
		id: 'rainbow5',
		label: 'Rainbow 5.0 (.vol)',
		canParse: (input) =>
			hasExtension(input.fileName, '.vol') || startsWithAscii(input.bytes, '<volume'),
		load: () => import('./rainbow5').then((m) => m.rainbow5Parser)
	},
	{
		id: 'nexrad-l2',
		label: 'NEXRAD Level II (Archive II)',
		canParse: (input) =>
			// Real files pulled from the NOAA/AWS bucket have no extension at all (e.g.
			// "KBYX20260726_113948_V06"), so the volume header's own "AR2V..." tape-id ASCII prefix
			// is the only reliable sniff for that case.
			hasExtension(input.fileName, '.ar2', '.ar2.bz2', '.gz') ||
			isGzipMagic(input.bytes) ||
			startsWithAscii(input.bytes, 'AR2V'),
		load: () => import('./nexrad-l2').then((m) => m.nexradL2Parser)
	},
	{
		id: 'insmet',
		label: 'Vesta observation container (.obs)',
		canParse: (input) =>
			hasExtension(input.fileName, '.obs') || startsWithAscii(input.bytes, 'Vesta Observation'),
		load: () => import('./insmet').then((m) => m.insmetParser)
	},
	{
		id: 'sigmet-iris',
		label: 'Sigmet/IRIS RAW (IDEAM Colombia)',
		canParse: (input) =>
			SIGMET_RAW_FILENAME_RE.test(input.fileName) || isSigmetRawMagic(input.bytes),
		load: () => import('./sigmet-iris').then((m) => m.sigmetIrisParser)
	},
	{
		id: 'netcdf-cfradial',
		label: 'NetCDF CfRadial/PPIVol (IDEAM Colombia)',
		canParse: (input) => hasExtension(input.fileName, '.nc') || isNetcdf3Magic(input.bytes),
		load: () => import('./netcdf-cfradial').then((m) => m.cfRadialParser)
	}
];
