import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { listVolumeScans, fetchVolumeScanBytes } from './nexradS3';

// Trimmed real response captured from
// https://unidata-nexrad-level2.s3.amazonaws.com/?list-type=2&prefix=2026/07/26/KBYX/&delimiter=/
const SAMPLE_LISTING_XML = `<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>unidata-nexrad-level2</Name><Prefix>2026/07/26/KBYX/</Prefix><KeyCount>3</KeyCount><MaxKeys>1000</MaxKeys><Delimiter>/</Delimiter><IsTruncated>false</IsTruncated><Contents><Key>2026/07/26/KBYX/KBYX20260726_000049_V06</Key><LastModified>2026-07-26T00:06:45.000Z</LastModified><ETag>"a498d803bea8bdbf767a70d26f98d262"</ETag><Size>3887280</Size><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>2026/07/26/KBYX/KBYX20260726_001212_V06</Key><LastModified>2026-07-26T00:18:08.000Z</LastModified><ETag>"7287edf15bcbb1b9d8b2bec7e54615d3"</ETag><Size>3807814</Size><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>2026/07/26/KBYX/KBYX20260726_000653_V06</Key><LastModified>2026-07-26T00:12:05.000Z</LastModified><ETag>"f4da16edf39d9113f0d3af737b3672e6"</ETag><Size>3493329</Size><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>`;

describe('listVolumeScans', () => {
	let originalFetch: typeof fetch;

	beforeEach(() => {
		originalFetch = globalThis.fetch;
	});

	afterEach(() => {
		globalThis.fetch = originalFetch;
	});

	it('parses Key/Size/timestamp and sorts oldest-first', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			text: async () => SAMPLE_LISTING_XML
		})) as unknown as typeof fetch;

		const scans = await listVolumeScans('KBYX', { year: 2026, month: 7, day: 26 });

		expect(scans.map((s) => s.key)).toEqual([
			'2026/07/26/KBYX/KBYX20260726_000049_V06',
			'2026/07/26/KBYX/KBYX20260726_000653_V06',
			'2026/07/26/KBYX/KBYX20260726_001212_V06'
		]);
		expect(scans[0].sizeBytes).toBe(3887280);
		expect(scans[0].timestamp.toISOString()).toBe('2026-07-26T00:00:49.000Z');
	});

	it('returns an empty array for a day/site with no data', async () => {
		globalThis.fetch = vi.fn(async () => ({
			ok: true,
			text: async () =>
				`<?xml version="1.0"?><ListBucketResult><KeyCount>0</KeyCount><IsTruncated>false</IsTruncated></ListBucketResult>`
		})) as unknown as typeof fetch;

		expect(await listVolumeScans('KBYX', { year: 2026, month: 1, day: 1 })).toEqual([]);
	});

	it('follows NextContinuationToken when the listing is truncated', async () => {
		const page1 = `<?xml version="1.0"?><ListBucketResult><IsTruncated>true</IsTruncated><NextContinuationToken>tok1</NextContinuationToken><Contents><Key>2026/07/26/KBYX/KBYX20260726_000049_V06</Key><Size>100</Size></Contents></ListBucketResult>`;
		const page2 = `<?xml version="1.0"?><ListBucketResult><IsTruncated>false</IsTruncated><Contents><Key>2026/07/26/KBYX/KBYX20260726_000653_V06</Key><Size>200</Size></Contents></ListBucketResult>`;

		let call = 0;
		globalThis.fetch = vi.fn(async () => {
			call += 1;
			return { ok: true, text: async () => (call === 1 ? page1 : page2) };
		}) as unknown as typeof fetch;

		const scans = await listVolumeScans('KBYX', { year: 2026, month: 7, day: 26 });
		expect(scans).toHaveLength(2);
		expect(call).toBe(2);
	});

	it('throws when the listing request fails', async () => {
		globalThis.fetch = vi.fn(async () => ({ ok: false, status: 403 })) as unknown as typeof fetch;
		await expect(listVolumeScans('KBYX', { year: 2026, month: 7, day: 26 })).rejects.toThrow();
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

		const picked = await fetchVolumeScanBytes('2026/07/26/KBYX/KBYX20260726_000049_V06');
		expect(picked.fileName).toBe('KBYX20260726_000049_V06');
		expect(Array.from(picked.bytes)).toEqual([1, 2, 3, 4]);
	});

	it('throws when the download fails', async () => {
		globalThis.fetch = vi.fn(async () => ({ ok: false, status: 404 })) as unknown as typeof fetch;
		await expect(fetchVolumeScanBytes('bad/key')).rejects.toThrow();
	});
});
