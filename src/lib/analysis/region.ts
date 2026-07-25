/**
 * Analysis regions — where statistics/reports are computed.
 *
 * DEVIATION (documented, decision 4): the legacy `TRegion` (`legacy/Units/Region.pas`) models a
 * region as an explicit enumerated set of grid cells loaded from a `.rgn` text file, matched by
 * exact cell-index equality. That representation is tied to a fixed product grid and does not
 * survive a rewrite cleanly. We normalise to geometric shapes (polygon / rectangle / circle) in
 * site-relative ground metres (x = east, y = north), with an inside test. A polygon can represent
 * anything the legacy cell-set did, plus it is resolution-independent.
 */

export interface PolygonRegion {
	kind: 'polygon';
	name: string;
	/** Vertices as [xEastM, yNorthM], site-relative metres. Open ring (first != last needed). */
	points: Array<[number, number]>;
}

export interface RectangleRegion {
	kind: 'rectangle';
	name: string;
	minXM: number;
	minYM: number;
	maxXM: number;
	maxYM: number;
}

export interface CircleRegion {
	kind: 'circle';
	name: string;
	cxM: number;
	cyM: number;
	radiusM: number;
}

export type Region = PolygonRegion | RectangleRegion | CircleRegion;

/** Even-odd ray-casting point-in-polygon. Points on an edge are treated as inside-ish (unstable). */
function pointInPolygon(points: Array<[number, number]>, x: number, y: number): boolean {
	let inside = false;
	const n = points.length;
	for (let i = 0, j = n - 1; i < n; j = i++) {
		const [xi, yi] = points[i];
		const [xj, yj] = points[j];
		const intersects = yi > y !== yj > y && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi;
		if (intersects) inside = !inside;
	}
	return inside;
}

export function regionContains(region: Region, xEastM: number, yNorthM: number): boolean {
	switch (region.kind) {
		case 'polygon':
			return pointInPolygon(region.points, xEastM, yNorthM);
		case 'rectangle':
			return (
				xEastM >= region.minXM &&
				xEastM <= region.maxXM &&
				yNorthM >= region.minYM &&
				yNorthM <= region.maxYM
			);
		case 'circle': {
			const dx = xEastM - region.cxM;
			const dy = yNorthM - region.cyM;
			return dx * dx + dy * dy <= region.radiusM * region.radiusM;
		}
	}
}
