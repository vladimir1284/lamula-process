import { describe, it, expect } from 'vitest';
import type { RegionStats } from './statistics';
import { formatReportCsv, formatReportTxt } from './report';

const stats: RegionStats[] = [
	{
		region: 'Camagüey',
		unit: 'dBZ',
		threshold: 20,
		count: 100,
		areaKm2: 6.283,
		coatingPct: 25,
		max: 55,
		min: 5,
		meanAll: 37.03,
		meanCovered: 42,
		median: 40,
		volumeMm3: 6.283,
		stdDev: 8.1
	},
	{
		region: 'Sin datos',
		unit: 'dBZ',
		threshold: 20,
		count: 0,
		areaKm2: 0,
		coatingPct: 0,
		max: null,
		min: null,
		meanAll: null,
		meanCovered: null,
		median: null,
		volumeMm3: null,
		stdDev: null
	}
];

describe('formatReportCsv', () => {
	it('has a header + one row per region', () => {
		const csv = formatReportCsv(stats);
		const rows = csv.trimEnd().split('\r\n');
		expect(rows).toHaveLength(3); // header + 2
		expect(rows[0]).toContain('Región');
		expect(rows[0]).toContain('Área (km²)');
	});

	it('renders nulls as empty fields and quotes commas', () => {
		const csv = formatReportCsv(stats);
		const rows = csv.trimEnd().split('\r\n');
		// second data row is all-null after region/unit/threshold/count/area/coating
		expect(rows[2]).toContain(',,,'); // consecutive empty null fields
	});
});

describe('formatReportTxt', () => {
	it('includes clean UTF-8 headers and meta', () => {
		const txt = formatReportTxt(stats, { title: 'Reporte', product: 'Máximos' });
		expect(txt).toContain('Reporte');
		expect(txt).toContain('Producto: Máximos');
		expect(txt).toContain('Máximo');
		expect(txt).toContain('Volumen (Mm³)');
		expect(txt).toContain('—'); // null placeholder
	});
});
