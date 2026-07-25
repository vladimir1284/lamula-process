import { cellFlagCode } from '$lib/domain';
import type { MomentType } from '$lib/domain';

// dMeasure, ported from Obs_Parser.py (the format author's own 2013 reference decoder). Only codes
// actually exercised by the 4 real Camagüey fixtures are mapped to a domain MomentType -- the rest
// (unDB, ZDR, uPhiDP, RhoHV, KDP, ...) would need a conversion formula that's never been verified
// against real bytes here, so they throw rather than guess (unDB in particular needs the range-
// dependent dB2dBZ() correction from Obs_Parser.py, never exercised since no fixture uses it).
export const MEASURE_TO_MOMENT: Partial<Record<number, MomentType>> = {
	2: 'dBZ', // unDBZ
	4: 'V', // unMS (velocity)
	16: 'W' // unSW (spectrum width)
};

const NO_DATA = cellFlagCode('no-data');

// Byte->physical formulas confirmed against docs/formatos.md's verified table: dBZ = byte-80,
// velocity/spectrum-width = (byte-128)/2. raw=0 is the shared no-data sentinel across every measure
// (confirmed empirically against all 4 fixtures: it's the overwhelming majority value in every PPI,
// unlike any in-range physical byte). Obs_Parser.py additionally flips velocity's sign ("TODO speed
// sign correction" in its own comment) -- left out here since that inversion is the original author's
// own unresolved question, not a confirmed part of the format.
export function decodeCells(
	raw: Uint8Array,
	measureCode: number,
	numRays: number,
	numGates: number
): { values: Float32Array; flags: Uint8Array } {
	const n = numRays * numGates;
	const values = new Float32Array(n);
	const flags = new Uint8Array(n);

	for (let i = 0; i < n; i++) {
		const byte = raw[i];
		if (byte === 0) {
			flags[i] = NO_DATA;
			continue;
		}
		values[i] = measureCode === 2 ? byte - 80 : (byte - 128) / 2;
	}

	return { values, flags };
}
