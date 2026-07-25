import type { Observation, Channel, Scan, Movement } from '$lib/domain/types';

/**
 * Pure selection helpers turning an Observation + UI choices into the single Scan to render.
 * Kept free of Svelte/OpenLayers so the mapping is unit-testable.
 */

export interface ChannelRef {
	movement: Movement;
	channel: Channel;
	/** Index within the flattened channel list, for stable UI selection. */
	index: number;
}

/** Flatten every channel across movements, tagged with its movement. */
export function observationChannels(obs: Observation): ChannelRef[] {
	const out: ChannelRef[] = [];
	let index = 0;
	for (const movement of obs.movements)
		for (const channel of movement.channels) out.push({ movement, channel, index: index++ });
	return out;
}

/** Sorted, de-duplicated elevation angles available in a channel's PPI scans. */
export function listElevationsDeg(channel: Channel): number[] {
	const set = new Set(channel.scans.map((s) => s.angleDeg));
	return [...set].sort((a, b) => a - b);
}

/** The scan whose elevation is closest to the requested angle. Throws on an empty channel. */
export function pickScanByElevation(channel: Channel, elevationDeg: number): Scan {
	if (channel.scans.length === 0) throw new Error('channel has no scans');
	let best = channel.scans[0];
	let bestDiff = Math.abs(best.angleDeg - elevationDeg);
	for (const s of channel.scans) {
		const d = Math.abs(s.angleDeg - elevationDeg);
		if (d < bestDiff) {
			bestDiff = d;
			best = s;
		}
	}
	return best;
}

/** Site georeferencing is only available when the source format carried a position. */
export function hasGeoref(obs: Observation): boolean {
	return obs.site.lon !== undefined && obs.site.lat !== undefined;
}
