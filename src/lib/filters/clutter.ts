import type { Cells } from '$lib/domain';
import { cellFlagCode } from '$lib/domain';

const NO_DATA = cellFlagCode('no-data');

// Direct port of TObservation.Sup (legacy/Units/Observation.pas): elementwise-multiplies cell
// values by a same-shaped clutter-map "template" grid loaded from a Template<design>.OBS file
// (0 = permanent ground clutter, suppress; 1 = pass through -- the original works on raw TCode
// bytes with a plain `*`, which only stays in range for a binary mask). A mask value of exactly 0
// also marks the cell 'no-data', mirroring how raw=0 is the shared no-data sentinel in the legacy
// encoding; any other multiplier only scales the value (not independently verified -- no real
// non-binary template was available to check against).
//
// Preserves a real off-by-one in the original: `for N:=1 to count-1` never reaches the last cell
// of the flat array, so this loop stops at length-1 too rather than "fixing" it.
//
// Loading an actual Template<design>.OBS file isn't implemented here -- that requires a `.obs`
// reader, which is outside Rainbow5/NEXRAD L2's P0 parser scope (see docs/formatos.md). This is
// the masking primitive only; wiring it to a real template file is separate follow-up work.
export function suppressClutter(cells: Cells, mask: ArrayLike<number>): void {
	if (mask.length !== cells.values.length) {
		throw new Error(
			`clutter mask length ${mask.length} does not match cell count ${cells.values.length}`
		);
	}
	for (let i = 0; i < cells.values.length - 1; i++) {
		if (mask[i] === 0) {
			cells.values[i] = 0;
			cells.flags[i] = NO_DATA;
		} else {
			cells.values[i] *= mask[i];
		}
	}
}
