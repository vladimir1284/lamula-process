import { isTauri } from '@tauri-apps/api/core';
import { THIS_APP, type FeedbackContext } from './contract';
import { buildId } from './env';

/**
 * Automatic context attached to every message, so a report is reproducible without a
 * back-and-forth.
 *
 * REDACTION IS THE POINT OF THIS MODULE. The name and path of the opened file NEVER travel, and
 * neither does any sample of the data: these are operational files of INSMET and IDEAM. The file
 * name lives in `pipeline/observationMachine.ts` (`Picked.fileName`) and in
 * `platform/config.ts` (`RecentFileEntry.label`); neither is an input here. Format, site code and
 * elevation are enough to reproduce any bug.
 *
 * The output is built field by field from a closed input type -- never by spreading the caller's
 * object -- so a new field upstream cannot leak in by accident. `context.spec.ts` seeds a
 * recognisable file name and asserts it is absent from the serialised payload.
 */

export interface FeedbackContextInput {
	/** Parser family: 'insmet' | 'nexrad-l2' | 'rainbow' | 'sigmet' | 'netcdf'… */
	format?: string | null;
	/** Radar site code, e.g. 'rdCMW'. Not a path, not a file name. */
	siteCode?: string | null;
	elevationDeg?: number | null;
	/** Window TYPES open at the time, e.g. ['ppi', 'rhi']. Never their titles. */
	productsOpen?: string[];
	paletteName?: string | null;
	filtersActive?: string[];
	locale?: string | null;
	/** Dedup key; also stored on the queue entry. */
	clientId?: string;
}

function detectPlatform(): 'web' | 'tauri' {
	try {
		return isTauri() ? 'tauri' : 'web';
	} catch {
		return 'web';
	}
}

function viewport(): string | null {
	if (typeof window === 'undefined') return null;
	return `${window.innerWidth}x${window.innerHeight}`;
}

function userAgent(): string | null {
	if (typeof navigator === 'undefined') return null;
	return navigator.userAgent;
}

export function buildContext(input: FeedbackContextInput = {}): FeedbackContext {
	const context: FeedbackContext = {
		app: THIS_APP,
		platform: detectPlatform(),
		buildId: buildId(),
		clientId: input.clientId ?? crypto.randomUUID()
	};

	const locale = input.locale ?? null;
	if (locale) context.locale = locale;

	const vp = viewport();
	if (vp) context.viewport = vp;

	const ua = userAgent();
	if (ua) context.userAgent = ua;

	if (input.format) context.format = input.format;
	if (input.siteCode) context.siteCode = input.siteCode;
	if (typeof input.elevationDeg === 'number' && Number.isFinite(input.elevationDeg)) {
		context.elevationDeg = input.elevationDeg;
	}
	if (input.productsOpen?.length) context.productsOpen = [...input.productsOpen];
	if (input.paletteName) context.paletteName = input.paletteName;
	if (input.filtersActive?.length) context.filtersActive = [...input.filtersActive];

	return context;
}
