import type { RadarParser } from '../types';
import { parseNexradL2 } from './parse';

// Layout verified against real KMLB fixtures, see docs/formatos.md#formato-2--nexrad-level-ii-archive-ii.
export const nexradL2Parser: RadarParser = {
	id: 'nexrad-l2',
	label: 'NEXRAD Level II (Archive II)',
	parse: (input) => parseNexradL2(input.bytes)
};
