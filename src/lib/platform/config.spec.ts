// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { isTauri } from '@tauri-apps/api/core';

vi.mock('@tauri-apps/api/core', () => ({ isTauri: vi.fn(() => false) }));

import { loadConfig, saveConfig, addRecentFile } from './config';

beforeEach(() => {
	localStorage.clear();
	vi.mocked(isTauri).mockReturnValue(false);
});

describe('on Tauri (not implemented yet)', () => {
	it('loadConfig/saveConfig both throw', async () => {
		vi.mocked(isTauri).mockReturnValue(true);
		await expect(loadConfig()).rejects.toThrow(/not implemented yet/);
		await expect(saveConfig({ recentFiles: [] })).rejects.toThrow(/not implemented yet/);
	});
});

describe('loadConfig', () => {
	it('returns an empty recentFiles list when nothing is stored', async () => {
		expect(await loadConfig()).toEqual({ recentFiles: [] });
	});

	it('falls back to the default on corrupt JSON', async () => {
		localStorage.setItem('lamula-process:config', '{not json');
		expect(await loadConfig()).toEqual({ recentFiles: [] });
	});

	it('falls back to the default when recentFiles is not an array', async () => {
		localStorage.setItem('lamula-process:config', JSON.stringify({ recentFiles: 'nope' }));
		expect(await loadConfig()).toEqual({ recentFiles: [] });
	});
});

describe('saveConfig / loadConfig round-trip', () => {
	it('persists across a save/load cycle', async () => {
		await saveConfig({ recentFiles: ['a.vol', 'b.gz'] });
		expect(await loadConfig()).toEqual({ recentFiles: ['a.vol', 'b.gz'] });
	});
});

describe('addRecentFile', () => {
	it('adds a new file to the front', async () => {
		await saveConfig({ recentFiles: ['a.vol'] });
		const updated = await addRecentFile('b.gz');
		expect(updated.recentFiles).toEqual(['b.gz', 'a.vol']);
	});

	it('moves an already-present file to the front instead of duplicating it', async () => {
		await saveConfig({ recentFiles: ['a.vol', 'b.gz', 'c.vol'] });
		const updated = await addRecentFile('b.gz');
		expect(updated.recentFiles).toEqual(['b.gz', 'a.vol', 'c.vol']);
	});

	it('caps the list at 10 entries', async () => {
		const initial = Array.from({ length: 10 }, (_, i) => `f${i}.vol`);
		await saveConfig({ recentFiles: initial });
		const updated = await addRecentFile('new.vol');
		expect(updated.recentFiles).toHaveLength(10);
		expect(updated.recentFiles[0]).toBe('new.vol');
		expect(updated.recentFiles).not.toContain('f9.vol');
	});
});
