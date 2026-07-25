import type { Palette } from './types';

/**
 * A built-in reflectivity (dBZ) color scale so the viewer has colours before the user imports or
 * edits a `.pal`. Step thresholds in dBZ (matches the domain's physical values); roughly the
 * common NWS reflectivity ramp. Not a legacy artifact — just a sensible default starting point
 * for the P1 editor.
 */
export const defaultDbzPalette: Palette = {
	name: 'dBZ (por defecto)',
	smooth: false,
	stops: [
		{ value: 5, color: [4, 233, 231], caption: '5' },
		{ value: 10, color: [1, 159, 244], caption: '10' },
		{ value: 15, color: [3, 0, 244], caption: '15' },
		{ value: 20, color: [2, 253, 2], caption: '20' },
		{ value: 25, color: [1, 197, 1], caption: '25' },
		{ value: 30, color: [0, 142, 0], caption: '30' },
		{ value: 35, color: [253, 248, 2], caption: '35' },
		{ value: 40, color: [229, 188, 0], caption: '40' },
		{ value: 45, color: [253, 149, 0], caption: '45' },
		{ value: 50, color: [253, 0, 0], caption: '50' },
		{ value: 55, color: [212, 0, 0], caption: '55' },
		{ value: 60, color: [188, 0, 0], caption: '60' },
		{ value: 65, color: [248, 0, 253], caption: '65' },
		{ value: 70, color: [152, 84, 198], caption: '70' }
	]
};
