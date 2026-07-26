/**
 * Browser-side client for the `unidata-nexrad-level2` public S3 bucket (anonymous read, CORS
 * `*` verified on both the ListObjectsV2 XML listing endpoint and object GET). Archives are laid
 * out as `YYYY/MM/DD/SITE/SITE_YYYYMMDD_HHMMSS_V0x`, one folder per UTC day -- matches what
 * `aws s3 ls --no-sign-request s3://unidata-nexrad-level2/...` already shows.
 *
 * `noaa-nexrad-level2` (the other AWS Open Data mirror) returned 403 on the same kind of
 * listing call when this was verified -- don't switch to it.
 */

const BUCKET_URL = 'https://unidata-nexrad-level2.s3.amazonaws.com/';

export interface VolumeScan {
	key: string;
	sizeBytes: number;
	/** Scan time parsed from the filename (UTC), not the object's upload LastModified. */
	timestamp: Date;
}

export interface ScanDate {
	year: number;
	month: number; // 1-12
	day: number;
}

/** Volume scans for one radar site on one UTC day, oldest first. Empty array is a normal result. */
export async function listVolumeScans(site: string, date: ScanDate): Promise<VolumeScan[]> {
	const prefix = `${date.year}/${pad2(date.month)}/${pad2(date.day)}/${site}/`;
	const scans: VolumeScan[] = [];
	let continuationToken: string | undefined;

	do {
		const url = new URL(BUCKET_URL);
		url.searchParams.set('list-type', '2');
		url.searchParams.set('prefix', prefix);
		url.searchParams.set('delimiter', '/');
		if (continuationToken) url.searchParams.set('continuation-token', continuationToken);

		const res = await fetch(url);
		if (!res.ok) throw new Error(`S3 listing failed for ${prefix}: HTTP ${res.status}`);
		const xml = await res.text();

		scans.push(...parseListing(xml));
		continuationToken = /<IsTruncated>true<\/IsTruncated>/.test(xml)
			? /<NextContinuationToken>([^<]*)<\/NextContinuationToken>/.exec(xml)?.[1]
			: undefined;
	} while (continuationToken);

	return scans.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
}

/** Downloads one volume scan's raw bytes, ready to hand to parseObservation(). */
export async function fetchVolumeScanBytes(
	key: string
): Promise<{ fileName: string; bytes: Uint8Array }> {
	const res = await fetch(BUCKET_URL + key);
	if (!res.ok) throw new Error(`Failed to download ${key}: HTTP ${res.status}`);
	const buf = await res.arrayBuffer();
	return { fileName: key.split('/').pop() ?? key, bytes: new Uint8Array(buf) };
}

function pad2(n: number): string {
	return String(n).padStart(2, '0');
}

// Deliberately minimal (mirrors src/lib/parsers/xml.ts's approach): this only ever needs to pull
// <Key>/<Size> out of each <Contents> block of an S3 ListObjectsV2 response, so a couple of
// regexes are simpler and more portable (no DOMParser dependency, works in Node test runs too)
// than a general XML parser.
function parseListing(xml: string): VolumeScan[] {
	const scans: VolumeScan[] = [];
	const contentsRe = /<Contents>([\s\S]*?)<\/Contents>/g;
	let match: RegExpExecArray | null;
	while ((match = contentsRe.exec(xml))) {
		const block = match[1];
		const key = /<Key>([^<]*)<\/Key>/.exec(block)?.[1];
		const size = /<Size>(\d+)<\/Size>/.exec(block)?.[1];
		if (!key || !size) continue;
		const timestamp = parseTimestampFromKey(key);
		if (!timestamp) continue; // not a volume-scan file (shouldn't happen given the SITE/ prefix)
		scans.push({ key, sizeBytes: Number(size), timestamp });
	}
	return scans;
}

// Filenames are SITE + YYYYMMDD concatenated directly (no separator), then _HHMMSS_Vxx --
// e.g. "KBYX20260726_000049_V06".
const FILENAME_RE = /(\d{8})_(\d{6})_V\d+$/;

function parseTimestampFromKey(key: string): Date | null {
	const match = FILENAME_RE.exec(key);
	if (!match) return null;
	const [, ymd, hms] = match;
	return new Date(
		Date.UTC(
			Number(ymd.slice(0, 4)),
			Number(ymd.slice(4, 6)) - 1,
			Number(ymd.slice(6, 8)),
			Number(hms.slice(0, 2)),
			Number(hms.slice(2, 4)),
			Number(hms.slice(4, 6))
		)
	);
}
