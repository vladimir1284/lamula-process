// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { isTauri } from '@tauri-apps/api/core';

vi.mock('@tauri-apps/api/core', () => ({ isTauri: vi.fn(() => false) }));

import { openObservationFile, reopenLocalFile } from './openFile';

beforeEach(() => {
	vi.mocked(isTauri).mockReturnValue(false);
});

describe('openObservationFile (Tauri)', () => {
	it('throws until the desktop backend is implemented', async () => {
		vi.mocked(isTauri).mockReturnValue(true);
		await expect(openObservationFile()).rejects.toThrow(/not implemented yet/);
	});
});

// happy-dom has no File System Access API, so every web-path test here exercises the
// <input type=file> fallback.
describe('openObservationFile (web, input fallback)', () => {
	let originalClick: typeof HTMLInputElement.prototype.click;

	beforeEach(() => {
		originalClick = HTMLInputElement.prototype.click;
	});

	afterEach(() => {
		HTMLInputElement.prototype.click = originalClick;
	});

	it("resolves with the picked file's name and bytes", async () => {
		const file = new File([new Uint8Array([1, 2, 3])], 'scan.vol');
		HTMLInputElement.prototype.click = function (this: HTMLInputElement) {
			Object.defineProperty(this, 'files', { value: [file], configurable: true });
			this.dispatchEvent(new Event('change'));
		};

		const result = await openObservationFile();
		expect(result?.fileName).toBe('scan.vol');
		expect(Array.from(result!.bytes)).toEqual([1, 2, 3]);
	});

	it('resolves null when no file is chosen on change', async () => {
		HTMLInputElement.prototype.click = function (this: HTMLInputElement) {
			Object.defineProperty(this, 'files', { value: [], configurable: true });
			this.dispatchEvent(new Event('change'));
		};

		expect(await openObservationFile()).toBeNull();
	});

	it('resolves null on the native cancel event', async () => {
		HTMLInputElement.prototype.click = function (this: HTMLInputElement) {
			this.dispatchEvent(new Event('cancel'));
		};

		expect(await openObservationFile()).toBeNull();
	});
});

// The remembered-handle map that backs these is populated only by the showOpenFilePicker branch
// of openObservationFile(), which happy-dom can't exercise (see the describe block above) -- so
// reopenLocalFile is tested directly against a fake handle instead.
describe('reopenLocalFile', () => {
	function fakeHandle(bytes: number[], name = 'scan.vol') {
		return { getFile: async () => new File([new Uint8Array(bytes)], name) };
	}

	it('re-reads the file when there is no permission API (already-granted access)', async () => {
		const result = await reopenLocalFile(fakeHandle([1, 2, 3]));
		expect(result.fileName).toBe('scan.vol');
		expect(Array.from(result.bytes)).toEqual([1, 2, 3]);
	});

	it('skips requestPermission when queryPermission already reports granted', async () => {
		const requestPermission = vi.fn();
		const handle = {
			...fakeHandle([9]),
			queryPermission: vi.fn(async () => 'granted' as const),
			requestPermission
		};
		await reopenLocalFile(handle);
		expect(requestPermission).not.toHaveBeenCalled();
	});

	it('requests permission when not yet granted, then re-reads on success', async () => {
		const handle = {
			...fakeHandle([4, 5]),
			queryPermission: vi.fn(async () => 'prompt' as const),
			requestPermission: vi.fn(async () => 'granted' as const)
		};
		const result = await reopenLocalFile(handle);
		expect(handle.requestPermission).toHaveBeenCalledWith({ mode: 'read' });
		expect(Array.from(result.bytes)).toEqual([4, 5]);
	});

	it('throws when permission is denied', async () => {
		const handle = {
			...fakeHandle([1]),
			queryPermission: vi.fn(async () => 'prompt' as const),
			requestPermission: vi.fn(async () => 'denied' as const)
		};
		await expect(reopenLocalFile(handle)).rejects.toThrow(/permiso denegado/i);
	});
});
