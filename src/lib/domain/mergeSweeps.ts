import type { Channel, MomentType, Observation, Scan } from './types';

/**
 * Stitches several single-sweep Observations (one elevation each, as Sigmet/IRIS RAW and
 * CfRadial/PPIVol files both are -- see parsers/sigmet-iris and parsers/netcdf-cfradial) into one
 * multi-tilt Observation, one Scan per elevation per Channel. Mirrors timespan.ts's
 * `createTimeSpan` philosophy: the first observation fixes the radar site, mismatched or
 * differently-shaped inputs are dropped and reported rather than silently ignored or thrown away.
 */

export interface MergeSweepsResult {
	observation: Observation;
	/** Inputs dropped for belonging to a different site or not being a single-sweep observation. */
	skipped: Observation[];
}

function isSingleSweep(o: Observation): boolean {
	return o.movements.length === 1 && o.movements[0].channels.every((c) => c.scans.length === 1);
}

/** Merges N single-sweep Observations of the same site into one multi-tilt Observation. Throws
 * only if every input is empty or unusable; a partial merge is reported via `skipped`, not thrown. */
export function mergeSweeps(observations: Observation[]): MergeSweepsResult {
	if (observations.length === 0) throw new Error('mergeSweeps: no observations to merge');

	const base = observations[0];
	const kept: Observation[] = [];
	const skipped: Observation[] = [];
	for (const o of observations) {
		const sameSite = o === base || o.site.code === base.site.code;
		if (sameSite && isSingleSweep(o)) kept.push(o);
		else skipped.push(o);
	}
	if (kept.length === 0) {
		throw new Error('mergeSweeps: no valid single-sweep observations for a shared site to merge');
	}

	const scansByMoment = new Map<MomentType, Scan[]>();
	const metaByMoment = new Map<MomentType, Pick<Channel, 'waveLengthM' | 'beamWidthDeg'>>();
	for (const o of kept) {
		for (const channel of o.movements[0].channels) {
			if (!scansByMoment.has(channel.moment)) {
				scansByMoment.set(channel.moment, []);
				metaByMoment.set(channel.moment, {
					waveLengthM: channel.waveLengthM,
					beamWidthDeg: channel.beamWidthDeg
				});
			}
			scansByMoment.get(channel.moment)!.push(channel.scans[0]);
		}
	}

	const channels: Channel[] = Array.from(scansByMoment.entries()).map(([moment, scans], id) => ({
		id,
		moment,
		...metaByMoment.get(moment),
		scans: [...scans].sort((a, b) => a.angleDeg - b.angleDeg).map((scan, i) => ({ ...scan, id: i }))
	}));

	const byTimeAscending = [...kept].sort(
		(a, b) => Date.parse(a.timestamp) - Date.parse(b.timestamp)
	);
	const earliest = byTimeAscending[0];

	return {
		observation: {
			id: earliest.id,
			site: earliest.site,
			timestamp: earliest.timestamp,
			design: earliest.design,
			movements: [{ id: 0, kind: earliest.movements[0].kind, channels }]
		},
		skipped
	};
}
