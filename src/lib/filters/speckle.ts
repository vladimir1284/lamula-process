import type { Cells } from '$lib/domain';
import { cellFlagCode } from '$lib/domain';

const OK = cellFlagCode('ok');
const NO_DATA = cellFlagCode('no-data');

// Direct port of TObservation.RemoveRadialSpeckler (legacy/Units/Observation.pas): along each ray,
// erase runs of "signal" gates shorter than `minRunLength`, treating anything <= `lowValue` (or
// already flagged not-'ok') as background. `lowValue` is a physical-value floor -- the original
// reused the currently-selected palette's first stop (a raw TCode byte) for this; callers wanting
// exact legacy parity should convert that stop's value into this scan's physical units themselves.
export function removeRadialSpeckle(cells: Cells, lowValue: number, minRunLength: number): void {
	if (minRunLength <= 0) return; // legacy: `if umbral <> 0`

	const isBackground = (i: number): boolean => cells.flags[i] !== OK || cells.values[i] <= lowValue;

	for (let ray = 0; ray < cells.numRays; ray++) {
		const base = ray * cells.numGates;
		let r = 0;
		while (r < cells.numGates - 1) {
			if (isBackground(base + r) && !isBackground(base + r + 1)) {
				// rising edge at r+1: scan forward for the end of this run.
				let c = r;
				do {
					c++;
				} while (c < cells.numGates - 1 && c - r < minRunLength && !isBackground(base + c));

				if (c - r < minRunLength) {
					// too short: erase the whole span [r, c], including its bounding cells.
					for (let i = r; i <= c; i++) {
						cells.flags[base + i] = NO_DATA;
						cells.values[base + i] = 0;
					}
				}
				r = c;
			} else {
				r++;
			}
		}
	}
}
