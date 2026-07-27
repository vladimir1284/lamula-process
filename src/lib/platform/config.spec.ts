// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { isTauri } from '@tauri-apps/api/core';

vi.mock('@tauri-apps/api/core', () => ({ isTauri: vi.fn(() => false) }));

import { loadConfig, saveConfig, addRecentFile, type RecentFileEntry } from './config';

const local = (label: string): RecentFileEntry => ({ label, source: 'local' });

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

	it('falls back to the default on the pre-migration plain-string shape', async () => {
		localStorage.setItem(
			'lamula-process:config',
			JSON.stringify({ recentFiles: ['a.vol', 'b.gz'] })
		);
		expect(await loadConfig()).toEqual({ recentFiles: [] });
	});
});

describe('saveConfig / loadConfig round-trip', () => {
	it('persists across a save/load cycle', async () => {
		await saveConfig({ recentFiles: [local('a.vol'), local('b.gz')] });
		expect(await loadConfig()).toEqual({ recentFiles: [local('a.vol'), local('b.gz')] });
	});

	it('keeps the s3Key on an aws entry', async () => {
		const entry: RecentFileEntry = {
			label: 'KBYX_V06',
			source: 'aws',
			s3Key: '2026/07/26/KBYX/KBYX_V06'
		};
		await saveConfig({ recentFiles: [entry] });
		expect(await loadConfig()).toEqual({ recentFiles: [entry] });
	});
});

describe('addRecentFile', () => {
	it('adds a new file to the front', async () => {
		await saveConfig({ recentFiles: [local('a.vol')] });
		const updated = await addRecentFile(local('b.gz'));
		expect(updated.recentFiles).toEqual([local('b.gz'), local('a.vol')]);
	});

	it('moves an already-present file to the front instead of duplicating it', async () => {
		await saveConfig({ recentFiles: [local('a.vol'), local('b.gz'), local('c.vol')] });
		const updated = await addRecentFile(local('b.gz'));
		expect(updated.recentFiles).toEqual([local('b.gz'), local('a.vol'), local('c.vol')]);
	});

	it('caps the list at 10 entries', async () => {
		const initial = Array.from({ length: 10 }, (_, i) => local(`f${i}.vol`));
		await saveConfig({ recentFiles: initial });
		const updated = await addRecentFile(local('new.vol'));
		expect(updated.recentFiles).toHaveLength(10);
		expect(updated.recentFiles[0]).toEqual(local('new.vol'));
		expect(updated.recentFiles).not.toContainEqual(local('f9.vol'));
	});
});
