import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { Scan } from '$lib/domain';
import { parseNexradL2 } from './parse';

const FIXTURE = fileURLToPath(
	new URL(
		'../../../../test-fixtures/observations/nexrad-l2/KMLB20121026_121212_V06.gz',
		import.meta.url
	)
);

// Ground truth below comes straight from running test-fixtures/reference/nexrad-l2/l2_probe_py3.py
// against this exact fixture (see its module docstring / docs/formatos.md), which reports stats
// for the FIRST message-31 radial found (elevation_number=1, azimuth_number=1 -- ray 0 of that
// moment's first Scan) and the first radial carrying DVEL (elevation_number=2, azimuth_number=1).
function rayStats(scan: Scan, ray: number) {
	const { values, flags, numGates } = scan.cells;
	let count = 0;
	let min = Infinity;
	let max = -Infinity;
	for (let g = 0; g < numGates; g++) {
		const i = ray * numGates + g;
		if (flags[i] !== 0) continue;
		count++;
		if (values[i] < min) min = values[i];
		if (values[i] > max) max = values[i];
	}
	return { count, min, max };
}

function channel(obs: Awaited<ReturnType<typeof parseNexradL2>>, moment: string) {
	const found = obs.movements[0].channels.find((c) => c.moment === moment);
	if (!found) throw new Error(`no ${moment} channel decoded`);
	return found;
}

describe('parseNexradL2 (real KMLB Archive II fixture)', () => {
	it('decodes the volume header into site/timestamp/design', async () => {
		const obs = await parseNexradL2(new Uint8Array(readFileSync(FIXTURE)));

		expect(obs.site.code).toBe('KMLB');
		expect(obs.design).toBe('AR2V0006.157');
		expect(obs.timestamp).toBe('2012-10-26T12:12:14.000Z');
		expect(obs.movements).toHaveLength(1);
		expect(obs.movements[0].kind).toBe('PPI');
	});

	it('decodes the first radial (elev=1 az=1, dual-pol surveillance-only cut)', async () => {
		const obs = await parseNexradL2(new Uint8Array(readFileSync(FIXTURE)));

		const ref = channel(obs, 'dBZ').scans[0];
		expect(ref.angleDeg).toBeCloseTo(0.2527, 3);
		expect(ref.numGates).toBe(1832);
		expect(ref.rayStartAnglesDeg[0]).toBeCloseTo(243.218, 2);
		const refStats = rayStats(ref, 0);
		expect(refStats.count).toBe(229);
		expect(refStats.min).toBeCloseTo(-12.0);
		expect(refStats.max).toBeCloseTo(29.0);

		const zdr = channel(obs, 'ZDR').scans[0];
		expect(zdr.numGates).toBe(1192);
		const zdrStats = rayStats(zdr, 0);
		expect(zdrStats.count).toBe(201);
		expect(zdrStats.min).toBeCloseTo(-7.875);
		expect(zdrStats.max).toBeCloseTo(7.9375);

		const phi = channel(obs, 'uPhiDP').scans[0];
		const phiStats = rayStats(phi, 0);
		expect(phiStats.count).toBe(201);
		expect(phiStats.min).toBeCloseTo(0.35, 1);
		expect(phiStats.max).toBeCloseTo(357.2, 1);

		const rho = channel(obs, 'RhoHV').scans[0];
		const rhoStats = rayStats(rho, 0);
		expect(rhoStats.count).toBe(201);
		expect(rhoStats.min).toBeCloseTo(0.208, 2);
		expect(rhoStats.max).toBeCloseTo(1.052, 2);
	});

	it('decodes the first Doppler radial (elev=2 az=1)', async () => {
		const obs = await parseNexradL2(new Uint8Array(readFileSync(FIXTURE)));

		const ref = channel(obs, 'dBZ').scans[1];
		expect(ref.angleDeg).toBeCloseTo(0.4834, 3);
		expect(ref.numGates).toBe(1192);
		expect(ref.rayStartAnglesDeg[0]).toBeCloseTo(260.219, 2);
		const refStats = rayStats(ref, 0);
		expect(refStats.count).toBe(204);
		expect(refStats.min).toBeCloseTo(-20.0);
		expect(refStats.max).toBeCloseTo(26.5);

		const vel = channel(obs, 'V').scans[0];
		expect(vel.numGates).toBe(1192);
		const velStats = rayStats(vel, 0);
		expect(velStats.count).toBe(161);
		expect(velStats.min).toBeCloseTo(-26.5);
		expect(velStats.max).toBeCloseTo(28.5);

		const sw = channel(obs, 'W').scans[0];
		const swStats = rayStats(sw, 0);
		expect(swStats.count).toBe(204);
		expect(swStats.min).toBeCloseTo(0.0);
		expect(swStats.max).toBeCloseTo(16.5);
	});
});
