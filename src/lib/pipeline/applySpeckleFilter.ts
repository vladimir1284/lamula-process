import type { ChannelRef } from './select';
import type { Cells } from '$lib/domain/types';
import type { PaletteBook } from '$lib/platform';
import { paletteForMoment } from '$lib/platform';
import { removeRadialSpeckle } from '$lib/filters';

function cloneCells(cells: Cells): Cells {
	return {
		numRays: cells.numRays,
		numGates: cells.numGates,
		values: cells.values.slice(),
		flags: cells.flags.slice()
	};
}

/**
 * Applies legacy's radial-speckle despeckle filter (`filters/speckle.ts`, a port of
 * `TObservation.RemoveRadialSpeckler`) to a CLONE of every scan's cells -- the source
 * `ChannelRef[]`/`Observation` is never mutated, so toggling the setting off always recovers the
 * original data.
 *
 * `distanceM` is legacy's user-facing unit (`Radial_Speckle`, metres); the ported filter works in
 * gate counts, so it's converted per scan using that scan's own gate spacing (gate spacing varies
 * scan-to-scan even within one channel, see `Scan.gateLengthM`'s doc comment).
 *
 * The background floor (`lowValue`) is each moment's own assigned palette's lowest stop, matching
 * legacy's behavior of reusing "the currently-selected palette's first stop" (see
 * `filters/speckle.ts`'s `removeRadialSpeckle` doc) -- there is no separate user-facing setting
 * for it, same as legacy.
 */
export function applySpeckleFilter(
	channels: ChannelRef[],
	book: PaletteBook,
	distanceM: number
): ChannelRef[] {
	if (distanceM <= 0) return channels;
	return channels.map((ref) => {
		const lowValue = paletteForMoment(book, ref.channel.moment).stops[0]?.value ?? -Infinity;
		const scans = ref.channel.scans.map((scan) => {
			const cells = cloneCells(scan.cells);
			const minRunLength = Math.max(1, Math.round(distanceM / scan.gateLengthM));
			removeRadialSpeckle(cells, lowValue, minRunLength);
			return { ...scan, cells };
		});
		return { ...ref, channel: { ...ref.channel, scans } };
	});
}
