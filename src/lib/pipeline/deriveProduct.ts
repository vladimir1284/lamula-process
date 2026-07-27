import type { Channel, Scan } from '$lib/domain/types';
import { momentUnit } from '$lib/domain';
import { pickScanByElevation } from './select';
import { computeCappi } from '$lib/products/cappi';
import { computeTops } from '$lib/products/tops';
import { computeMaxs } from '$lib/products/maxs';
import { computeVil } from '$lib/products/vil';
import { computeRainRate } from '$lib/products/rainRate';
import { computeWind } from '$lib/products/wind';

/**
 * Ground-range scalar products that render on the PPI map path (a single `Scan` + unit). Kept
 * pure and Svelte-free so the product-selection plumbing is unit-testable; the page passes the
 * result straight to `PpiMap`. Cross-section and profile are NOT here — they drive their own
 * standalone canvas panels.
 *
 * Accumulation is intentionally excluded: it needs a `TimeSpan` (multiple observations), which the
 * single-file page does not build. Use `computeAccumulate` directly with a multi-observation
 * TimeSpan once a multi-file UI exists.
 */

export type GroundProductKind =
	'PPI' | 'CAPPI' | 'TOPS' | 'MAXS_HEIGHT' | 'COLUMN_MAX' | 'VIL' | 'RAIN' | 'WIND_SPEED';

export interface DeriveOptions {
	elevationDeg: number;
	beamWidthDeg: number;
	siteAltM: number;
	cappiBottomM: number;
	cappiTopM: number;
	/** Reflectivity threshold for echo tops. */
	topsMinDbz: number;
	vilBottomM: number;
	vilTopM: number;
	vilC1: number;
	vilC2: number;
	zrA: number;
	zrB: number;
	vadMinSamples?: number;
	vadThreshVelocity?: number;
	vadNumFitTests?: number;
	vadSymmetry?: number;
}

export interface DerivedProduct {
	scan: Scan;
	unit: string;
}

export function deriveGroundProduct(
	channel: Channel,
	kind: GroundProductKind,
	opts: DeriveOptions
): DerivedProduct {
	const bw = channel.beamWidthDeg ?? opts.beamWidthDeg;
	const common = { beamWidthDeg: bw, siteAltM: opts.siteAltM };
	switch (kind) {
		case 'PPI':
			return {
				scan: pickScanByElevation(channel, opts.elevationDeg),
				unit: momentUnit(channel.moment)
			};
		case 'CAPPI': {
			const r = computeCappi(channel.scans, {
				bottomM: opts.cappiBottomM,
				topM: opts.cappiTopM,
				moment: channel.moment,
				...common
			});
			return { scan: r.scan, unit: momentUnit(channel.moment) };
		}
		case 'TOPS': {
			const r = computeTops(channel.scans, { minValue: opts.topsMinDbz, ...common });
			return { scan: r.scan, unit: r.unit };
		}
		case 'MAXS_HEIGHT': {
			const r = computeMaxs(channel.scans, { ...common, valueUnit: momentUnit(channel.moment) });
			return { scan: r.height.scan, unit: r.height.unit };
		}
		case 'COLUMN_MAX': {
			const r = computeMaxs(channel.scans, { ...common, valueUnit: momentUnit(channel.moment) });
			return { scan: r.columnMax.scan, unit: r.columnMax.unit };
		}
		case 'VIL': {
			const r = computeVil(channel.scans, {
				bottomM: opts.vilBottomM,
				topM: opts.vilTopM,
				c1: opts.vilC1,
				c2: opts.vilC2,
				...common
			});
			return { scan: r.scan, unit: r.unit };
		}
		case 'RAIN': {
			const src = pickScanByElevation(channel, opts.elevationDeg);
			const r = computeRainRate(src, { kind: 'zr', a: opts.zrA, b: opts.zrB });
			return { scan: r.scan, unit: r.unit };
		}
		case 'WIND_SPEED': {
			const src = pickScanByElevation(channel, opts.elevationDeg);
			const r = computeWind(src, {
				minSamples: opts.vadMinSamples,
				threshVelocity: opts.vadThreshVelocity,
				numFitTests: opts.vadNumFitTests,
				symmetry: opts.vadSymmetry
			});
			return { scan: r.speed.scan, unit: r.speed.unit };
		}
	}
}
