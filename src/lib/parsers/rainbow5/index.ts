import type { RadarParser } from '../types';
import { parseRainbow5 } from './parse';

// Layout verified against real fixtures, see docs/formatos.md#formato-1--rainbow-50-gematronikleonardo-selex.
export const rainbow5Parser: RadarParser = {
	id: 'rainbow5',
	label: 'Rainbow 5.0 (.vol)',
	parse: (input) => parseRainbow5(input.bytes)
};
