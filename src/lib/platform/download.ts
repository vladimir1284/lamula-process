/** Triggers a browser download of in-memory text content -- the Blob/`<a download>` pattern
 * already used inline for JSON/PNG exports elsewhere in this app (`+page.svelte`, `viewer/exportImage.ts`),
 * factored out here since this is the first plain-text (CSV/TXT) export. */
export function downloadTextFile(content: string, filename: string, mimeType: string): void {
	const blob = new Blob([content], { type: mimeType });
	const url = URL.createObjectURL(blob);
	const a = document.createElement('a');
	a.href = url;
	a.download = filename;
	a.click();
	URL.revokeObjectURL(url);
}
