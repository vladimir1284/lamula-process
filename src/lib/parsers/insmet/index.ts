import type { RadarParser } from '../types';
import { parseInsmet } from './parse';

// Layout verified against real Camagüey fixtures, see docs/formatos.md#formato-interno--obs-vesta.
export const insmetParser: RadarParser = {
	id: 'insmet',
	label: 'Vesta observation container (.obs)',
	parse: (input) => parseInsmet(input.bytes)
};
