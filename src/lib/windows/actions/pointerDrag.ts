/**
 * Generic pointer-drag action shared by the window title bar (move) and the 8 resize handles.
 * Reports cumulative delta from drag-start on every `pointermove`, not delta-since-last-move, so
 * callers can clamp against the drag's original rect instead of accumulating rounding drift.
 */
export interface PointerDragCallbacks {
	onStart?: () => void;
	onMove: (totalDx: number, totalDy: number) => void;
	onEnd?: () => void;
}

export function pointerDrag(node: HTMLElement, callbacks: PointerDragCallbacks) {
	let cb = callbacks;
	let startX = 0;
	let startY = 0;
	let dragging = false;

	function onPointerDown(e: PointerEvent) {
		if (e.button !== 0) return;
		e.preventDefault();
		e.stopPropagation();
		startX = e.clientX;
		startY = e.clientY;
		dragging = true;
		node.setPointerCapture(e.pointerId);
		cb.onStart?.();
		window.addEventListener('pointermove', onPointerMove);
		window.addEventListener('pointerup', onPointerUp, { once: true });
	}

	function onPointerMove(e: PointerEvent) {
		if (!dragging) return;
		cb.onMove(e.clientX - startX, e.clientY - startY);
	}

	function onPointerUp() {
		dragging = false;
		window.removeEventListener('pointermove', onPointerMove);
		cb.onEnd?.();
	}

	node.style.touchAction = 'none';
	node.addEventListener('pointerdown', onPointerDown);

	return {
		update(newCallbacks: PointerDragCallbacks) {
			cb = newCallbacks;
		},
		destroy() {
			node.removeEventListener('pointerdown', onPointerDown);
			window.removeEventListener('pointermove', onPointerMove);
		}
	};
}
