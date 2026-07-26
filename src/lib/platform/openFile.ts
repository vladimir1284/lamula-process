import { isTauri } from '@tauri-apps/api/core';

export interface OpenedFile {
	fileName: string;
	bytes: Uint8Array;
}

const ACCEPTED_EXTENSIONS = ['.vol', '.gz', '.ar2', '.obs'];

// Tauri desktop file access (@tauri-apps/plugin-dialog + plugin-fs) isn't wired up yet -- no Rust
// toolchain is available in this sandbox to build/verify the plugin registration, see
// docs/plan-implementacion.md. Only the web path is implemented and tested.
export async function openObservationFile(): Promise<OpenedFile | null> {
	if (isTauri()) throw new Error('Tauri file picker not implemented yet');
	return openViaWebPicker();
}

interface FileSystemFileHandleLike {
	getFile(): Promise<File>;
}

async function openViaWebPicker(): Promise<OpenedFile | null> {
	// File System Access API first (per docs/stack.md), falling back to a plain <input type=file>
	// where it's unavailable (Firefox/Safari at time of writing).
	if ('showOpenFilePicker' in window) {
		try {
			const picker = (
				window as unknown as {
					showOpenFilePicker(options: unknown): Promise<FileSystemFileHandleLike[]>;
				}
			).showOpenFilePicker;
			const [handle] = await picker({
				multiple: false,
				types: [
					{
						description: 'Radar observation',
						accept: { 'application/octet-stream': ACCEPTED_EXTENSIONS }
					}
				]
			});
			const file = await handle.getFile();
			return { fileName: file.name, bytes: new Uint8Array(await file.arrayBuffer()) };
		} catch (err) {
			if (err instanceof DOMException && err.name === 'AbortError') return null; // user cancelled
			throw err;
		}
	}
	return openViaInputElement();
}

// input.click() must run synchronously within the caller's user-gesture event handler (no `await`
// before it) or browsers silently ignore the picker request -- callers should invoke
// openObservationFile() directly from a click handler, not after other awaits.
function openViaInputElement(): Promise<OpenedFile | null> {
	return new Promise((resolve, reject) => {
		const input = document.createElement('input');
		input.type = 'file';
		input.accept = ACCEPTED_EXTENSIONS.join(',');
		input.addEventListener('change', () => {
			const file = input.files?.[0];
			if (!file) {
				resolve(null);
				return;
			}
			file
				.arrayBuffer()
				.then((buf) => resolve({ fileName: file.name, bytes: new Uint8Array(buf) }))
				.catch(reject);
		});
		input.addEventListener('cancel', () => resolve(null));
		input.click();
	});
}
