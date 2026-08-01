import { isTauri } from '@tauri-apps/api/core';
import type { RadarWindow } from './windowTypes';

/**
 * Persisted window-desktop layout: which windows are open, where, and which one is focused.
 * Same web-only localStorage pattern as `platform/paletteStore.ts` -- see that file for the Tauri
 * caveat. Unlike the palette book / site data stores, import here is a full REPLACE, not a merge:
 * a layout is one coherent snapshot (positions/z-order/focus only make sense relative to each
 * other, and window ids are random per-session UUIDs with no cross-session identity to merge on).
 */

export interface WindowLayout {
	version: 1;
	windows: RadarWindow[];
	focusedId: string | null;
}

const STORAGE_KEY = 'lamula-process:window-layout';

function isWindowLayout(x: unknown): x is WindowLayout {
	return !!x && typeof x === 'object' && Array.isArray((x as WindowLayout).windows);
}

export async function loadLayout(): Promise<WindowLayout | null> {
	if (isTauri()) throw new Error('Tauri layout store not implemented yet');
	const raw = localStorage.getItem(STORAGE_KEY);
	if (!raw) return null;
	try {
		const parsed = JSON.parse(raw);
		return isWindowLayout(parsed) ? parsed : null;
	} catch {
		return null;
	}
}

export async function saveLayout(layout: WindowLayout): Promise<void> {
	if (isTauri()) throw new Error('Tauri layout store not implemented yet');
	localStorage.setItem(STORAGE_KEY, JSON.stringify(layout));
}

export async function clearLayout(): Promise<void> {
	if (isTauri()) throw new Error('Tauri layout store not implemented yet');
	localStorage.removeItem(STORAGE_KEY);
}

/** Serialize a layout for a user-triggered download. */
export function exportLayout(layout: WindowLayout): string {
	return JSON.stringify(layout, null, 2);
}

/** Parse + persist an exported layout blob, replacing whatever was stored. Caller is responsible
 * for confirming with the user before applying it over a live desktop with windows open. */
export async function importLayout(json: string): Promise<WindowLayout> {
	const incoming = JSON.parse(json);
	if (!isWindowLayout(incoming)) throw new Error('invalid layout JSON');
	await saveLayout(incoming);
	return incoming;
}
