import { cellFlagCode } from '$lib/domain';

// rayinfo (ray angle): raw uint16 -> degrees via raw*360/65536, i.e. divide by 2**depth, NOT
// 2**depth-2 (that's a different formula, used for moment data below). Only depth=16 verified
// against real fixtures -- see docs/formatos.md.
export function decodeRayAngles(data: Uint8Array, depth: number): Float32Array {
	if (depth !== 16) {
		throw new Error(`rayinfo depth ${depth} not exercised by any fixture, refusing to guess`);
	}
	const view = new DataView(data.buffer, data.byteOffset, data.byteLength);
	const n = Math.floor(data.length / 2);
	const angles = new Float32Array(n);
	for (let i = 0; i < n; i++) {
		angles[i] = (view.getUint16(i * 2) * 360.0) / 65536.0;
	}
	return angles;
}

const NO_DATA = cellFlagCode('no-data');

// rawdata (moment data): raw uint8 or uint16, both verified against real fixtures (depth=8 for
// dBZ/dBuZ/V/W/RhoHV, depth=16 for uPhiDP). raw=0 means no-data/below-threshold. For raw>=1:
// physical = vmin + (raw-1)*scale, scale = (vmax-vmin)/(2**depth-2) -- confirmed empirically
// against the declared slice vmin (see docs/formatos.md), NOT the naive vmin+raw*scale.
export function decodeMoment(
	data: Uint8Array,
	rays: number,
	bins: number,
	depth: number,
	vmin: number,
	vmax: number
): { values: Float32Array; flags: Uint8Array } {
	const n = rays * bins;
	const values = new Float32Array(n);
	const flags = new Uint8Array(n);
	const scale = (vmax - vmin) / (2 ** depth - 2);

	if (depth === 8) {
		for (let i = 0; i < n; i++) {
			const raw = data[i];
			if (raw === 0) flags[i] = NO_DATA;
			else values[i] = vmin + (raw - 1) * scale;
		}
	} else if (depth === 16) {
		const view = new DataView(data.buffer, data.byteOffset, data.byteLength);
		for (let i = 0; i < n; i++) {
			const raw = view.getUint16(i * 2);
			if (raw === 0) flags[i] = NO_DATA;
			else values[i] = vmin + (raw - 1) * scale;
		}
	} else {
		throw new Error(`rawdata depth ${depth} (sub-byte packing) not exercised by any fixture`);
	}

	return { values, flags };
}
