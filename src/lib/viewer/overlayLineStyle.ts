/**
 * Shared color helper for the "line overlays" group (range rings, azimuth radials, lat/lon grid)
 * -- one configurable color/width across all three (see `platform/settingsStore.ts`'s
 * `overlayLineColor`/`overlayLineWidthPx`), each overlay keeping its own per-kind opacity so
 * rings/radials/grid stay visually distinct at a glance.
 */

export type OverlayBaseColor = 'white' | 'black';

const RGB: Record<OverlayBaseColor, string> = {
	white: '255,255,255',
	black: '0,0,0'
};

export function overlayRgba(base: OverlayBaseColor, alpha: number): string {
	return `rgba(${RGB[base]},${alpha})`;
}

/** Label text stroke/outline: opposite of the line color so text stays legible either way. */
export function overlayOutline(base: OverlayBaseColor): OverlayBaseColor {
	return base === 'white' ? 'black' : 'white';
}
