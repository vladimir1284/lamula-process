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
