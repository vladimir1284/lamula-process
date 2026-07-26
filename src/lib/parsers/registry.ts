import type { ParserDescriptor } from './types';
import { hasExtension, isGzipMagic, startsWithAscii } from './sniff';

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
	}
];
