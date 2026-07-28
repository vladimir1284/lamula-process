import { cellFlagCode } from '$lib/domain';
import type { MomentType } from '$lib/domain';

// dMeasure, ported from Obs_Parser.py (the format author's own 2013 reference decoder). Only codes
// actually exercised by real fixtures are mapped to a domain MomentType -- the rest (ZDR, uPhiDP,
// RhoHV, KDP, ...) would need a conversion formula that's never been verified against real bytes
// here, so they throw rather than guess.
export const MEASURE_TO_MOMENT: Partial<Record<number, MomentType>> = {
	1: 'dBZ', // unDB (uncorrected reflectivity, needs dB2dBZ() range correction below)
	2: 'dBZ', // unDBZ
	4: 'V', // unMS (velocity)
	16: 'W' // unSW (spectrum width)
};

const NO_DATA = cellFlagCode('no-data');

export interface UnDbCalibration {
	cellLengthM: number;
	metPotential: number;
}

// Byte->physical formulas confirmed against docs/formatos.md's verified table: dBZ (unDBZ) =
// byte-80, velocity/spectrum-width = (byte-128)/2. unDB is uncorrected reflectivity: ported from
// Obs_Parser.py's dB2dBZ(), which the original author's own code never applies inline (only
// unDBZ/unMS/unSW get their byte->value conversion in the parser loop -- unDB stays raw until
// dB2dBZ() runs), verified against the older single-channel p15g1530.obs fixture (2007 rdPilon,
// no fixture with unDBZ or batch channels uses unDB). Formula: dBZ = byte + met_potential +
// max(0, 20*log10(range_km)), range_km computed per-gate from the channel's cell_length_m
// (1-indexed: first gate is one cell_length from the antenna, matching Obs_Parser.py's
// linspace(cellLength, ncell*cellLength, ncell)). raw=0 is the shared no-data sentinel across
// every measure (confirmed empirically: it's the overwhelming majority value in every PPI, unlike
// any in-range physical byte). Obs_Parser.py additionally flips velocity's sign ("TODO speed sign
// correction" in its own comment) -- left out here since that inversion is the original author's
// own unresolved question, not a confirmed part of the format.
export function decodeCells(
	raw: Uint8Array,
	measureCode: number,
	numRays: number,
	numGates: number,
	unDbCalibration?: UnDbCalibration
): { values: Float32Array; flags: Uint8Array } {
	const n = numRays * numGates;
	const values = new Float32Array(n);
	const flags = new Uint8Array(n);

	let gateCorrectionDb: Float32Array | undefined;
	if (measureCode === 1) {
		if (!unDbCalibration) throw new Error('.obs unDB measure requires channel calibration');
		const cellLengthKm = unDbCalibration.cellLengthM / 1000;
		gateCorrectionDb = new Float32Array(numGates);
		for (let g = 0; g < numGates; g++) {
			gateCorrectionDb[g] = Math.max(0, 20 * Math.log10(cellLengthKm * (g + 1)));
		}
	}

	for (let i = 0; i < n; i++) {
		const byte = raw[i];
		if (byte === 0) {
			flags[i] = NO_DATA;
			continue;
		}
		if (measureCode === 2) {
			values[i] = byte - 80;
		} else if (measureCode === 1) {
			const g = i % numGates;
			values[i] = byte + unDbCalibration!.metPotential + gateCorrectionDb![g];
		} else {
			values[i] = (byte - 128) / 2;
		}
	}

	return { values, flags };
}
