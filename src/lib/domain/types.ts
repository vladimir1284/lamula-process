/**
 * Nesting follows docs/alcance.md P0: Observation -> Movements (PPI/RHI) -> Channels -> Scans -> Cells.
 * Populated by format parsers (Rainbow5, NEXRAD L2); shape is the common target both must produce.
 */

export interface RadarSite {
	name: string;
	code: string;
	// NEXRAD L2's message-31 stream (the only message type this app decodes so far) doesn't
	// self-describe site position -- that lives in a volume-constant block this parser doesn't
	// read yet, see src/lib/parsers/nexrad-l2/parse.ts. Rainbow5's sensorinfo always has it.
	lat?: number;
	lon?: number;
	altM?: number;
}

// Moment types seen across real fixtures (Rainbow5 + NEXRAD L2), see docs/formatos.md.
export type MomentType = 'dBZ' | 'dBuZ' | 'V' | 'W' | 'ZDR' | 'uPhiDP' | 'RhoHV' | 'KDP';

export type MovementKind = 'PPI' | 'RHI';

export interface Channel {
	id: number;
	moment: MomentType;
	// Same gap as RadarSite.lat/lon above: not present in NEXRAD L2 message-31.
	waveLengthM?: number;
	beamWidthDeg?: number;
	// Present when the source format carries calibration constants (.obs met_potential/delta_potential).
	calibration?: {
		metPotential: number;
		deltaPotential: number;
	};
	scans: Scan[];
}

// Raw sentinel meaning differs per format (0 = no-data/below-threshold in most, 1 = range-folded in NEXRAD L2);
// parsers normalize to this shared vocabulary rather than leaking format-specific raw codes into the model.
export type CellFlag = 'ok' | 'no-data' | 'below-threshold' | 'range-folded';

export interface Scan {
	id: number;
	// Elevation angle for PPI scans, azimuth angle for RHI scans.
	angleDeg: number;
	rangeToFirstGateM: number;
	// Gate size varies scan-to-scan even within one channel (e.g. Rainbow5 keeps bin count constant
	// across elevations but shortens max range at higher tilts) -- confirmed on real bandaS fixtures.
	gateLengthM: number;
	numRays: number;
	numGates: number;
	// Per-ray angle bounds (azimuth for PPI, elevation for RHI): both source formats give explicit
	// per-ray angles rather than a uniform step, so a scan-level scalar would lose real angular data.
	rayStartAnglesDeg: Float32Array;
	rayStopAnglesDeg: Float32Array;
	cells: Cells;
}

// Row-major [ray][gate] grid, kept as parallel typed arrays instead of per-cell objects.
export interface Cells {
	numRays: number;
	numGates: number;
	values: Float32Array;
	flags: Uint8Array;
}

export interface Movement {
	id: number;
	kind: MovementKind;
	channels: Channel[];
}

export interface Observation {
	id: string;
	site: RadarSite;
	timestamp: string;
	// VCP name as carried by the source format, e.g. "VCP_11", "VCP_31_Merged".
	design: string;
	movements: Movement[];
}
