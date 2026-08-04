import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { listVolumeScans, fetchVolumeScanBytes } from './ideamS3';

// Trimmed real response captured from
// https://s3-radaresideam.s3.amazonaws.com/?list-type=2&prefix=l2_data/2023/01/01/Guaviare/
const RAW_LISTING_XML = `<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult><Prefix>l2_data/2023/01/01/Guaviare/</Prefix><IsTruncated>false</IsTruncated><Contents><Key>l2_data/2023/01/01/Guaviare/GUA230101000023.RAW7W6D</Key><Size>3760128</Size></Contents><Contents><Key>l2_data/2023/01/01/Guaviare/GUA230101000127.RAW7W6H</Key><Size>4767744</Size></Contents></ListBucketResult>`;

// Trimmed real response captured from
// https://s3-radaresideam.s3.amazonaws.com/?list-type=2&prefix=l2_data/2025/06/01/Bogota/
const NETCDF_LISTING_XML = `<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult><Prefix>l2_data/2025/06/01/Bogota/</Prefix><IsTruncated>false</IsTruncated><Contents><Key>l2_data/2025/06/01/Bogota/1399BOG-20250601-000042-PPIVol-7550.nc</Key><Size>59986980</Size></Contents><Contents><Key>l2_data/2025/06/01/Bogota/1399BOG-20250601-000245-PPIVol-7556.nc</Key><Size>59986980</Size></Contents></ListBucketResult>`;

describe('listVolumeScans', () => {
	let originalFetch: typeof fetch;

	beforeEach(() => {
		originalFetch = globalThis.fetch;
	});

	afterEach(() => {
		globalThis.fetch = originalFetch;
	});

	it('parses Sigmet/IRIS RAW filenames (Guaviare) and sorts most-recent-first', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			text: async () => RAW_LISTING_XML
		})) as unknown as typeof fetch;

		const scans = await listVolumeScans('Guaviare', { year: 2023, month: 1, day: 1 });

		expect(scans.map((s) => s.key)).toEqual([
			'l2_data/2023/01/01/Guaviare/GUA230101000127.RAW7W6H',
			'l2_data/2023/01/01/Guaviare/GUA230101000023.RAW7W6D'
		]);
		expect(scans[0].timestamp.toISOString()).toBe('2023-01-01T00:01:27.000Z');
	});

	it('parses NetCDF PPIVol filenames (Bogota) and sorts most-recent-first', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			text: async () => NETCDF_LISTING_XML
		})) as unknown as typeof fetch;

		const scans = await listVolumeScans('Bogota', { year: 2025, month: 6, day: 1 });

		expect(scans.map((s) => s.key)).toEqual([
			'l2_data/2025/06/01/Bogota/1399BOG-20250601-000245-PPIVol-7556.nc',
			'l2_data/2025/06/01/Bogota/1399BOG-20250601-000042-PPIVol-7550.nc'
		]);
		expect(scans[0].timestamp.toISOString()).toBe('2025-06-01T00:02:45.000Z');
	});

	it('returns an empty array for a day/site with no data', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			text: async () =>
				`<?xml version="1.0"?><ListBucketResult><KeyCount>0</KeyCount><IsTruncated>false</IsTruncated></ListBucketResult>`
		})) as unknown as typeof fetch;

		expect(await listVolumeScans('Guaviare', { year: 2026, month: 1, day: 1 })).toEqual([]);
	});

	it('follows NextContinuationToken when the listing is truncated', async () => {
		const page1 = `<?xml version="1.0"?><ListBucketResult><IsTruncated>true</IsTruncated><NextContinuationToken>tok1</NextContinuationToken><Contents><Key>l2_data/2023/01/01/Guaviare/GUA230101000023.RAW7W6D</Key><Size>100</Size></Contents></ListBucketResult>`;
		const page2 = `<?xml version="1.0"?><ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>l2_data/2023/01/01/Guaviare/GUA230101000127.RAW7W6H</Key><Size>200</Size></Contents></ListBucketResult>`;

		let call = 0;
		globalThis.fetch = vi.fn(async () => {
			call += 1;
			return { ok: true, text: async () => (call === 1 ? page1 : page2) };
		}) as unknown as typeof fetch;

		const scans = await listVolumeScans('Guaviare', { year: 2023, month: 1, day: 1 });
		expect(scans).toHaveLength(2);
		expect(call).toBe(2);
	});

	it('throws when the listing request fails', async () => {
		globalThis.fetch = vi.fn(async () => ({ ok: false, status: 403 })) as unknown as typeof fetch;
		await expect(listVolumeScans('Guaviare', { year: 2023, month: 1, day: 1 })).rejects.toThrow();
	});
});

describe('fetchVolumeScanBytes', () => {
	let originalFetch: typeof fetch;

	beforeEach(() => {
		originalFetch = globalThis.fetch;
	});

	afterEach(() => {
		globalThis.fetch = originalFetch;
	});

	it('downloads bytes and derives fileName from the key', async () => {
		const bytes = new Uint8Array([1, 2, 3, 4]);
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			arrayBuffer: async () => bytes.buffer
		})) as unknown as typeof fetch;

		const picked = await fetchVolumeScanBytes(
			'l2_data/2023/01/01/Guaviare/GUA230101000023.RAW7W6D'
		);
		expect(picked.fileName).toBe('GUA230101000023.RAW7W6D');
		expect(Array.from(picked.bytes)).toEqual([1, 2, 3, 4]);
	});

	it('throws when the download fails', async () => {
		globalThis.fetch = vi.fn(async () => ({ ok: false, status: 404 })) as unknown as typeof fetch;
		await expect(fetchVolumeScanBytes('bad/key')).rejects.toThrow();
	});
});
