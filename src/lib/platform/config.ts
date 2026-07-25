import { isTauri } from '@tauri-apps/api/core';

export interface AppConfig {
	// Most-recently-opened file names, most recent first.
	recentFiles: string[];
}

const DEFAULT_CONFIG: AppConfig = { recentFiles: [] };
const STORAGE_KEY = 'lamula-process:config';
const MAX_RECENT_FILES = 10;

// Tauri desktop persistence (@tauri-apps/plugin-store) isn't wired up yet -- no Rust toolchain is
// available in this sandbox to build/verify the plugin registration, see docs/plan-implementacion.md.
// Only the web path (localStorage) is implemented and tested.
export async function loadConfig(): Promise<AppConfig> {
	if (isTauri()) throw new Error('Tauri config store not implemented yet');
	const raw = localStorage.getItem(STORAGE_KEY);
	if (!raw) return { ...DEFAULT_CONFIG };
	try {
		const parsed = JSON.parse(raw);
		return { recentFiles: Array.isArray(parsed.recentFiles) ? parsed.recentFiles : [] };
	} catch {
		return { ...DEFAULT_CONFIG };
	}
}

export async function saveConfig(config: AppConfig): Promise<void> {
	if (isTauri()) throw new Error('Tauri config store not implemented yet');
	localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
}

export async function addRecentFile(fileName: string): Promise<AppConfig> {
	const config = await loadConfig();
	const deduped = [fileName, ...config.recentFiles.filter((f) => f !== fileName)];
	const updated: AppConfig = { recentFiles: deduped.slice(0, MAX_RECENT_FILES) };
	await saveConfig(updated);
	return updated;
}
