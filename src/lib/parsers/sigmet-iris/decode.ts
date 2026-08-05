// Sigmet/IRIS RAW per-gate decode formulas, ported from xradar's iris.py backend (the oracle for
// this format -- no legacy Delphi source, same situation Rainbow5 was in). Every formula/mask here
// is taken from xradar's SIGMET_DATA_TYPES table entry for that code and cross-checked against the
// real fixture's known min/max/count (test-fixtures/observations/ideam/sigmet-raw), not guessed
// from the IRIS ICD alone.

/** BIN2 angle code (uint16) -> degrees. See IRIS ICD 4.2 p.23. */
export function decodeBin2(raw: number): number {
	return (360 * raw) / 65536;
}

/** BIN4 angle code (uint32) -> degrees. */
export function decodeBin4(raw: number): number {
	return (360 * raw) / 4294967296;
}

// DB_DBZ (code 2, 1 byte): no mask -- every code 0..255 is a real value, decode_array(scale=2,
// offset=-64). raw=0 -> -32 dBZ, confirmed as the fixture's real minimum (not a no-data sentinel).
export function decodeDbz(raw: number): number {
	return (raw - 64) / 2;
}

// DB_ZDR (code 5, 1 byte): no mask, decode_array(scale=16, offset=-128). Same "no sentinel" shape
// as DBZ -- raw=0 -> -8 dB, confirmed fixture minimum.
export function decodeZdr(raw: number): number {
	return (raw - 128) / 16;
}

// DB_PHIDP (code 16, 1 byte): decode_phidp = 180 * decode_array(scale=254, offset=-1). No mask;
// raw=0 legitimately decodes to a small negative edge value (-0.7086...), confirmed in the fixture.
export function decodePhidp(raw: number): number {
	return (180 * (raw - 1)) / 254;
}

// DB_VEL (code 3, 1 byte): decode_vel = decode_array(scale=127, offset=-128, mask=0) * nyquist.
// mask=0 means raw===0 is the no-data sentinel here (unlike DBZ/ZDR/PHIDP above).
export function decodeVel(raw: number, nyquistMs: number): number | null {
	if (raw === 0) return null;
	return ((raw - 128) / 127) * nyquistMs;
}

// DB_RHOHV (code 19, 1 byte): decode_sqi = sqrt(decode_array(scale=253, offset=-1)). raw=0 makes
// the sqrt argument negative -- NaN in numpy, no-data here. Confirmed: fixture's RHOHV valid count
// is well below the full gate count, unlike DBZ/ZDR/PHIDP.
export function decodeRhohv(raw: number): number | null {
	const inner = (raw - 1) / 253;
	return inner < 0 ? null : Math.sqrt(inner);
}

// DB_KDP (code 14, 1 byte, SIGNED int8 -128..127): decode_kdp's own three-way split --
// raw 0 or -1 -> no-data, raw -128 -> exactly 0 (a real "measured zero" sentinel, not no-data),
// everything else through the exponential IRIS KDP formula (ICD 4.4.20 p.77). wavelengthCm is the
// task's radar wavelength in cm (task_misc_info.wavelength / 100).
export function decodeKdp(raw: number, wavelengthCm: number): number | null {
	if (raw === 0 || raw === -1) return null;
	if (raw === -128) return 0;
	return (-0.25 * Math.sign(raw) * Math.pow(600, (127 - Math.abs(raw)) / 126)) / wavelengthCm;
}
