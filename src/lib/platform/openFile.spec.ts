// @vitest-environment happy-dom
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { isTauri } from '@tauri-apps/api/core';

vi.mock('@tauri-apps/api/core', () => ({ isTauri: vi.fn(() => false) }));

import { openObservationFile } from './openFile';

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
