import type { RadarParser } from '../types';
import { parseSigmetIris } from './parse';

// Layout verified against real IDEAM fixtures, see test-fixtures/reference/ideam/sigmet_probe.py.
export const sigmetIrisParser: RadarParser = {
	id: 'sigmet-iris',
	label: 'Sigmet/IRIS RAW (IDEAM Colombia)',
	parse: (input) => parseSigmetIris(input.bytes, input.fileName)
};
