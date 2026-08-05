// Minimal classic-NetCDF (CDF\x01, "NETCDF3_CLASSIC", magic "CDF\x01") reader -- deliberately not
// general-purpose: covers exactly what IDEAM's CfRadial/PPIVol files use (fixed + record
// variables, byte/char/short/int/float/double types, scalar/array global+variable attributes).
// No 64-bit-offset (CDF\x02) or CDF-5 (CDF\x05) support -- neither appears in the verified
// fixture (test-fixtures/observations/ideam/netcdf-ppivol), and this throws clearly if seen.
// All classic-NetCDF numbers are big-endian (XDR), unlike every other format this app parses.
//
// Spec reference: the public "NetCDF Classic Format Specification" (nc_type tags, NC_STRING
// 4-byte-padding, record-variable striping). Verified against the real fixture: read back
// known values (site lat/lon/alt, DBZH raw int16 codes) and diffed against netCDF4-python.

export type NcType = 'byte' | 'char' | 'short' | 'int' | 'float' | 'double';
export type NcAttrValue = string | number | number[];
export type NcTypedArray =
	Int8Array | Uint8Array | Int16Array | Int32Array | Float32Array | Float64Array;

export interface NcDim {
	name: string;
	length: number;
	isRecord: boolean;
}

export interface NcVariable {
	name: string;
	dimIds: number[];
	type: NcType;
	attrs: Record<string, NcAttrValue>;
	isRecordVar: boolean;
	/** Raw (undecoded) values, no scale_factor/add_offset/_FillValue applied -- that's CF-convention interpretation, not this reader's job. */
	data: NcTypedArray;
}

export interface Netcdf3File {
	dims: NcDim[];
	globalAttrs: Record<string, NcAttrValue>;
	variables: NcVariable[];
	numRecords: number;
}

const NC_DIMENSION = 0x0a;
const NC_ATTRIBUTE = 0x0c;
const NC_VARIABLE = 0x0b;

const TYPE_BY_CODE: Record<number, NcType> = {
	1: 'byte',
	2: 'char',
	3: 'short',
	4: 'int',
	5: 'float',
	6: 'double'
};

const TYPE_SIZE: Record<NcType, number> = {
	byte: 1,
	char: 1,
	short: 2,
	int: 4,
	float: 4,
	double: 8
};

class Cursor {
	pos = 0;
	constructor(private view: DataView) {}

	u32(): number {
		const v = this.view.getUint32(this.pos, false);
		this.pos += 4;
		return v;
	}

	i32(): number {
		const v = this.view.getInt32(this.pos, false);
		this.pos += 4;
		return v;
	}

	/** NC_STRING: 4-byte length, then that many bytes, then zero-padded to a 4-byte boundary. */
	string(): string {
		const len = this.u32();
		const bytes = new Uint8Array(this.view.buffer, this.view.byteOffset + this.pos, len);
		this.pos += len + padding(len);
		return String.fromCharCode(...bytes);
	}

	bytesAt(offset: number, length: number): Uint8Array {
		return new Uint8Array(this.view.buffer, this.view.byteOffset + offset, length);
	}
}

function padding(byteLength: number): number {
	return (4 - (byteLength % 4)) % 4;
}

function readTypedValues(cursor: Cursor, type: NcType, nelems: number): number[] | string {
	const size = TYPE_SIZE[type];
	const totalBytes = nelems * size;
	const start = cursor.pos;
	cursor.pos += totalBytes + padding(totalBytes);

	if (type === 'char') {
		const bytes = cursor.bytesAt(start, nelems);
		return String.fromCharCode(...bytes).replace(/\0+$/, '');
	}

	const slice = cursor.bytesAt(start, totalBytes);
	const view = new DataView(slice.buffer, slice.byteOffset, totalBytes);
	const values: number[] = [];
	for (let i = 0; i < nelems; i++) {
		const off = i * size;
		values.push(
			type === 'byte'
				? view.getInt8(off)
				: type === 'short'
					? view.getInt16(off, false)
					: type === 'int'
						? view.getInt32(off, false)
						: type === 'float'
							? view.getFloat32(off, false)
							: view.getFloat64(off, false)
		);
	}
	return values;
}

function readAttrList(cursor: Cursor): Record<string, NcAttrValue> {
	const tag = cursor.u32();
	const nelems = cursor.u32();
	if (tag !== 0 && tag !== NC_ATTRIBUTE) {
		throw new Error(`netcdf3: expected NC_ATTRIBUTE tag, got ${tag}`);
	}
	const attrs: Record<string, NcAttrValue> = {};
	for (let i = 0; i < nelems; i++) {
		const name = cursor.string();
		const type = typeFromCode(cursor.u32());
		const attrNelems = cursor.u32();
		const values = readTypedValues(cursor, type, attrNelems);
		attrs[name] = Array.isArray(values) && values.length === 1 ? values[0] : values;
	}
	return attrs;
}

function typeFromCode(code: number): NcType {
	const type = TYPE_BY_CODE[code];
	if (!type) throw new Error(`netcdf3: unknown nc_type code ${code}`);
	return type;
}

function makeTypedArray(type: NcType, length: number): NcTypedArray {
	switch (type) {
		case 'byte':
			return new Int8Array(length);
		case 'char':
			return new Uint8Array(length);
		case 'short':
			return new Int16Array(length);
		case 'int':
			return new Int32Array(length);
		case 'float':
			return new Float32Array(length);
		case 'double':
			return new Float64Array(length);
	}
}

export function readNetcdf3(bytes: Uint8Array): Netcdf3File {
	const magic = String.fromCharCode(bytes[0], bytes[1], bytes[2]);
	const version = bytes[3];
	if (magic !== 'CDF') throw new Error('netcdf3: not a NetCDF file (bad magic)');
	if (version !== 1) {
		throw new Error(
			`netcdf3: only classic 32-bit-offset format (version 1) is supported, got version ${version}`
		);
	}

	const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
	const cursor = new Cursor(view);
	cursor.pos = 4;

	const numRecs = cursor.u32();

	const dimTag = cursor.u32();
	const dimCount = cursor.u32();
	if (dimTag !== 0 && dimTag !== NC_DIMENSION) {
		throw new Error(`netcdf3: expected NC_DIMENSION tag, got ${dimTag}`);
	}
	const dims: NcDim[] = [];
	for (let i = 0; i < dimCount; i++) {
		const name = cursor.string();
		const length = cursor.u32();
		dims.push({ name, length, isRecord: length === 0 });
	}

	const globalAttrs = readAttrList(cursor);

	const varTag = cursor.u32();
	const varCount = cursor.u32();
	if (varTag !== 0 && varTag !== NC_VARIABLE) {
		throw new Error(`netcdf3: expected NC_VARIABLE tag, got ${varTag}`);
	}

	interface VarHeader {
		name: string;
		dimIds: number[];
		attrs: Record<string, NcAttrValue>;
		type: NcType;
		vsize: number;
		begin: number;
		isRecordVar: boolean;
	}
	const varHeaders: VarHeader[] = [];
	for (let i = 0; i < varCount; i++) {
		const name = cursor.string();
		const ndims = cursor.u32();
		const dimIds: number[] = [];
		for (let d = 0; d < ndims; d++) dimIds.push(cursor.u32());
		const attrs = readAttrList(cursor);
		const type = typeFromCode(cursor.u32());
		const vsize = cursor.u32();
		const begin = cursor.i32();
		varHeaders.push({
			name,
			dimIds,
			attrs,
			type,
			vsize,
			begin,
			isRecordVar: dimIds.length > 0 && dims[dimIds[0]].isRecord
		});
	}

	const recordVars = varHeaders.filter((v) => v.isRecordVar);
	const recSize = recordVars.reduce((sum, v) => sum + v.vsize, 0);

	const variables: NcVariable[] = varHeaders.map((v) => {
		const nonRecordDims = v.isRecordVar ? v.dimIds.slice(1) : v.dimIds;
		const perRecordCount = nonRecordDims.reduce((n, id) => n * dims[id].length, 1);
		const size = TYPE_SIZE[v.type];

		const data = makeTypedArray(v.type, v.isRecordVar ? perRecordCount * numRecs : perRecordCount);
		if (v.isRecordVar) {
			for (let r = 0; r < numRecs; r++) {
				const offset = v.begin + r * recSize;
				copyInto(data, r * perRecordCount, view, offset, perRecordCount, v.type, size);
			}
		} else {
			copyInto(data, 0, view, v.begin, perRecordCount, v.type, size);
		}

		return {
			name: v.name,
			dimIds: v.dimIds,
			type: v.type,
			attrs: v.attrs,
			isRecordVar: v.isRecordVar,
			data
		};
	});

	return { dims, globalAttrs, variables, numRecords: numRecs };
}

function copyInto(
	dest: NcTypedArray,
	destOffset: number,
	view: DataView,
	byteOffset: number,
	count: number,
	type: NcType,
	size: number
): void {
	for (let i = 0; i < count; i++) {
		const off = byteOffset + i * size;
		const value =
			type === 'char'
				? view.getUint8(off)
				: type === 'byte'
					? view.getInt8(off)
					: type === 'short'
						? view.getInt16(off, false)
						: type === 'int'
							? view.getInt32(off, false)
							: type === 'float'
								? view.getFloat32(off, false)
								: view.getFloat64(off, false);
		(dest as Float64Array)[destOffset + i] = value;
	}
}

export function findVar(file: Netcdf3File, name: string): NcVariable {
	const found = file.variables.find((v) => v.name === name);
	if (!found) throw new Error(`netcdf3: variable "${name}" not found`);
	return found;
}

/** Decode a char-typed variable's flat byte data into a trimmed string (for scalar string vars, e.g. sweep_mode). */
export function ncCharsToString(v: NcVariable): string {
	return String.fromCharCode(...v.data)
		.replace(/\0+$/, '')
		.trimEnd();
}
