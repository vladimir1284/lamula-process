/** Great-circle distance in km between two lat/lon points (haversine, Earth radius 6371 km). */
export function haversineKm(
	a: { lat: number; lon: number },
	b: { lat: number; lon: number }
): number {
	const R = 6371;
	const dLat = toRad(b.lat - a.lat);
	const dLon = toRad(b.lon - a.lon);
	const sinLat = Math.sin(dLat / 2);
	const sinLon = Math.sin(dLon / 2);
	const h = sinLat * sinLat + Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * sinLon * sinLon;
	return 2 * R * Math.asin(Math.sqrt(h));
}

function toRad(deg: number): number {
	return (deg * Math.PI) / 180;
}
