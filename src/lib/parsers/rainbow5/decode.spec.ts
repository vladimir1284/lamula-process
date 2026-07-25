import { describe, it, expect } from 'vitest';
import { decodeRayAngles, decodeMoment } from './decode';

describe('decodeRayAngles', () => {
	it('decodes u16 BE raw values to degrees via raw*360/65536', () => {
		const buf = new ArrayBuffer(4);
		const view = new DataView(buf);
		view.setUint16(0, 0);
		view.setUint16(2, 32768);
		const angles = decodeRayAngles(new Uint8Array(buf), 16);
		expect(Array.from(angles)).toEqual([0, 180]);
	});

	it('rejects depths not exercised by any fixture', () => {
		expect(() => decodeRayAngles(new Uint8Array(2), 8)).toThrow(/not exercised/);
	});
});

describe('decodeMoment', () => {
	it('maps raw=0 to no-data and raw>=1 to vmin+(raw-1)*scale, depth=8', () => {
		// vmin=-31.5, vmax=95.5, depth=8 -> scale=(95.5-(-31.5))/(2**8-2)=0.5
		const data = new Uint8Array([0, 1, 2, 255]);
		const { values, flags } = decodeMoment(data, 1, 4, 8, -31.5, 95.5);
		expect(Array.from(flags)).toEqual([1, 0, 0, 0]);
		expect(values[1]).toBeCloseTo(-31.5);
		expect(values[2]).toBeCloseTo(-31.0);
		expect(values[3]).toBeCloseTo(95.5);
	});

	it('handles depth=16 the same way, u16 BE', () => {
		const buf = new ArrayBuffer(6);
		const view = new DataView(buf);
		view.setUint16(0, 0);
		view.setUint16(2, 1);
		view.setUint16(4, 65535);
		const { values, flags } = decodeMoment(new Uint8Array(buf), 1, 3, 16, 0, 360);
		expect(flags[0]).toBe(1);
		expect(values[1]).toBeCloseTo(0);
		expect(values[2]).toBeCloseTo(360);
	});

	it('rejects sub-byte depths (unverified bit-packing)', () => {
		expect(() => decodeMoment(new Uint8Array(1), 1, 1, 6, 0, 1)).toThrow(/sub-byte packing/);
	});
});
