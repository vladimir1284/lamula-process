import { get } from 'svelte/store';
import { _ } from '$lib/i18n';
import type { RegionStats } from './statistics';

/**
 * Report serialisation — the portable core of `legacy/Units/Report.pas`. The legacy unit had three
 * renderers (plain-text memo, RTF, and OLE-Word automation); per scope we keep only TXT and add
 * CSV, and drop RTF and Word entirely (decision in docs/alcance.md).
 *
 * Both formats share one column model, one row per region. Headers follow the active i18n locale
 * (see src/lib/i18n/locales/*.json `analysisReport.*`) -- read via `get(_)` since this runs outside
 * any component lifecycle, on demand when the user exports a report.
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

function columns(t: (key: string) => string): Column[] {
	return [
		{ header: t('analysisReport.region'), get: (s) => s.region },
		{ header: t('analysisReport.unit'), get: (s) => s.unit },
		{ header: t('analysisReport.threshold'), get: (s) => s.threshold, decimals: 2 },
		{ header: t('analysisReport.cells'), get: (s) => s.count },
		{ header: t('analysisReport.areaKm2'), get: (s) => s.areaKm2, decimals: 2 },
		{ header: t('analysisReport.coveragePct'), get: (s) => s.coatingPct, decimals: 1 },
		{ header: t('analysisReport.max'), get: (s) => s.max, decimals: 2 },
		{ header: t('analysisReport.min'), get: (s) => s.min, decimals: 2 },
		{ header: t('analysisReport.mean'), get: (s) => s.meanAll, decimals: 2 },
		{ header: t('analysisReport.meanCovered'), get: (s) => s.meanCovered, decimals: 2 },
		{ header: t('analysisReport.median'), get: (s) => s.median, decimals: 2 },
		{ header: t('analysisReport.volumeMm3'), get: (s) => s.volumeMm3, decimals: 3 },
		{ header: t('analysisReport.stdDev'), get: (s) => s.stdDev, decimals: 2 }
	];
}

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
	const t = get(_);
	const cols = columns(t);
	const lines: string[] = [];
	lines.push(cols.map((c) => csvField(c.header)).join(','));
	for (const s of stats) {
		lines.push(cols.map((c) => csvField(fmt(c.get(s), c.decimals, ''))).join(','));
	}
	return lines.join('\r\n') + '\r\n';
}

export function formatReportTxt(stats: RegionStats[], meta: ReportMeta = {}): string {
	const t = get(_);
	const cols = columns(t);
	const cells: string[][] = [];
	cells.push(cols.map((c) => c.header));
	for (const s of stats) cells.push(cols.map((c) => fmt(c.get(s), c.decimals, '—')));

	// column widths for alignment
	const widths = cols.map((_col, i) => Math.max(...cells.map((row) => row[i].length)));
	const renderRow = (row: string[]) => row.map((v, i) => v.padStart(widths[i])).join('  ');

	const out: string[] = [];
	if (meta.title) out.push(meta.title);
	if (meta.product) out.push(t('analysisReport.product', { values: { value: meta.product } }));
	if (meta.timestamp)
		out.push(t('analysisReport.observation', { values: { value: meta.timestamp } }));
	if (meta.generatedAt)
		out.push(t('analysisReport.generatedAt', { values: { value: meta.generatedAt } }));
	if (out.length > 0) out.push('');
	out.push(renderRow(cells[0]));
	out.push(widths.map((w) => '-'.repeat(w)).join('  '));
	for (let i = 1; i < cells.length; i++) out.push(renderRow(cells[i]));
	return out.join('\n') + '\n';
}
