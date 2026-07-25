import type { Scan } from '$lib/domain/types';
import { createCells, cellFlagCode } from '$lib/domain/cells';
import { nearestRayByAzimuth } from './crossSection';

/**
 * Reconstruct a real RHI (Range-Height Indicator) Scan from a PPI volume at a fixed azimuth.
 *
 * No input format this app reads carries a native RHI sweep (all three parsers only produce
 * volume PPI — many elevation sweeps, each a full azimuth turn). A pseudo-RHI is the standard
 * derivation: hold azimuth fixed and take one ray — the ray nearest that azimuth — from every
 * elevation sweep, stacking them into a single elevation-swept Scan the RHI rasterizer already
 * understands (see render/rasterizeRHI.ts: rays are elevation bounds, angleDeg is the azimuth).
 *
 * Vertical resolution is limited by the number of tilts in the volume (typically 5-14), so the
 * result is coarser than a native RHI and shows gaps between beams — inherent to volume-derived
 * RHI, the same caveat the cross-section path documents.
 *
 * Gate geometry varies sweep-to-sweep (Rainbow5 shortens max range at higher tilts), but the RHI
 * rasterizer assumes a single shared gate grid. So each picked ray is resampled by slant range
 * onto a common grid: the finest gate length seen and the longest max range across the sweeps.
 */
export function volumeToRhiScan(scans: Scan[], azimuthDeg: number): Scan | null {
	if (scans.length === 0) return null;

	// Sweeps sorted low-to-high elevation so RHI rays run bottom (row) to top.
	const sweeps = [...scans].sort((a, b) => a.angleDeg - b.angleDeg);
	const numRays = sweeps.length;

	// Common range grid: finest gate length, nearest first-gate, longest reach across sweeps.
	let gateLengthM = Infinity;
	let rangeToFirstGateM = Infinity;
	let maxRangeM = 0;
	for (const s of sweeps) {
		if (s.gateLengthM < gateLengthM) gateLengthM = s.gateLengthM;
		if (s.rangeToFirstGateM < rangeToFirstGateM) rangeToFirstGateM = s.rangeToFirstGateM;
		const reach = s.rangeToFirstGateM + (s.numGates - 1) * s.gateLengthM;
		if (reach > maxRangeM) maxRangeM = reach;
	}
	const numGates = Math.max(1, Math.round((maxRangeM - rangeToFirstGateM) / gateLengthM) + 1);

	const cells = createCells(numRays, numGates);
	// createCells zero-fills flags = 'ok'; uncovered gates must read as no-data, not a real 0-value.
	cells.flags.fill(cellFlagCode('no-data'));
	const rayStartAnglesDeg = new Float32Array(numRays);
	const rayStopAnglesDeg = new Float32Array(numRays);

	let az = azimuthDeg % 360;
	if (az < 0) az += 360;

	for (let r = 0; r < numRays; r++) {
		const src = sweeps[r];
		// Ray bounds are elevation bounds (rasterizeRHI reads their mean as the beam elevation).
		rayStartAnglesDeg[r] = src.angleDeg;
		rayStopAnglesDeg[r] = src.angleDeg;

		// Nearest azimuth ray in this sweep (circular distance handles the 0/360 seam).
		const azCenters = new Float64Array(src.numRays);
		for (let i = 0; i < src.numRays; i++) {
			let c = (src.rayStartAnglesDeg[i] + src.rayStopAnglesDeg[i]) / 2;
			c = ((c % 360) + 360) % 360;
			azCenters[i] = c;
		}
		const srcRay = nearestRayByAzimuth(azCenters, az);

		for (let g = 0; g < numGates; g++) {
			const slant = rangeToFirstGateM + g * gateLengthM;
			const srcGate = Math.round((slant - src.rangeToFirstGateM) / src.gateLengthM);
			if (srcGate < 0 || srcGate >= src.numGates) continue; // beyond this sweep's reach: stays no-data
			const srcIdx = srcRay * src.numGates + srcGate;
			const dstIdx = r * numGates + g;
			cells.values[dstIdx] = src.cells.values[srcIdx];
			cells.flags[dstIdx] = src.cells.flags[srcIdx];
		}
	}

	return {
		id: 0,
		angleDeg: az,
		rangeToFirstGateM,
		gateLengthM,
		numRays,
		numGates,
		rayStartAnglesDeg,
		rayStopAnglesDeg,
		cells
	};
}
