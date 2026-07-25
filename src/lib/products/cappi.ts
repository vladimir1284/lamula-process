import type { Scan, MomentType } from '$lib/domain/types';
import { createCells, cellFlagCode, CELL_FLAG_OK } from '$lib/domain/cells';
import { beamHeightRangeM } from '$lib/geo/height';
import { toLinear, fromLinear } from './measure';

/**
 * CAPPI — Constant-Altitude PPI. Direct port of `TCAPPIScan.ProcessMove`
 * (`legacy/Units/CAPPIScan.pas`): synthesize a single ground-range polar scan by averaging,
 * across all elevation PPIs of one channel, every gate whose beam occupies the altitude slab
 * [bottomM, topM].
 *
 * Per source scan at elevation θ, for source gate R:
 *   - beam height min/max via the 4/3-earth model (`beamHeightRangeM`);
 *   - if the beam is entirely below the slab (`max ≤ bottom`) skip the gate;
 *   - if entirely above (`min ≥ top`) stop — height rises monotonically with R (legacy `break`);
 *   - otherwise deposit the cell at ground gate `round(R·cosθ)` (legacy `Radius := round(R*Cos)`)
 *     into the accumulator, summing in linear measure space and counting for the average.
 *
 * The output is a `Scan` whose gate index is *ground* range (elevation 0, so downstream
 * rendering does not re-project it) and whose azimuth rays are inherited from a reference scan.
 *
 * Azimuth alignment: like the legacy source, this assumes every elevation shares the same ray
 * (azimuth) indexing. Scans whose `numRays` differs from the reference are skipped rather than
 * silently mis-indexed; `result.skipped` reports how many.
 */

export interface CappiOptions {
	bottomM: number;
	topM: number;
	moment: MomentType;
	beamWidthDeg: number;
	siteAltM?: number;
}

export interface CappiResult {
	scan: Scan;
	skipped: number;
}

export function computeCappi(scans: Scan[], opts: CappiOptions): CappiResult {
	if (scans.length === 0) throw new Error('computeCappi: no scans');

	// Reference geometry: the ray structure of the first scan, and the widest gate count so
	// every ground gate (≤ source gate, since round(R·cosθ) ≤ R) has a home.
	const ref = scans[0];
	const numRays = ref.numRays;
	const numGates = scans.reduce((m, s) => Math.max(m, s.numGates), 0);
	const gateLengthM = ref.gateLengthM;
	const rangeToFirstGateM = ref.rangeToFirstGateM;
	const siteAltM = opts.siteAltM ?? 0;

	const sumLin = new Float64Array(numRays * numGates);
	const count = new Uint32Array(numRays * numGates);
	let skipped = 0;

	for (const s of scans) {
		if (s.numRays !== numRays) {
			skipped++;
			continue;
		}
		const cos = Math.cos((s.angleDeg * Math.PI) / 180);
		for (let r = 0; r < s.numGates; r++) {
			const slant = s.rangeToFirstGateM + r * s.gateLengthM;
			const { min, max } = beamHeightRangeM(slant, s.angleDeg, opts.beamWidthDeg, siteAltM);
			if (max <= opts.bottomM) continue;
			if (min >= opts.topM) break; // higher gates are higher still
			const groundGate = Math.round(r * cos);
			if (groundGate < 0 || groundGate >= numGates) continue;
			for (let a = 0; a < numRays; a++) {
				const srcIdx = a * s.numGates + r;
				if (s.cells.flags[srcIdx] !== CELL_FLAG_OK) continue;
				const dstIdx = a * numGates + groundGate;
				sumLin[dstIdx] += toLinear(s.cells.values[srcIdx], opts.moment);
				count[dstIdx] += 1;
			}
		}
	}

	const cells = createCells(numRays, numGates);
	const noData = cellFlagCode('no-data');
	for (let i = 0; i < cells.values.length; i++) {
		if (count[i] > 0) {
			cells.values[i] = fromLinear(sumLin[i] / count[i], opts.moment);
			cells.flags[i] = CELL_FLAG_OK;
		} else {
			cells.flags[i] = noData;
		}
	}

	const scan: Scan = {
		id: ref.id,
		angleDeg: 0, // ground-range grid: gate index already IS ground range
		rangeToFirstGateM,
		gateLengthM,
		numRays,
		numGates,
		rayStartAnglesDeg: ref.rayStartAnglesDeg.slice(),
		rayStopAnglesDeg: ref.rayStopAnglesDeg.slice(),
		cells
	};
	return { scan, skipped };
}
