/**
 * Browser-side client for the `s3-radaresideam` public S3 bucket (IDEAM's Colombian radar
 * network, anonymous read, no AWS account needed -- see
 * https://registry.opendata.aws/ideam-radares/). Archives are laid out as
 * `l2_data/YYYY/MM/DD/RadarName/<file>`, one folder per UTC day, verified against the live
 * bucket via `curl "https://s3-radaresideam.s3.amazonaws.com/?list-type=2&prefix=l2_data/..."`.
 *
 * Two file families live in this bucket depending on the radar (verified against real keys):
 *  - Sigmet/IRIS RAW volumes for Guaviare/Munchique/Carimagua/Barrancabermeja/Corozal/Tablazo,
 *    e.g. "GUA230101000023.RAW7W6D" (site code + YYMMDDHHMMSS + ".RAW" + hex suffix).
 *  - NetCDF PPIVol volumes for Bogota and santa_elena (a different radar vendor -- SIATA operates
 *    the santa_elena site), e.g. "1399BOG-20250601-000042-PPIVol-7550.nc".
 * Neither format has a parser in this app yet -- this module only supports browsing/downloading
 * raw bytes, matching the current AWS NEXRAD explorer's scope.
 */
import { listS3Objects, fetchS3ObjectBytes } from './s3ListObjects';

const BUCKET_URL = 'https://s3-radaresideam.s3.amazonaws.com/';

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
	const prefix = `l2_data/${date.year}/${pad2(date.month)}/${pad2(date.day)}/${site}/`;
	const objects = await listS3Objects(BUCKET_URL, prefix, parseTimestampFromKey);
	return objects.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
}

/** Downloads one volume scan's raw bytes. */
export function fetchVolumeScanBytes(
	key: string
): Promise<{ fileName: string; bytes: Uint8Array }> {
	return fetchS3ObjectBytes(BUCKET_URL, key);
}

function pad2(n: number): string {
	return String(n).padStart(2, '0');
}

// Sigmet/IRIS RAW: SITECODE + YYMMDDHHMMSS + ".RAW" + hex suffix, e.g. "GUA230101000023.RAW7W6D".
const RAW_FILENAME_RE = /(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})\.RAW/;

// NetCDF PPIVol: <radarId><site>-YYYYMMDD-HHMMSS-PPIVol-<hex>.nc, e.g.
// "1399BOG-20250601-000042-PPIVol-7550.nc".
const NETCDF_FILENAME_RE = /-(\d{8})-(\d{6})-PPIVol-/;

function parseTimestampFromKey(key: string): Date | null {
	const rawMatch = RAW_FILENAME_RE.exec(key);
	if (rawMatch) {
		const [, yy, mm, dd, hh, min, ss] = rawMatch;
		return new Date(
			Date.UTC(2000 + Number(yy), Number(mm) - 1, Number(dd), Number(hh), Number(min), Number(ss))
		);
	}

	const netcdfMatch = NETCDF_FILENAME_RE.exec(key);
	if (netcdfMatch) {
		const [, ymd, hms] = netcdfMatch;
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

	return null;
}
