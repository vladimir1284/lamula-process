import { isTauri } from '@tauri-apps/api/core';

/**
 * `s3Key` is the full bucket key (e.g. `2026/07/26/KBYX/KBYX20260726_113948_V06`), needed to
 * re-fetch an 'aws' entry -- `label` alone (the trailing filename) isn't enough to rebuild it.
 */
export interface RecentFileEntry {
	label: string;
	source: 'local' | 'aws';
	s3Key?: string;
}

export interface AppConfig {
	// Most-recently-opened files, most recent first.
	recentFiles: RecentFileEntry[];
}

const DEFAULT_CONFIG: AppConfig = { recentFiles: [] };
const STORAGE_KEY = 'lamula-process:config';
const MAX_RECENT_FILES = 10;

function isRecentFileEntry(v: unknown): v is RecentFileEntry {
	return (
		typeof v === 'object' &&
		v !== null &&
		typeof (v as RecentFileEntry).label === 'string' &&
		((v as RecentFileEntry).source === 'local' || (v as RecentFileEntry).source === 'aws')
	);
}

// Tauri desktop persistence (@tauri-apps/plugin-store) isn't wired up yet -- no Rust toolchain is
// available in this sandbox to build/verify the plugin registration, see docs/plan-implementacion.md.
// Only the web path (localStorage) is implemented and tested.
export async function loadConfig(): Promise<AppConfig> {
	if (isTauri()) throw new Error('Tauri config store not implemented yet');
	const raw = localStorage.getItem(STORAGE_KEY);
	if (!raw) return { ...DEFAULT_CONFIG };
	try {
		const parsed = JSON.parse(raw);
		const recentFiles = Array.isArray(parsed.recentFiles) ? parsed.recentFiles : [];
		return { recentFiles: recentFiles.every(isRecentFileEntry) ? recentFiles : [] };
	} catch {
		return { ...DEFAULT_CONFIG };
	}
}

export async function saveConfig(config: AppConfig): Promise<void> {
	if (isTauri()) throw new Error('Tauri config store not implemented yet');
	localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
}

export async function addRecentFile(entry: RecentFileEntry): Promise<AppConfig> {
	const config = await loadConfig();
	const deduped = [entry, ...config.recentFiles.filter((f) => f.label !== entry.label)];
	const updated: AppConfig = { recentFiles: deduped.slice(0, MAX_RECENT_FILES) };
	await saveConfig(updated);
	return updated;
}
