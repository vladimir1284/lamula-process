import type { Scan } from '$lib/domain/types';

/**
 * Common shape for a derived product that renders on the PPI raster path: a single ground-range
 * polar `Scan` (elevation 0, so downstream rendering does not re-project it) plus the physical
 * unit of its cell values and a count of source scans that were skipped for geometry mismatch.
 *
 * `unit` is carried alongside the scan because the domain `Scan` itself has no unit tag (values
 * live in `Cells.values` as plain numbers); derived products change the physical quantity —
 * echo-top height is metres, VIL is kg/m², rain accumulation is mm — so the readout/legend needs
 * to know what it is showing. Legacy stored this as the `Measure` enum on the product; we keep a
 * plain string and drop the legacy `unKM`-declared-but-metres-stored mismatch (documented in
 * docs/plan-implementacion.md §Fase 3, decision 4).
 */
export interface ProductResult {
	scan: Scan;
	unit: string;
	skipped: number;
}
