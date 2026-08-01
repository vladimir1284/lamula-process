import type { WindowRect } from './windowTypes';
import type { CanvasSize } from './windowStore.svelte';

/** Pixel distance within which a dragged/resized edge snaps to a target edge. */
export const SNAP_THRESHOLD = 8;

export type ResizeDir = 'n' | 's' | 'e' | 'w' | 'ne' | 'nw' | 'se' | 'sw';

export interface SnapGuides {
	vertical: number[];
	horizontal: number[];
}

interface EdgeHit {
	snapped: number;
	dist: number;
}

function collectEdges(others: WindowRect[], canvas: CanvasSize) {
	const xs = new Set<number>([0, canvas.width]);
	const ys = new Set<number>([0, canvas.height]);
	for (const r of others) {
		xs.add(r.x);
		xs.add(r.x + r.width);
		ys.add(r.y);
		ys.add(r.y + r.height);
	}
	return { xs: [...xs], ys: [...ys] };
}

function closestEdge(value: number, targets: number[], threshold: number): EdgeHit | null {
	let best: EdgeHit | null = null;
	for (const t of targets) {
		const dist = Math.abs(value - t);
		if (dist <= threshold && (!best || dist < best.dist)) best = { snapped: t, dist };
	}
	return best;
}

/** Snaps a window being moved: tries left/right edges against every x target, top/bottom
 * against every y target, and returns the (dx, dy) nudge plus the guide lines that were hit. */
export function snapMove(
	rect: WindowRect,
	others: WindowRect[],
	canvas: CanvasSize,
	threshold = SNAP_THRESHOLD
): { dx: number; dy: number; guides: SnapGuides } {
	const { xs, ys } = collectEdges(others, canvas);
	const guides: SnapGuides = { vertical: [], horizontal: [] };
	let dx = 0;
	let dy = 0;

	const left = closestEdge(rect.x, xs, threshold);
	const right = closestEdge(rect.x + rect.width, xs, threshold);
	if (left && (!right || left.dist <= right.dist)) {
		dx = left.snapped - rect.x;
		guides.vertical.push(left.snapped);
	} else if (right) {
		dx = right.snapped - (rect.x + rect.width);
		guides.vertical.push(right.snapped);
	}

	const top = closestEdge(rect.y, ys, threshold);
	const bottom = closestEdge(rect.y + rect.height, ys, threshold);
	if (top && (!bottom || top.dist <= bottom.dist)) {
		dy = top.snapped - rect.y;
		guides.horizontal.push(top.snapped);
	} else if (bottom) {
		dy = bottom.snapped - (rect.y + rect.height);
		guides.horizontal.push(bottom.snapped);
	}

	return { dx, dy, guides };
}

/** Snaps only the edge(s) a resize handle is actively moving (e.g. `dir === 'e'` only tests the
 * right edge) so a corner drag can snap independently on each axis. */
export function snapResize(
	rect: WindowRect,
	dir: ResizeDir,
	others: WindowRect[],
	canvas: CanvasSize,
	threshold = SNAP_THRESHOLD
): { rect: WindowRect; guides: SnapGuides } {
	const { xs, ys } = collectEdges(others, canvas);
	const guides: SnapGuides = { vertical: [], horizontal: [] };
	let { x, y, width, height } = rect;

	if (dir.includes('e')) {
		const hit = closestEdge(x + width, xs, threshold);
		if (hit) {
			width = hit.snapped - x;
			guides.vertical.push(hit.snapped);
		}
	}
	if (dir.includes('w')) {
		const hit = closestEdge(x, xs, threshold);
		if (hit) {
			width += x - hit.snapped;
			x = hit.snapped;
			guides.vertical.push(hit.snapped);
		}
	}
	if (dir.includes('s')) {
		const hit = closestEdge(y + height, ys, threshold);
		if (hit) {
			height = hit.snapped - y;
			guides.horizontal.push(hit.snapped);
		}
	}
	if (dir.includes('n')) {
		const hit = closestEdge(y, ys, threshold);
		if (hit) {
			height += y - hit.snapped;
			y = hit.snapped;
			guides.horizontal.push(hit.snapped);
		}
	}

	return { rect: { x, y, width, height }, guides };
}
