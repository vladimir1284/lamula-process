// Guards against new hardcoded Spanish UI text slipping back in now that strings live in
// src/lib/i18n/locales/*.json. Heuristic (accented chars / ¿¡), not an AST check: skips comment
// lines and the locale JSON files themselves, so a rare false positive is expected and can be
// silenced by rephrasing or moving the string into a locale file.
import { readdirSync, readFileSync, statSync } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const srcDir = path.resolve(__dirname, '..', 'src');

const SPANISH_PATTERN = /[áéíóúñÁÉÍÓÚÑ¿¡]/;
const EXCLUDED_DIRS = new Set(['i18n', 'vitest-examples']);
const EXCLUDED_FILE_SUFFIXES = ['.spec.ts', '.test.ts'];

function isCommentLine(line) {
	const trimmed = line.trim();
	return trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/**');
}

// Deliberate, reviewed exceptions: raw technical error text kept in its origin language (shown
// only inside a collapsed "technical detail" in the UI), static SEO/social-share meta tags, and
// language names shown in their own language (a standard picker convention). Mark with this to
// silence the check for a specific line.
const IGNORE_MARKER = 'i18n-ignore';

function walk(dir, files = []) {
	for (const entry of readdirSync(dir)) {
		if (EXCLUDED_DIRS.has(entry)) continue;
		const full = path.join(dir, entry);
		if (statSync(full).isDirectory()) {
			walk(full, files);
		} else if (entry.endsWith('.svelte') || entry.endsWith('.ts')) {
			if (EXCLUDED_FILE_SUFFIXES.some((suf) => entry.endsWith(suf))) continue;
			files.push(full);
		}
	}
	return files;
}

const offenders = [];
for (const file of walk(srcDir)) {
	const lines = readFileSync(file, 'utf8').split('\n');
	lines.forEach((line, i) => {
		if (isCommentLine(line)) return;
		// Look back a few lines so the marker can sit on a comment above a wrapped multi-line
		// tag/statement (prettier reflows these, so the marker can't rely on a fixed offset).
		const nearbyLines = lines.slice(Math.max(0, i - 4), i + 1);
		if (nearbyLines.some((l) => l.includes(IGNORE_MARKER))) return;
		if (SPANISH_PATTERN.test(line)) {
			offenders.push(`${path.relative(srcDir, file)}:${i + 1}: ${line.trim()}`);
		}
	});
}

if (offenders.length > 0) {
	console.error('Found hardcoded Spanish text outside src/lib/i18n/locales/:\n');
	console.error(offenders.join('\n'));
	console.error(
		"\nMove the string into src/lib/i18n/locales/{es,en}.json and reference it with $_('key'), or if this is a false positive (comment, scientific unit/notation), adjust check-i18n.mjs."
	);
	process.exit(1);
} else {
	console.log('check-i18n: no hardcoded Spanish text found outside locale files.');
}
