import type { Observation } from '$lib/domain';

export interface ParseInput {
	fileName: string;
	bytes: Uint8Array;
}

export interface RadarParser {
	readonly id: string;
	readonly label: string;
	parse(input: ParseInput): Promise<Observation>;
}

// Split from RadarParser so canParse() can run without pulling in the (potentially heavy,
// dynamically-imported) parse implementation — detection must stay cheap and synchronous.
export interface ParserDescriptor {
	readonly id: string;
	readonly label: string;
	canParse(input: ParseInput): boolean;
	load(): Promise<RadarParser>;
}
