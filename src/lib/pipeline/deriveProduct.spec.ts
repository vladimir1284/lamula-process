import { describe, it, expect } from 'vitest';
import type { Channel } from '$lib/domain/types';
import { makeScan } from '$lib/render/scanFixtures';
import {
	deriveGroundProduct,
	deriveOptionsFromMapPayload,
	type GroundProductKind,
	type DeriveOptions,
	type MapPayloadDeriveFields
} from './deriveProduct';

const channel: Channel = {
	id: 0,
	moment: 'dBZ',
	beamWidthDeg: 1,
	scans: [0.5, 1.5, 2.5].map((elev) =>
		makeScan({ numRays: 16, numGates: 5, gateLengthM: 1000, angleDeg: elev, fill: () => 30 })
	)
};

const OPTS: DeriveOptions = {
	elevationDeg: 0.5,
	beamWidthDeg: 1,
	siteAltM: 0,
	cappiBottomM: 1000,
	cappiTopM: 3000,
	topsMinDbz: 18,
	vilBottomM: 0,
	vilTopM: 15000,
	vilC1: 0.00524,
	vilC2: 0.57143,
	zrA: 300,
	zrB: 1.4
};

describe('deriveGroundProduct', () => {
	const cases: Array<[GroundProductKind, string]> = [
		['PPI', 'dBZ'],
		['CAPPI', 'dBZ'],
		['TOPS', 'm'],
		['MAXS_HEIGHT', 'm'],
		['COLUMN_MAX', 'dBZ'],
		['VIL', 'kg/m²'],
		['RAIN', 'mm/h'],
		['WIND_SPEED', 'm/s']
	];

	for (const [kind, unit] of cases) {
		it(`${kind} returns a scan with unit ${unit}`, () => {
			const r = deriveGroundProduct(channel, kind, OPTS);
			expect(r.unit).toBe(unit);
			expect(r.scan.numRays).toBe(16);
			expect(r.scan.numGates).toBeGreaterThan(0);
		});
	}

	it('column products collapse to a ground-range scan (elevation 0)', () => {
		expect(deriveGroundProduct(channel, 'VIL', OPTS).scan.angleDeg).toBe(0);
		expect(deriveGroundProduct(channel, 'TOPS', OPTS).scan.angleDeg).toBe(0);
	});
});

describe('deriveOptionsFromMapPayload', () => {
	const payload: MapPayloadDeriveFields = {
		elevationDeg: 0.5,
		cappiBottomKm: 1,
		cappiTopKm: 3,
		topsMinDbz: 18,
		vilBottomKm: 0,
		vilTopKm: 15,
		vilC1: 0.00524,
		vilC2: 0.57143,
		zrA: 300,
		zrB: 1.4
	};

	it('maps km fields to metres and passes beamWidthDeg/siteAltM through', () => {
		expect(deriveOptionsFromMapPayload(payload, 1.2, 500)).toEqual({
			elevationDeg: 0.5,
			beamWidthDeg: 1.2,
			siteAltM: 500,
			cappiBottomM: 1000,
			cappiTopM: 3000,
			topsMinDbz: 18,
			vilBottomM: 0,
			vilTopM: 15000,
			vilC1: 0.00524,
			vilC2: 0.57143,
			zrA: 300,
			zrB: 1.4
		});
	});
});
