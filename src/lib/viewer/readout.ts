import type { Scan } from '$lib/domain/types';
import { normDeg, sampleGround, type AzimuthLUT } from '$lib/render/scanSample';

/**
 * Convert a map coordinate (EPSG:3857) under the mouse into a radar readout: ground range,
 * azimuth, and the sampled cell value/flag. Pure so it can be unit-tested without a map.
 *
 * `scale` is projected-units per ground metre at the site latitude (see geo/extent.ts); the
 * projected offset from the site is divided by it to recover ground metres.
 */
export interface Readout {
	rangeM: number;
	azimuthDeg: number;
	value: number | null;
	flag: string | null;
}

export function readoutAt(
	coord3857: [number, number],
	site3857: [number, number],
	scale: number,
	scan: Scan,
	lut: AzimuthLUT
): Readout {
	const gx = (coord3857[0] - site3857[0]) / scale;
	const gy = (coord3857[1] - site3857[1]) / scale;
	const rangeM = Math.hypot(gx, gy);
	const azimuthDeg = normDeg((Math.atan2(gx, gy) * 180) / Math.PI);
	const sample = sampleGround(scan, lut, gx, gy);
	return {
		rangeM,
		azimuthDeg,
		value: sample ? sample.value : null,
		flag: sample ? sample.flag : null
	};
}
