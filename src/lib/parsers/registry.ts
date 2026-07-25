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
			hasExtension(input.fileName, '.ar2', '.ar2.bz2', '.gz') || isGzipMagic(input.bytes),
		load: () => import('./nexrad-l2').then((m) => m.nexradL2Parser)
	}
];
