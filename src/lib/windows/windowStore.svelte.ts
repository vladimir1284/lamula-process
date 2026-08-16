import {
	MIN_WINDOW_HEIGHT,
	MIN_WINDOW_WIDTH,
	type RadarWindow,
	type WindowPayload,
	type WindowRect,
	type WindowType
} from './windowTypes';
import type { SnapGuides } from './snap';

export interface CanvasSize {
	width: number;
	height: number;
}

/** Imperative per-window API a content wrapper can register -- kept outside `$state` since it
 * holds live object refs (an OL `Map`, a canvas), not serializable data. Used for cross-window
 * "export both panels" (a chart window reaching its source map window's live `ol/Map`) and to
 * detect a closed source (the registration is gone). Typed loosely (`unknown`) to avoid this
 * store depending on OpenLayers -- callers cast to the concrete type they registered. */
export interface WindowInstanceApi {
	getMap?: () => unknown;
	getCanvas?: () => HTMLCanvasElement | undefined;
}

let nextOpenOffset = 0;

/** Runes-module singleton: the one desktop's worth of open windows + focus/z-order. Every
 * consumer (sidebar, MenuBar's "Ventana" menu, the canvas itself) imports this directly instead
 * of relaying window state as props through `+page.svelte`. */
class WindowManagerStore {
	windows = $state<RadarWindow[]>([]);
	focusedId = $state<string | null>(null);
	/** Map window id currently armed to trace a free cross-section line -- set before any
	 * cross-section window exists so the map shows the draw interaction first; cleared once the
	 * line is completed and the chart window opens (see `MapWindow.svelte`). */
	armedCrossSection = $state<string | null>(null);
	/** Map window id currently armed to pick a vertical-profile point, before any profile window
	 * exists (mirrors `armedCrossSection`; see `MapWindow.svelte`'s `onPointSelect`). */
	armedProfile = $state<string | null>(null);
	/** Map window id currently armed to draw a stats region, before any stats window exists
	 * (mirrors `armedCrossSection`; see `MapWindow.svelte`'s `onStatsRegionSelect`). */
	armedStats = $state<string | null>(null);
	/** Live magnetic-snap guide lines for the window currently being dragged/resized; null when
	 * idle or when the current pointer position isn't within snap threshold of anything. */
	snapGuides = $state<SnapGuides | null>(null);
	private nextZ = 1;
	private instanceApis = new Map<string, WindowInstanceApi>();

	open(
		type: WindowType,
		opts: { title: string; payload: WindowPayload; rect?: Partial<WindowRect> }
	): RadarWindow {
		const offset = nextOpenOffset % 8;
		nextOpenOffset++;
		const rect: WindowRect = {
			x: 40 + offset * 32,
			y: 40 + offset * 28,
			width: 640,
			height: 480,
			...opts.rect
		};
		const w: RadarWindow = {
			id: crypto.randomUUID(),
			type,
			title: opts.title,
			rect,
			z: this.nextZ++,
			minimized: false,
			maximized: false,
			restoreRect: null,
			payload: opts.payload
		};
		this.windows.push(w);
		this.focus(w.id);
		return w;
	}

	/** Opens a window of `type` only if none exists yet; returns the existing one otherwise without
	 * focusing it -- used for auto-opening the observation-info window on load, where stealing
	 * focus from whatever the user is doing on every subsequent load would be intrusive. */
	ensureOpen(
		type: WindowType,
		opts: { title: string; payload: WindowPayload; rect?: Partial<WindowRect> }
	): RadarWindow {
		const existing = this.windows.find((w) => w.type === type);
		return existing ?? this.open(type, opts);
	}

	armCrossSection(sourceMapWindowId: string) {
		this.armedCrossSection = sourceMapWindowId;
	}

	disarmCrossSection() {
		this.armedCrossSection = null;
	}

	armProfile(sourceMapWindowId: string) {
		this.armedProfile = sourceMapWindowId;
	}

	disarmProfile() {
		this.armedProfile = null;
	}

	armStats(sourceMapWindowId: string) {
		this.armedStats = sourceMapWindowId;
	}

	disarmStats() {
		this.armedStats = null;
	}

	close(id: string) {
		this.windows = this.windows.filter((w) => w.id !== id);
		this.instanceApis.delete(id);
		if (this.focusedId === id) this.focusedId = null;
	}

	closeAll() {
		this.windows = [];
		this.instanceApis.clear();
		this.focusedId = null;
	}

	focus(id: string) {
		const w = this.find(id);
		if (!w) return;
		w.z = this.nextZ++;
		this.focusedId = id;
	}

	minimize(id: string) {
		const w = this.find(id);
		if (w) w.minimized = true;
	}

	restore(id: string) {
		const w = this.find(id);
		if (w) w.minimized = false;
		this.focus(id);
	}

	toggleMaximize(id: string, canvas: CanvasSize) {
		const w = this.find(id);
		if (!w) return;
		if (w.maximized) {
			w.rect = w.restoreRect ?? w.rect;
			w.restoreRect = null;
			w.maximized = false;
		} else {
			w.restoreRect = { ...w.rect };
			w.rect = { x: 0, y: 0, width: canvas.width, height: canvas.height };
			w.maximized = true;
		}
		this.focus(id);
	}

	move(id: string, x: number, y: number) {
		const w = this.find(id);
		if (w) {
			w.rect.x = x;
			w.rect.y = y;
		}
	}

	resize(id: string, rect: WindowRect) {
		const w = this.find(id);
		if (!w) return;
		w.rect = {
			x: rect.x,
			y: rect.y,
			width: Math.max(MIN_WINDOW_WIDTH, rect.width),
			height: Math.max(MIN_WINDOW_HEIGHT, rect.height)
		};
	}

	setSnapGuides(guides: SnapGuides | null) {
		this.snapGuides = guides;
	}

	setTitle(id: string, title: string) {
		const w = this.find(id);
		if (w) w.title = title;
	}

	setPayload(id: string, patch: Partial<WindowPayload>) {
		const w = this.find(id);
		if (w) w.payload = { ...w.payload, ...patch } as WindowPayload;
	}

	find(id: string): RadarWindow | undefined {
		return this.windows.find((w) => w.id === id);
	}

	setInstanceApi(id: string, api: WindowInstanceApi | null) {
		if (api) this.instanceApis.set(id, api);
		else this.instanceApis.delete(id);
	}

	getInstanceApi(id: string): WindowInstanceApi | undefined {
		return this.instanceApis.get(id);
	}

	/** Rearrange non-minimized windows into a staggered stack (classic MDI convention: minimized
	 * windows are untouched). */
	cascade(canvas: CanvasSize) {
		const stepX = 32;
		const stepY = 28;
		const start = 24;
		const wrapAfter = 8;
		const visible = this.windows.filter((w) => !w.minimized).sort((a, b) => a.z - b.z);
		visible.forEach((w, i) => {
			const col = i % wrapAfter;
			w.rect.x = start + col * stepX;
			w.rect.y = start + col * stepY;
			w.rect.width = Math.min(
				w.rect.width,
				Math.max(MIN_WINDOW_WIDTH, canvas.width - w.rect.x - 16)
			);
			w.rect.height = Math.min(
				w.rect.height,
				Math.max(MIN_WINDOW_HEIGHT, canvas.height - w.rect.y - 16)
			);
			w.z = this.nextZ++;
		});
	}

	/** Rearrange non-minimized windows into a roughly-square grid. */
	tile(canvas: CanvasSize) {
		const visible = this.windows.filter((w) => !w.minimized);
		const n = visible.length;
		if (n === 0) return;
		const cols = Math.ceil(Math.sqrt(n));
		const rows = Math.ceil(n / cols);
		const cellW = canvas.width / cols;
		const cellH = canvas.height / rows;
		visible.forEach((w, i) => {
			const col = i % cols;
			const row = Math.floor(i / cols);
			w.rect = { x: col * cellW, y: row * cellH, width: cellW, height: cellH };
			w.maximized = false;
			w.restoreRect = null;
		});
	}

	/** Replace live state wholesale from a persisted/imported layout snapshot. */
	hydrate(saved: { windows: RadarWindow[]; focusedId: string | null } | null) {
		if (!saved) return;
		this.windows = saved.windows;
		this.focusedId = saved.focusedId;
		this.nextZ = 1 + Math.max(0, ...saved.windows.map((w) => w.z));
	}
}

export const windowStore = new WindowManagerStore();
