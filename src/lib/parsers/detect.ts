import type { Observation } from '$lib/domain';
import type { ParseInput, ParserDescriptor } from './types';
import { PARSER_DESCRIPTORS } from './registry';

export function detectParsers(
	input: ParseInput,
	descriptors: readonly ParserDescriptor[] = PARSER_DESCRIPTORS
): ParserDescriptor[] {
	return descriptors.filter((d) => d.canParse(input));
}

export async function parseObservation(
	input: ParseInput,
	descriptors: readonly ParserDescriptor[] = PARSER_DESCRIPTORS
): Promise<Observation> {
	const candidates = detectParsers(input, descriptors);
	if (candidates.length === 0) {
		throw new Error(`No parser recognizes file "${input.fileName}"`);
	}

	// Extension/magic-byte sniffing can be ambiguous (e.g. bare .gz); try candidates in order
	// and surface the last failure if every match's real parser rejects the content.
	let lastError: unknown;
	for (const descriptor of candidates) {
		try {
			const parser = await descriptor.load();
			return await parser.parse(input);
		} catch (err) {
			lastError = err;
		}
	}
	throw new Error(`No parser could read file "${input.fileName}": ${String(lastError)}`);
}
