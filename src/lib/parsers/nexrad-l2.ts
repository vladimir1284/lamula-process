import type { RadarParser } from './types';

// Layout verified against real KMLB fixtures, see docs/formatos.md#formato-2--nexrad-level-ii-archive-ii.
// parse() not implemented yet — this wires the plugin registry ahead of the decoder itself.
export const nexradL2Parser: RadarParser = {
	id: 'nexrad-l2',
	label: 'NEXRAD Level II (Archive II)',
	async parse() {
		throw new Error('nexradL2Parser.parse: not implemented yet');
	}
};
