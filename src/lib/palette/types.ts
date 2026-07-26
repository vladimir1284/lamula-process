export interface PaletteStop {
	// Raw byte/value threshold (Vesta's TCode), e.g. the .obs dBZ = byte-80 encoding.
	value: number;
	color: readonly [r: number, g: number, b: number];
	caption: string;
}

export interface Palette {
	name: string;
	// Carried straight from the file's "size look" header line (legacy/Units/Scale.pas:
	// `readln(F, fSize, byte(fLook))`) but NOT consulted by the original TScale.GetValueColor --
	// it's a step lookup regardless. Kept for fidelity/round-tripping, not used by colorForValue.
	smooth: boolean;
	stops: PaletteStop[];
}

/**
 * Palette-book assignment keys for derived ground products whose physical unit differs from any
 * raw `MomentType` (height in metres, kg/m², mm/h, m/s) -- these can't share the source channel's
 * moment palette (e.g. reflectivity's -30..85 dBZ ramp is meaningless for a 0..21000 m echo-top
 * value). `MAXS_HEIGHT` and `TOPS` both report a height in metres, so they share `'TOPS_HEIGHT'`.
 */
export type ProductPaletteKey = 'TOPS_HEIGHT' | 'VIL' | 'RAIN' | 'WIND_SPEED';
