import type { CellFlag, Cells } from './types';

// Index must match this order; stored in Cells.flags as the numeric index rather than the string.
const CELL_FLAGS: readonly CellFlag[] = ['ok', 'no-data', 'below-threshold', 'range-folded'];

// Exposed so parsers filling large typed-array grids can resolve a flag to its numeric code once
// and reuse it across a tight per-gate loop, instead of paying an indexOf() per cell.
export function cellFlagCode(flag: CellFlag): number {
	return CELL_FLAGS.indexOf(flag);
}

// Reverse of cellFlagCode: numeric code -> flag string (e.g. for readouts). The 'ok' code is 0,
// which renderers compare against directly rather than stringifying every cell.
export function cellFlagFromCode(code: number): CellFlag {
	return CELL_FLAGS[code];
}

// Numeric codes hoisted for hot rasterizer loops (must match CELL_FLAGS order above).
export const CELL_FLAG_OK = 0;
export const CELL_FLAG_BELOW_THRESHOLD = 2;

export function createCells(numRays: number, numGates: number): Cells {
	return {
		numRays,
		numGates,
		values: new Float32Array(numRays * numGates),
		flags: new Uint8Array(numRays * numGates)
	};
}

export function cellIndex(cells: Cells, ray: number, gate: number): number {
	if (ray < 0 || ray >= cells.numRays || gate < 0 || gate >= cells.numGates) {
		throw new RangeError(
			`cell (${ray}, ${gate}) out of bounds for ${cells.numRays}x${cells.numGates}`
		);
	}
	return ray * cells.numGates + gate;
}

export function getCell(
	cells: Cells,
	ray: number,
	gate: number
): { value: number; flag: CellFlag } {
	const i = cellIndex(cells, ray, gate);
	return { value: cells.values[i], flag: CELL_FLAGS[cells.flags[i]] };
}

export function setCell(
	cells: Cells,
	ray: number,
	gate: number,
	value: number,
	flag: CellFlag
): void {
	const i = cellIndex(cells, ray, gate);
	cells.values[i] = value;
	cells.flags[i] = CELL_FLAGS.indexOf(flag);
}
