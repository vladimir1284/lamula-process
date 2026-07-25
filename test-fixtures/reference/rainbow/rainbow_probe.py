"""Python 3 stdlib-only Rainbow5 (.vol) probe/decoder.

No legacy Delphi source for this format was vendored: Process.dpr references
`Rainbow5_Translator.pas` and `Rainbow5_File.pas` (see legacy/Process.dpr), but
neither file ships in legacy/. The oracle here is xradar's reader instead
(github.com/openradar/xradar, xradar/io/backends/rainbow.py), cross-checked
against the real fixtures in test-fixtures/observations/rainbow/{bandaS,bandaX}:
bandaS = site "HNS"/Tegucigalpa, S-band (wavelen 0.10452m), 15 elevations,
one file per moment (dBZ/dBuZ/V/W); bandaX = site "HNX"/La Ceiba, X-band
(wavelen 0.03189m), 4 elevations, one file per moment (dBZ/dBuZ/V/W/RhoHV/
uPhiDP). All 10 files decode cleanly end to end with this script -- see
CONFIRMED section for the physically-plausible ranges obtained.

------------------------------------------------------------------------
CONFIRMED (checked against real bandaS/bandaX bytes):
------------------------------------------------------------------------

Container: an XML header (single <volume> root), followed by the literal
line `<!-- END XML -->`, followed by a flat sequence of binary blobs:

    <BLOB blobid="N" size="S" compression="qt">\n<S bytes of payload>\n</BLOB>

blobid is a single counter across the WHOLE file (not reset per slice/sweep):
slice 0 uses blobid 0,1,2; slice 1 uses 3,4,5; etc. There is exactly one
literal '\n' between the tag's '>' and the payload, one before the closing
'</BLOB>', AND one more between '</BLOB>' and the next '<BLOB' tag (or EOF)
-- confirmed byte-for-byte, not inferred from the ICD-style docs alone.

compression="qt": first 4 bytes of the payload are a big-endian uint32
uncompressed size, the rest is a raw zlib stream (`zlib.decompress`). No
other compression value observed in these fixtures.

XML structure relevant to decoding (from a real bandaS dBZ.vol):
    volume[@datetime,@version] > scan[@name] (one scan per file)
    volume > sensorinfo (SIBLING of scan, not nested inside it -- confirmed
        by real byte layout, closing </scan> appears before <sensorinfo>):
        lon/lat/alt/wavelen/beamwidth, confirmed site "HNS"/Tegucigalpa,
        lon=-87.13, lat=13.91, alt=1997m, wavelen=0.10452m i.e. S-band
    volume > scan > slice[@refid] (one per elevation sweep, numele of them
        per pargroup) > posangle (elevation angle, degrees, confirmed
        0.5 for slice refid=1 in bandaS matching pargroup/firstele=0 /
        anglestep=1) > dynz/dynv/dynw (min/max per moment family) >
        slicedata > rayinfo x2 (refid="startangle"/"stopangle", own blobid,
        depth, no min/max) + rawdata (own blobid, @rays, @bins, @type,
        @min, @max, @depth)

rayinfo (ray angle) decode: raw uint16 (only depth=16 observed) -> degrees
via `raw * 360.0 / 65536.0` (i.e. divide by 2**depth, NOT 2**depth-2 --
this is a different formula from rawdata below, confirmed by the decoded
sequence stepping ~1.0 deg apart matching pargroup/anglestep=1 exactly,
e.g. bandaS slice refid=1 startangle blob: 68.027, 69.027, 70.021, ...).

rawdata (moment data) decode: raw uint8 or uint16 (both observed: depth=8
for dBZ/dBuZ/V/W/RhoHV, depth=16 for uPhiDP in these fixtures; sub-byte
depths, e.g. 6-bit, are documented by xradar's reader but NOT exercised by
any fixture here -- flagged, not verified). raw=0 means no-data/below
threshold (excluded from stats below). For raw >= 1:

    scale = (vmax - vmin) / (2**depth - 2)
    physical = vmin + (raw - 1) * scale

This is NOT the naive `vmin + raw*scale` -- that shifts every value by
half a step. Confirmed empirically: bandaS dBZ slice 0 has real occurrences
of raw==1 (the minimum non-zero raw value in that sweep), and this formula
maps raw==1 to EXACTLY vmin (-31.5 dBZ, the slice's own declared dynz min)
to 3+ decimal places, which is too exact to be coincidence. This matches
xradar's own `scale_factor=(vmax-vmin)/(2**depth-2)`,
`add_offset=vmin-scale_factor`, `physical=raw*scale_factor+add_offset`
(algebraically identical to the formula above).

Confirmed decoded ranges (run this script on all 10 fixtures to reproduce),
all physically plausible and within each moment's own declared [min,max]:
    bandaS dBZ, 15 elevations 0.0-30.0 deg: phys ranges from [-31.5,56.0]
        (lowest tilt) down to [-31.5,3.0] (highest tilt) dBZ
    bandaS V: symmetric around 0, e.g. [-47.5,46.75] m/s at the 7 deg tilt
    bandaX (smaller, closer-in X-band volume) dBZ: [-31.5,40.5]..
        [-31.5,49.0] dBZ across its 4 elevations (1.3-5.0 deg)
    bandaX RhoHV: [0.008,1.0]..[0.02,1.0] -- inside declared [0,1]
    bandaX uPhiDP (the only depth=16 rawdata in these fixtures):
        [0.05,359.96]..[0.21,359.9] -- inside declared [0,360]
    All rawdata blobs decompress to exactly rays*bins bytes (depth=8) or
        rays*bins*2 bytes (depth=16) -- no padding, no ragged rows.

------------------------------------------------------------------------
STILL UNCERTAIN / NOT RESOLVED:
------------------------------------------------------------------------
- Sub-byte @depth (e.g. 6-bit) and the associated bit-packing/unpackbits
  path that xradar's reader has code for: not present in any fixture here,
  so the packing details (padding to a byte boundary, MSB vs LSB first)
  are NOT independently confirmed against real bytes in this project.
- compression values other than "qt" (e.g. uncompressed blobs): not seen
  in these fixtures, handled defensively below but unverified.
- Whether raw==1 in a moment where the true minimum physical value is
  itself the sentinel-adjacent value (e.g. RhoHV min=0) is distinguishable
  from genuine no-data: same ambiguity as the .obs/Level II probes' "0 vs
  real minimum" caveats, not resolved here either.

Usage:
    python3 rainbow_probe.py <file.vol> [<file2.vol> ...]
"""

import re
import struct
import sys
import zlib
import xml.etree.ElementTree as ET

END_XML_MARKER = b'<!-- END XML -->'
BLOB_TAG_RE = re.compile(rb'<BLOB blobid="(\d+)" size="(\d+)" compression="(\w*)">')
BLOB_CLOSE = b'\n</BLOB>'


def split_header(buf):
    marker = buf.index(END_XML_MARKER)
    header_xml = buf[:marker]
    blobs_start = marker + len(END_XML_MARKER)
    if buf[blobs_start:blobs_start + 1] == b'\n':
        blobs_start += 1
    return header_xml, blobs_start


def read_blobs(buf, start):
    """Sequentially walk every <BLOB blobid=.. size=.. compression=..>...</BLOB>
    block from `start` to EOF, keyed by blobid (a single counter across the
    whole file, see module docstring). Returns {blobid: decompressed_bytes}.
    """
    blobs = {}
    off = start
    while off < len(buf):
        m = BLOB_TAG_RE.match(buf, off)
        if not m:
            break
        blobid, size, comp = int(m.group(1)), int(m.group(2)), m.group(3).decode()
        tagend = m.end()
        assert buf[tagend:tagend + 1] == b'\n', (
            f'blob {blobid}: expected newline right after tag, got {buf[tagend:tagend + 1]!r}')
        payload_off = tagend + 1
        raw = buf[payload_off:payload_off + size]
        closing = buf[payload_off + size:payload_off + size + len(BLOB_CLOSE)]
        assert closing == BLOB_CLOSE, f'blob {blobid}: unexpected closing bytes {closing!r}'
        if comp == 'qt':
            usize = struct.unpack('>I', raw[:4])[0]
            data = zlib.decompress(raw[4:])
            assert len(data) == usize, f'blob {blobid}: usize mismatch {len(data)} != {usize}'
        elif comp in ('', 'none'):
            data = raw
        else:
            raise ValueError(f'blob {blobid}: unhandled compression {comp!r}')
        blobs[blobid] = data
        off = payload_off + size + len(BLOB_CLOSE)
        if buf[off:off + 1] == b'\n':
            off += 1
    return blobs


def decode_rayinfo(data, depth):
    if depth != 16:
        raise ValueError(f'rayinfo depth {depth} not exercised by any fixture, refusing to guess')
    n = len(data) // 2
    vals = struct.unpack('>%dH' % n, data[:n * 2])
    return [v * 360.0 / 65536.0 for v in vals]


def decode_rawdata(data, rays, bins_, depth, vmin, vmax):
    n = rays * bins_
    if depth == 8:
        raw = list(data[:n])
    elif depth == 16:
        raw = list(struct.unpack('>%dH' % n, data[:n * 2]))
    else:
        raise ValueError(f'rawdata depth {depth} (sub-byte packing) not exercised by any fixture')
    scale = (vmax - vmin) / (2 ** depth - 2)
    phys = [None if r == 0 else vmin + (r - 1) * scale for r in raw]
    return raw, phys


def probe(path):
    with open(path, 'rb') as f:
        buf = f.read()

    print(f'=== {path} ({len(buf):,} bytes) ===')
    header_xml, blobs_start = split_header(buf)
    root = ET.fromstring(header_xml.decode('latin-1'))
    blobs = read_blobs(buf, blobs_start)
    print(f'volume: datetime={root.get("datetime")} version={root.get("version")} '
          f'blobs found={len(blobs)}')

    scan = root.find('scan')
    sensorinfo = root.find('sensorinfo')
    print(f'scan name={scan.get("name")!r} site={sensorinfo.get("id")}/{sensorinfo.get("name")} '
          f'lon={sensorinfo.findtext("lon")} lat={sensorinfo.findtext("lat")} '
          f'alt={sensorinfo.findtext("alt")}m wavelen={sensorinfo.findtext("wavelen")}m')

    slices = scan.findall('slice')
    print(f'{len(slices)} slice(s) (elevation sweeps)')

    for sl in slices:
        posangle = sl.findtext('posangle')
        sd = sl.find('slicedata')
        rawdata_el = sd.find('rawdata')
        rayinfo_els = sd.findall('rayinfo')

        rays = int(rawdata_el.get('rays'))
        bins_ = int(rawdata_el.get('bins'))
        depth = int(rawdata_el.get('depth'))
        vmin = float(rawdata_el.get('min'))
        vmax = float(rawdata_el.get('max'))
        mtype = rawdata_el.get('type')
        blobid = int(rawdata_el.get('blobid'))

        raw, phys = decode_rawdata(blobs[blobid], rays, bins_, depth, vmin, vmax)
        valid = [p for p in phys if p is not None]

        start_angles = stop_angles = None
        for ri in rayinfo_els:
            angs = decode_rayinfo(blobs[int(ri.get('blobid'))], int(ri.get('depth')))
            if ri.get('refid') == 'startangle':
                start_angles = angs
            elif ri.get('refid') == 'stopangle':
                stop_angles = angs

        print(
            f'  slice refid={sl.get("refid")} elev={posangle} deg  type={mtype} '
            f'rays={rays} bins={bins_} depth={depth}  '
            f'az=[{start_angles[0]:.2f}..{start_angles[-1]:.2f}] (n={len(start_angles)})  '
            f'valid={len(valid)}/{rays * bins_}  '
            f'phys=[{min(valid):.3f},{max(valid):.3f}]' if valid else
            f'  slice refid={sl.get("refid")} elev={posangle} deg  type={mtype} no valid gates'
        )
    print()


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    for path in sys.argv[1:]:
        probe(path)
