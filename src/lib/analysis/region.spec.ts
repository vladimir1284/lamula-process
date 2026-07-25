import { describe, it, expect } from 'vitest';
import { regionContains, type Region } from './region';

describe('regionContains', () => {
	it('polygon (ray casting)', () => {
		const r: Region = {
			kind: 'polygon',
			name: 'p',
			points: [
				[0, 0],
				[0, 100],
				[100, 100],
				[100, 0]
			]
		};
		expect(regionContains(r, 50, 50)).toBe(true);
		expect(regionContains(r, 150, 50)).toBe(false);
		expect(regionContains(r, -1, 50)).toBe(false);
	});

	it('concave polygon excludes the notch', () => {
		// arrow-ish shape with a concave dent on the right
		const r: Region = {
			kind: 'polygon',
			name: 'c',
			points: [
				[0, 0],
				[0, 100],
				[100, 50],
				[0, 0]
			]
		};
		expect(regionContains(r, 10, 50)).toBe(true);
		expect(regionContains(r, 90, 90)).toBe(false);
	});

	it('rectangle inclusive of edges', () => {
		const r: Region = {
			kind: 'rectangle',
			name: 'r',
			minXM: -10,
			minYM: -10,
			maxXM: 10,
			maxYM: 10
		};
		expect(regionContains(r, 0, 0)).toBe(true);
		expect(regionContains(r, 10, 10)).toBe(true);
		expect(regionContains(r, 11, 0)).toBe(false);
	});

	it('circle by squared radius', () => {
		const r: Region = { kind: 'circle', name: 'o', cxM: 0, cyM: 0, radiusM: 100 };
		expect(regionContains(r, 60, 60)).toBe(true); // dist ~84.8
		expect(regionContains(r, 80, 80)).toBe(false); // dist ~113
	});
});
