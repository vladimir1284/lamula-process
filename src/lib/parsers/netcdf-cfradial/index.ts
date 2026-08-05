import type { RadarParser } from '../types';
import { parseCfRadial } from './parse';

// Layout verified against real IDEAM fixtures, see test-fixtures/reference/ideam/netcdf_probe.py.
export const cfRadialParser: RadarParser = {
	id: 'netcdf-cfradial',
	label: 'NetCDF CfRadial/PPIVol (IDEAM Colombia)',
	parse: (input) => parseCfRadial(input.bytes, input.fileName)
};
