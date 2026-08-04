/**
 * Browser-side client for the `unidata-nexrad-level2` public S3 bucket (anonymous read, CORS
 * `*` verified on both the ListObjectsV2 XML listing endpoint and object GET). Archives are laid
 * out as `YYYY/MM/DD/SITE/SITE_YYYYMMDD_HHMMSS_V0x`, one folder per UTC day -- matches what
 * `aws s3 ls --no-sign-request s3://unidata-nexrad-level2/...` already shows.
 *
 * `noaa-nexrad-level2` (the other AWS Open Data mirror) returned 403 on the same kind of
 * listing call when this was verified -- don't switch to it.
 */
import { listS3Objects, fetchS3ObjectBytes } from './s3ListObjects';

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

/** Volume scans for one radar site on one UTC day, most recent first. Empty array is a normal result. */
export async function listVolumeScans(site: string, date: ScanDate): Promise<VolumeScan[]> {
	const prefix = `${date.year}/${pad2(date.month)}/${pad2(date.day)}/${site}/`;
	const objects = await listS3Objects(BUCKET_URL, prefix, parseTimestampFromKey);
	return objects.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
}

/** Downloads one volume scan's raw bytes, ready to hand to parseObservation(). */
export function fetchVolumeScanBytes(
	key: string
): Promise<{ fileName: string; bytes: Uint8Array }> {
	return fetchS3ObjectBytes(BUCKET_URL, key);
}

function pad2(n: number): string {
	return String(n).padStart(2, '0');
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
