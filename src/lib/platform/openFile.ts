import { isTauri } from '@tauri-apps/api/core';

export interface OpenedFile {
	fileName: string;
	bytes: Uint8Array;
}

// IDEAM's Sigmet RAW files (e.g. "COR250601000029.RAWYSAP") have no clean, listable extension --
// same situation as NEXRAD L2's extensionless AWS files, see openViaInputElement below. There's
// nothing to add here for that format; registry.ts's content-sniffing is the real gate.
const ACCEPTED_EXTENSIONS = ['.vol', '.gz', '.ar2', '.ar2.bz2', '.obs', '.nc'];

// Tauri desktop file access (@tauri-apps/plugin-dialog + plugin-fs) isn't wired up yet -- no Rust
// toolchain is available in this sandbox to build/verify the plugin registration, see
// docs/plan-implementacion.md. Only the web path is implemented and tested.
export async function openObservationFile(): Promise<OpenedFile | null> {
	if (isTauri()) throw new Error('Tauri file picker not implemented yet');
	return openViaWebPicker();
}

/** Multi-file variant for opening a volume's individual sweep files at once (Sigmet/IRIS RAW,
 * CfRadial/PPIVol -- both one-elevation-per-file, see domain/mergeSweeps.ts). Empty array if the
 * user picked nothing/cancelled; a single file is a valid "volume" of one sweep. */
export async function openObservationFiles(): Promise<OpenedFile[]> {
	if (isTauri()) throw new Error('Tauri file picker not implemented yet');
	return openViaWebPickerMultiple();
}

interface FileSystemFileHandleLike {
	getFile(): Promise<File>;
	queryPermission?(opts: { mode: 'read' }): Promise<'granted' | 'denied' | 'prompt'>;
	requestPermission?(opts: { mode: 'read' }): Promise<'granted' | 'denied' | 'prompt'>;
}

// In-memory only (lost on reload) -- lets "Abrir reciente" silently re-read a local file picked
// via showOpenFilePicker this session instead of re-prompting the native dialog. Entries from a
// prior session (restored from localStorage by config.ts) have no handle here, so reopenLocalFile
// throws and the caller falls back to a fresh "Abrir archivo".
const rememberedHandles = new Map<string, FileSystemFileHandleLike>();

export function getRememberedFileHandle(fileName: string): FileSystemFileHandleLike | undefined {
	return rememberedHandles.get(fileName);
}

export async function reopenLocalFile(handle: FileSystemFileHandleLike): Promise<OpenedFile> {
	if (handle.queryPermission && handle.requestPermission) {
		const status = await handle.queryPermission({ mode: 'read' });
		if (status !== 'granted') {
			const granted = await handle.requestPermission({ mode: 'read' });
			if (granted !== 'granted') throw new Error('Permiso denegado para reabrir el archivo.');
		}
	}
	const file = await handle.getFile();
	return { fileName: file.name, bytes: new Uint8Array(await file.arrayBuffer()) };
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
			rememberedHandles.set(file.name, handle);
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
		// No `accept` filter: real NEXRAD Level II archives pulled from NOAA/AWS ship with no
		// extension at all (e.g. "KBYX20260726_113948_V06"), so an extension allowlist would grey
		// them out in this fallback picker. Content sniffing in registry.ts's canParse is the real
		// gate; ACCEPTED_EXTENSIONS above only hints the File System Access API picker.
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

async function openViaWebPickerMultiple(): Promise<OpenedFile[]> {
	if ('showOpenFilePicker' in window) {
		try {
			const picker = (
				window as unknown as {
					showOpenFilePicker(options: unknown): Promise<FileSystemFileHandleLike[]>;
				}
			).showOpenFilePicker;
			const handles = await picker({
				multiple: true,
				types: [
					{
						description: 'Radar observation',
						accept: { 'application/octet-stream': ACCEPTED_EXTENSIONS }
					}
				]
			});
			return Promise.all(
				handles.map(async (handle) => {
					const file = await handle.getFile();
					rememberedHandles.set(file.name, handle);
					return { fileName: file.name, bytes: new Uint8Array(await file.arrayBuffer()) };
				})
			);
		} catch (err) {
			if (err instanceof DOMException && err.name === 'AbortError') return []; // user cancelled
			throw err;
		}
	}
	return openViaInputElementMultiple();
}

function openViaInputElementMultiple(): Promise<OpenedFile[]> {
	return new Promise((resolve, reject) => {
		const input = document.createElement('input');
		input.type = 'file';
		input.multiple = true;
		input.addEventListener('change', () => {
			const files = input.files ? Array.from(input.files) : [];
			if (files.length === 0) {
				resolve([]);
				return;
			}
			Promise.all(
				files.map(async (file) => ({
					fileName: file.name,
					bytes: new Uint8Array(await file.arrayBuffer())
				}))
			)
				.then(resolve)
				.catch(reject);
		});
		input.addEventListener('cancel', () => resolve([]));
		input.click();
	});
}
