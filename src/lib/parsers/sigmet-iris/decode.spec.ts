import { describe, it, expect } from 'vitest';
import {
	decodeBin2,
	decodeBin4,
	decodeDbz,
	decodeZdr,
	decodePhidp,
	decodeVel,
	decodeRhohv,
	decodeKdp
} from './decode';

describe('decodeBin2 / decodeBin4', () => {
	it('maps 0 -> 0deg and half-range -> 180deg', () => {
		expect(decodeBin2(0)).toBe(0);
		expect(decodeBin2(32768)).toBe(180);
		expect(decodeBin4(0)).toBe(0);
		expect(decodeBin4(2147483648)).toBe(180);
	});
});

// Expected values below are cross-checked against the real Corozal fixture's known min/max/count
// (test-fixtures/observations/ideam/sigmet-raw/COR250601000029.RAWYSAP, see
// test-fixtures/reference/ideam/sigmet_probe.py) -- not just the formula in isolation.
describe('decodeDbz', () => {
	it('raw=0 is a real -32 dBZ value, not no-data (matches fixture minimum)', () => {
		expect(decodeDbz(0)).toBe(-32);
	});
	it('raw=64 -> 0 dBZ; the formula has headroom to 95.5 (raw=255) even though this fixture never hits above 59', () => {
		expect(decodeDbz(255)).toBeCloseTo(95.5);
		expect(decodeDbz(64)).toBe(0);
	});
});

describe('decodeZdr', () => {
	it('raw=0 -> -8 dB (fixture minimum, not no-data)', () => {
		expect(decodeZdr(0)).toBe(-8);
	});
	it('raw=128 -> 0 dB', () => {
		expect(decodeZdr(128)).toBe(0);
	});
});

describe('decodePhidp', () => {
	it('raw=0 -> -0.7086614... (fixture minimum, not no-data)', () => {
		expect(decodePhidp(0)).toBeCloseTo(-0.7086614173228346);
	});
	it('raw=255 -> 180 (fixture maximum)', () => {
		expect(decodePhidp(255)).toBe(180);
	});
});

describe('decodeVel', () => {
	it('raw=0 is no-data (mask=0)', () => {
		expect(decodeVel(0, 6.6625)).toBeNull();
	});
	it('raw=1 and raw=255 hit the fixture min/max of +-6.6625 m/s at nyquist=6.6625', () => {
		expect(decodeVel(1, 6.6625)).toBeCloseTo(-6.6625, 3);
		expect(decodeVel(255, 6.6625)).toBeCloseTo(6.6625, 3);
	});
});

describe('decodeRhohv', () => {
	it('raw=0 is no-data (sqrt of a negative value)', () => {
		expect(decodeRhohv(0)).toBeNull();
	});
	it('raw=1 -> 0.0 and raw=254 -> 1.0 (fixture min/max)', () => {
		expect(decodeRhohv(1)).toBeCloseTo(0);
		expect(decodeRhohv(254)).toBeCloseTo(1.0);
	});
});

describe('decodeKdp', () => {
	it('raw=0 and raw=-1 are no-data', () => {
		expect(decodeKdp(0, 5.33)).toBeNull();
		expect(decodeKdp(-1, 5.33)).toBeNull();
	});
	it('raw=-128 is a real measured-zero, not no-data', () => {
		expect(decodeKdp(-128, 5.33)).toBe(0);
	});
	it('positive/negative raw values are sign-symmetric through the exponential formula', () => {
		const pos = decodeKdp(50, 5.33);
		const neg = decodeKdp(-50, 5.33);
		expect(pos).not.toBeNull();
		expect(neg).toBeCloseTo(-(pos as number));
	});
});
