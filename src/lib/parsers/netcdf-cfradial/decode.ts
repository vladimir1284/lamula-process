// Ray-geometry helpers for CfRadial: unlike Rainbow5/Sigmet-IRIS (which both carry explicit
// per-ray start/stop angles), CfRadial only gives one azimuth per ray (the beam center) --
// start/stop have to be derived by bisecting to each ray's neighbors. Confirmed necessary against
// the real fixture (test-fixtures/observations/ideam/netcdf-ppivol): without derived start/stop,
// adjacent-ray wedges would have zero angular width and the sweep wouldn't render at all.

/** Shortest-arc midpoint between two azimuths (degrees, wraps correctly across 0/360). */
function angularMidpoint(a: number, b: number): number {
	let diff = b - a;
	if (diff > 180) diff -= 360;
	if (diff < -180) diff += 360;
	let mid = a + diff / 2;
	if (mid < 0) mid += 360;
	if (mid >= 360) mid -= 360;
	return mid;
}

/** Mirrors the angular step from `from` to `via` past `via`, for extrapolating a virtual
 * neighbor at the first/last ray (which has no real neighbor on one side). */
function extrapolate(from: number, via: number): number {
	let step = via - from;
	if (step > 180) step -= 360;
	if (step < -180) step += 360;
	let out = via + step;
	if (out < 0) out += 360;
	if (out >= 360) out -= 360;
	return out;
}

/** Derives per-ray start/stop angles from ray-center azimuths by bisecting to each neighbor. */
export function rayCenterToStartStop(azimuthsDeg: Float32Array): {
	start: Float32Array;
	stop: Float32Array;
} {
	const n = azimuthsDeg.length;
	const start = new Float32Array(n);
	const stop = new Float32Array(n);
	for (let i = 0; i < n; i++) {
		const prev = i > 0 ? azimuthsDeg[i - 1] : extrapolate(azimuthsDeg[1], azimuthsDeg[0]);
		const next =
			i < n - 1 ? azimuthsDeg[i + 1] : extrapolate(azimuthsDeg[n - 2], azimuthsDeg[n - 1]);
		start[i] = angularMidpoint(prev, azimuthsDeg[i]);
		stop[i] = angularMidpoint(azimuthsDeg[i], next);
	}
	return { start, stop };
}
