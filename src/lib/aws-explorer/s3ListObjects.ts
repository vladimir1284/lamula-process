/**
 * Generic paginated ListObjectsV2 client shared by nexradS3.ts and ideamS3.ts -- both hit an
 * anonymous public S3 bucket's XML listing endpoint with a `prefix`/`delimiter=/` query and need
 * the same continuation-token pagination + <Contents> block parsing. Only the bucket URL and the
 * per-file timestamp format differ between the two buckets.
 */

export interface S3Object {
	key: string;
	sizeBytes: number;
	timestamp: Date;
}

/** All objects under `prefix` in `bucketUrl`, unsorted. Empty array is a normal result. */
export async function listS3Objects(
	bucketUrl: string,
	prefix: string,
	parseTimestamp: (key: string) => Date | null
): Promise<S3Object[]> {
	const objects: S3Object[] = [];
	let continuationToken: string | undefined;

	do {
		const url = new URL(bucketUrl);
		url.searchParams.set('list-type', '2');
		url.searchParams.set('prefix', prefix);
		url.searchParams.set('delimiter', '/');
		if (continuationToken) url.searchParams.set('continuation-token', continuationToken);

		const res = await fetch(url);
		if (!res.ok) throw new Error(`S3 listing failed for ${prefix}: HTTP ${res.status}`);
		const xml = await res.text();

		objects.push(...parseListing(xml, parseTimestamp));
		continuationToken = /<IsTruncated>true<\/IsTruncated>/.test(xml)
			? /<NextContinuationToken>([^<]*)<\/NextContinuationToken>/.exec(xml)?.[1]
			: undefined;
	} while (continuationToken);

	return objects;
}

/** Downloads one object's raw bytes, ready to hand to parseObservation(). */
export async function fetchS3ObjectBytes(
	bucketUrl: string,
	key: string
): Promise<{ fileName: string; bytes: Uint8Array }> {
	const res = await fetch(bucketUrl + key);
	if (!res.ok) throw new Error(`Failed to download ${key}: HTTP ${res.status}`);
	const buf = await res.arrayBuffer();
	return { fileName: key.split('/').pop() ?? key, bytes: new Uint8Array(buf) };
}

// Deliberately minimal (mirrors src/lib/parsers/xml.ts's approach): this only ever needs to pull
// <Key>/<Size> out of each <Contents> block of an S3 ListObjectsV2 response, so a couple of
// regexes are simpler and more portable (no DOMParser dependency, works in Node test runs too)
// than a general XML parser.
function parseListing(xml: string, parseTimestamp: (key: string) => Date | null): S3Object[] {
	const objects: S3Object[] = [];
	const contentsRe = /<Contents>([\s\S]*?)<\/Contents>/g;
	let match: RegExpExecArray | null;
	while ((match = contentsRe.exec(xml))) {
		const block = match[1];
		const key = /<Key>([^<]*)<\/Key>/.exec(block)?.[1];
		const size = /<Size>(\d+)<\/Size>/.exec(block)?.[1];
		if (!key || !size) continue;
		const timestamp = parseTimestamp(key);
		if (!timestamp) continue; // not a volume-scan file (shouldn't happen given the SITE/ prefix)
		objects.push({ key, sizeBytes: Number(size), timestamp });
	}
	return objects;
}
