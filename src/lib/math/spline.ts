/**
 * Natural cubic spline — the interpolation the legacy vertical profile uses (`utMath.Spline`/
 * `SplInt`, called from `legacy/Units/ProfileVector.pas`). Standard Numerical-Recipes tridiagonal
 * solve for the second derivatives, then per-segment cubic evaluation. "Natural" = zero second
 * derivative at both ends.
 *
 * Points must be strictly increasing in x. Evaluation clamps to the endpoints outside the range
 * (the legacy profile fills flat below the lowest sample).
 */

export interface Spline {
	xs: Float64Array;
	ys: Float64Array;
	/** Second derivatives at the knots. */
	y2: Float64Array;
}

export function buildSpline(xs: number[] | Float64Array, ys: number[] | Float64Array): Spline {
	const n = xs.length;
	if (n !== ys.length) throw new Error('buildSpline: xs/ys length mismatch');
	const x = Float64Array.from(xs);
	const y = Float64Array.from(ys);
	const y2 = new Float64Array(n);
	if (n < 3) return { xs: x, ys: y, y2 }; // a line (or point) needs no curvature
	const u = new Float64Array(n);
	// natural lower boundary
	y2[0] = 0;
	u[0] = 0;
	for (let i = 1; i < n - 1; i++) {
		const sig = (x[i] - x[i - 1]) / (x[i + 1] - x[i - 1]);
		const p = sig * y2[i - 1] + 2;
		y2[i] = (sig - 1) / p;
		u[i] =
			(y[i + 1] - y[i]) / (x[i + 1] - x[i]) - (y[i] - y[i - 1]) / (x[i] - x[i - 1]);
		u[i] = (6 * u[i] / (x[i + 1] - x[i - 1]) - sig * u[i - 1]) / p;
	}
	// natural upper boundary
	y2[n - 1] = 0;
	for (let k = n - 2; k >= 0; k--) y2[k] = y2[k] * y2[k + 1] + u[k];
	return { xs: x, ys: y, y2 };
}

export function evalSpline(s: Spline, xq: number): number {
	const { xs, ys, y2 } = s;
	const n = xs.length;
	if (n === 0) return NaN;
	if (n === 1) return ys[0];
	if (xq <= xs[0]) return ys[0];
	if (xq >= xs[n - 1]) return ys[n - 1];
	// binary search for the bracketing interval
	let lo = 0;
	let hi = n - 1;
	while (hi - lo > 1) {
		const mid = (hi + lo) >> 1;
		if (xs[mid] > xq) hi = mid;
		else lo = mid;
	}
	const h = xs[hi] - xs[lo];
	if (h === 0) return ys[lo];
	const a = (xs[hi] - xq) / h;
	const b = (xq - xs[lo]) / h;
	return (
		a * ys[lo] +
		b * ys[hi] +
		((a * a * a - a) * y2[lo] + (b * b * b - b) * y2[hi]) * (h * h) / 6
	);
}
