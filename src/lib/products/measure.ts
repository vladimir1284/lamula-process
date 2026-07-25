import type { MomentType } from '$lib/domain/types';

/**
 * Measure-space conversions for averaging.
 *
 * The legacy products average in *linear measure space* (`CodeLineal`/`LinealCode` in
 * `legacy/Units/Measure`), not on the stored code/physical value. For reflectivity moments
 * that means converting dB → linear Z (10^(dBZ/10)), averaging Z, then back to dB — averaging
 * dBZ arithmetically would be physically wrong. Non-reflectivity moments (velocity, spectrum
 * width, RhoHV, PhiDP, ZDR) are averaged directly.
 *
 * ZDR is itself a dB ratio; the legacy source only special-cased plain reflectivity, so we keep
 * ZDR on the identity path here and flag it — revisit if a CAPPI/average over ZDR is ever needed
 * for real.
 */

const REFLECTIVITY: ReadonlySet<MomentType> = new Set<MomentType>(['dBZ', 'dBuZ']);

export function isReflectivity(moment: MomentType): boolean {
	return REFLECTIVITY.has(moment);
}

/** Value → linear averaging space. */
export function toLinear(value: number, moment: MomentType): number {
	return isReflectivity(moment) ? Math.pow(10, value / 10) : value;
}

/** Linear averaging space → value. */
export function fromLinear(lin: number, moment: MomentType): number {
	return isReflectivity(moment) ? 10 * Math.log10(lin) : lin;
}
