import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { fetchElevationM } from './elevation';

describe('fetchElevationM', () => {
	let originalFetch: typeof fetch;

	beforeEach(() => {
		originalFetch = globalThis.fetch;
	});

	afterEach(() => {
		globalThis.fetch = originalFetch;
	});

	it('returns the elevation from a successful response', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			json: async () => ({ results: [{ elevation: 123.4 }] })
		})) as unknown as typeof fetch;

		expect(await fetchElevationM(21.4, -77.9)).toBe(123.4);
	});

	it('returns null on a non-ok response', async () => {
		globalThis.fetch = vi.fn(async () => ({ ok: false })) as unknown as typeof fetch;
		expect(await fetchElevationM(21.4, -77.9)).toBeNull();
	});

	it('returns null when the response has no results', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			json: async () => ({ results: [] })
		})) as unknown as typeof fetch;
		expect(await fetchElevationM(21.4, -77.9)).toBeNull();
	});

	it('returns null when fetch throws (network down)', async () => {
		globalThis.fetch = vi.fn(async () => {
			throw new Error('network down');
		}) as unknown as typeof fetch;
		expect(await fetchElevationM(21.4, -77.9)).toBeNull();
	});
});
