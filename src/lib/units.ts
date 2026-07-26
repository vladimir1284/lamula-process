/**
 * Display-only unit conversion. The app's internal data (parsed cell values, product
 * thresholds/palette stops, stored site altitudes) always stays in SI -- only the text shown to
 * the user is converted, so palette calibration and stored data never need touching.
 */

export type UnitSystem = 'metric' | 'imperial';

const KM_PER_MI = 1.609344;
const M_PER_FT = 0.3048;
const MPS_PER_MPH = 0.44704;
const MM_PER_IN = 25.4;

export function distanceUnitLabel(system: UnitSystem): string {
	return system === 'imperial' ? 'mi' : 'km';
}

export function altitudeUnitLabel(system: UnitSystem): string {
	return system === 'imperial' ? 'ft' : 'm';
}

export function speedUnitLabel(system: UnitSystem): string {
	return system === 'imperial' ? 'mph' : 'm/s';
}

export function precipUnitLabel(system: UnitSystem): string {
	return system === 'imperial' ? 'in' : 'mm';
}

/** Ground metres -> the active system's ground-distance unit (km or mi). */
export function toDisplayDistanceM(m: number, system: UnitSystem): number {
	const km = m / 1000;
	return system === 'imperial' ? km / KM_PER_MI : km;
}

/** Metres of height/altitude -> the active system's altitude unit (m or ft). */
export function toDisplayAltitudeM(m: number, system: UnitSystem): number {
	return system === 'imperial' ? m / M_PER_FT : m;
}

/** m/s -> the active system's speed unit (m/s or mph). */
export function toDisplaySpeedMs(ms: number, system: UnitSystem): number {
	return system === 'imperial' ? ms / MPS_PER_MPH : ms;
}

/** mm -> the active system's precipitation unit (mm or in). */
export function toDisplayPrecipMm(mm: number, system: UnitSystem): number {
	return system === 'imperial' ? mm / MM_PER_IN : mm;
}

export function formatDistanceM(m: number, system: UnitSystem, digits = 1): string {
	return `${toDisplayDistanceM(m, system).toFixed(digits)} ${distanceUnitLabel(system)}`;
}

export function formatAltitudeM(m: number, system: UnitSystem, digits?: number): string {
	const d = digits ?? (system === 'imperial' ? 0 : 2);
	return `${toDisplayAltitudeM(m, system).toFixed(d)} ${altitudeUnitLabel(system)}`;
}

/**
 * A moment/product readout value plus its canonical (SI) unit string (see domain/cells.ts
 * MOMENT_UNIT and products/*.ts `unit` fields) -> converted text, no space before the unit
 * (matches the existing readout formatting convention). Units the app doesn't have an imperial
 * form for (dBZ, dB, °, correlation-coefficient's '') pass through unchanged.
 */
export function formatReading(value: number, unit: string, system: UnitSystem, digits = 1): string {
	if (unit === 'm/s')
		return `${toDisplaySpeedMs(value, system).toFixed(digits)}${speedUnitLabel(system)}`;
	if (unit === 'mm')
		return `${toDisplayPrecipMm(value, system).toFixed(digits)}${precipUnitLabel(system)}`;
	return `${value.toFixed(digits)}${unit}`;
}
