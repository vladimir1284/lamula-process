import type { RegionStats } from './statistics';

/**
 * Report serialisation — the portable core of `legacy/Units/Report.pas`. The legacy unit had three
 * renderers (plain-text memo, RTF, and OLE-Word automation); per scope we keep only TXT and add
 * CSV, and drop RTF and Word entirely (decision in docs/alcance.md).
 *
 * Both formats share one column model, one row per region. Spanish headers, cleaned to UTF-8 (the
 * legacy source stored them as ISO-8859-1 with mojibake — `�rea`, `M�ximo`, `km�`).
 */

export interface ReportMeta {
	title?: string;
	product?: string;
	/** Observation time (ISO string), shown in the header. */
	timestamp?: string;
	/** Creation time (ISO string). */
	generatedAt?: string;
}

interface Column {
	header: string;
	get: (s: RegionStats) => number | string | null;
	decimals?: number;
}

const COLUMNS: Column[] = [
	{ header: 'Región', get: (s) => s.region },
	{ header: 'Unidad', get: (s) => s.unit },
	{ header: 'Umbral', get: (s) => s.threshold, decimals: 2 },
	{ header: 'Celdas', get: (s) => s.count },
	{ header: 'Área (km²)', get: (s) => s.areaKm2, decimals: 2 },
	{ header: 'Cobertura (%)', get: (s) => s.coatingPct, decimals: 1 },
	{ header: 'Máximo', get: (s) => s.max, decimals: 2 },
	{ header: 'Mínimo', get: (s) => s.min, decimals: 2 },
	{ header: 'Media', get: (s) => s.meanAll, decimals: 2 },
	{ header: 'Media cubierta', get: (s) => s.meanCovered, decimals: 2 },
	{ header: 'Mediana', get: (s) => s.median, decimals: 2 },
	{ header: 'Volumen (Mm³)', get: (s) => s.volumeMm3, decimals: 3 },
	{ header: 'Desv. est.', get: (s) => s.stdDev, decimals: 2 }
];

function fmt(value: number | string | null, decimals: number | undefined, nullStr: string): string {
	if (value === null) return nullStr;
	if (typeof value === 'string') return value;
	if (!isFinite(value)) return nullStr;
	return decimals === undefined ? String(value) : value.toFixed(decimals);
}

/** RFC-4180-ish CSV: quote fields containing comma/quote/newline. */
function csvField(s: string): string {
	return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export function formatReportCsv(stats: RegionStats[]): string {
	const lines: string[] = [];
	lines.push(COLUMNS.map((c) => csvField(c.header)).join(','));
	for (const s of stats) {
		lines.push(COLUMNS.map((c) => csvField(fmt(c.get(s), c.decimals, ''))).join(','));
	}
	return lines.join('\r\n') + '\r\n';
}

export function formatReportTxt(stats: RegionStats[], meta: ReportMeta = {}): string {
	const cells: string[][] = [];
	cells.push(COLUMNS.map((c) => c.header));
	for (const s of stats) cells.push(COLUMNS.map((c) => fmt(c.get(s), c.decimals, '—')));

	// column widths for alignment
	const widths = COLUMNS.map((_, i) => Math.max(...cells.map((row) => row[i].length)));
	const renderRow = (row: string[]) => row.map((v, i) => v.padStart(widths[i])).join('  ');

	const out: string[] = [];
	if (meta.title) out.push(meta.title);
	if (meta.product) out.push(`Producto: ${meta.product}`);
	if (meta.timestamp) out.push(`Observación: ${meta.timestamp}`);
	if (meta.generatedAt) out.push(`Generado: ${meta.generatedAt}`);
	if (out.length > 0) out.push('');
	out.push(renderRow(cells[0]));
	out.push(widths.map((w) => '-'.repeat(w)).join('  '));
	for (let i = 1; i < cells.length; i++) out.push(renderRow(cells[i]));
	return out.join('\n') + '\n';
}
