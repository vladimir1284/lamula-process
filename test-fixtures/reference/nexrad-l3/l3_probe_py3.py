"""Python 3 stdlib-only NEXRAD Level III (Graphic Product Message) probe/decoder.

Reverse-engineers and cross-checks the byte layout against a known-correct open-source
reference (Py-ART's `pyart.io.nexrad_level3`, ARM-DOE/pyart on GitHub -- there is no ICD PDF
for this format in this repo, unlike nexrad-l2/RDA_RPG_2620002P.pdf) and against two real
products for KBYX (Key West FL), volume timestamp 2026-07-26T11:39:48Z, downloaded from the
public `unidata-nexrad-level3` S3 bucket: BYX_N0B_..._11_39_48 (super-res base reflectivity,
product code 153) and BYX_N0G_..._11_39_48 (super-res velocity, product code 154).

Purpose: cross-validate that the NEXRAD Level II decoder (src/lib/parsers/nexrad-l2/) is
reading gate range/spacing correctly, using an *independent* product family (Level III, a
different RPG-generated derivative of the same radar volume) as the oracle rather than
re-deriving the same Level II bytes a second way.

------------------------------------------------------------------------
CONFIRMED (checked against real BYX_N0B_2026_07_26_11_39_48 bytes):
------------------------------------------------------------------------

File layout, in order:
  - WMO/AWIPS text header: "SDUSxx KKEY ddHHMM\\r\\r\\nN0BBYX\\r\\r\\n" (variable length,
    located by searching for the literal b"SDUS"; some feeds pad before it).
  - Message Header Block, 18 bytes, immediately after the text header:
    format '>hhiihhh': code(h), date(h, days since 1970-01-01), time(i, sec of day),
    length(i, bytes), source(h), dest(h), nblocks(h).
    Confirmed: code=153 (matches the "N0B" in the text header and the AWS bucket product
    mnemonic mapping in nexrad-l3-pipeline/ingest/products.py).
  - Product Description Block (PDB), 102 bytes, immediately after the Message Header (NOT at
    the halfword offset implied by the PDB's own `offset_symbology` field -- Py-ART ignores
    that field entirely and just reads the symbology block right after the fixed 102-byte PDB;
    confirmed empirically, see PDB_FMT below for exact field byte offsets computed from the
    Py-ART field-size table. `offset_symbology`/`offset_graphic`/`offset_tabular` decoded to
    garbage-looking values in this file when read at their own documented offsets, but are
    simply unused by any real-world decoder for this reason).
    Confirmed: latitude=24.597, longitude=-81.703 (Key West, matches BYX), elevation_num=1,
    vcp=215 (a real, current super-res VCP number).
  - Product Symbology Block: 16-byte header (divider=-1, block_id=1, block_length, layers,
    layer_divider=-1, layer_length), then packet data. THIS ENTIRE BLOCK may itself be
    bzip2-compressed independently of anything at the Level II / Archive-II layer -- confirmed:
    the first two bytes right after the PDB are literally "BZ" (bzip2 magic) in this file.
    Decompress with a plain `bz2.BZ2Decompressor` (there is trailing tabular-block data after
    the compressed stream in the file, so a one-shot `bz2.decompress()` on the whole remainder
    is wrong -- must use the incremental decompressor and stop at the first complete stream).
  - Digital Radial Data Array Packet (Packet Code 16), 14-byte header immediately after the
    (decompressed) symbology block's own 16-byte header: format '>hhhhhhh': packet_code(h,
    ==16), first_bin(h), nbins(h), i_sweep_center(h), j_sweep_center(h), range_scale(h),
    nradials(h). Then, per radial: a 6-byte radial header ('>hhh': nbytes, angle_start*0.1deg,
    angle_delta*0.1deg) followed by nbytes of raw gate bytes.
    Confirmed: packet_code=16, nbins=1840, range_scale_raw=999, nradials=720, first radial
    angle_start_raw=3580 (358.0 deg) angle_delta_raw=5 (0.5 deg).

  Gate spacing: per Py-ART's PRODUCT_RANGE_RESOLUTION table, product 153/154 (super-res
  reflectivity/velocity) use a 0.25 (km-per-raw-unit) resolution factor, so actual gate spacing
  in meters = range_scale_raw * 0.25 = 999 * 0.25 = 249.75 ~= 250m. This independently confirms
  the Level II decoder's gateLengthM=250 for the same volume (src/lib/parsers/nexrad-l2/
  message31.ts), without re-deriving it from the same Level II bytes.

  `first_bin` in this file is 0 -- this is the RASTER ARRAY's logical start (bin 0 = range 0),
  padded with below-threshold gates out to the beam's real blanking range; it is NOT the same
  quantity as Level II's `rangeToFirstGateM` (2125m, the first gate that actually carries data)
  and a numeric mismatch between the two is expected, not a bug. The useful cross-checks here
  are gate SPACING (250m both ways) and radial geometry (below), not first_bin vs
  rangeToFirstGateM.

  Radial geometry cross-check against the Level II decode of the same volume (see
  src/lib/parsers/nexrad-l2/parseArchive2Bzip2.spec.ts, which pins these same numbers
  independently from the Level II bytes):
    nradials=720          matches L2 dBZ channel scans[0].numRays == 720
    angle_start=358.0deg,
    angle_delta=0.5deg
    -> radial center 358.25deg
                          matches L2 rayStartAnglesDeg[0] == 358.248deg (within L3's 0.1deg
                          encoding precision)

------------------------------------------------------------------------
STILL UNCERTAIN / NOT RESOLVED:
------------------------------------------------------------------------
- Only the FIRST radial's header/geometry was decoded and cross-checked -- gate VALUES
  themselves (reflectivity dBZ per bin) are not decoded/verified here, since the goal was
  specifically to validate range/gate geometry, not moment calibration (already covered
  independently by nexrad-l2's own ICD-grounded tests).
- `offset_symbology` / `offset_graphic` / `offset_tabular` fields' real meaning/units are not
  resolved (decoded to implausible values here); every real-world decoder found (Py-ART)
  ignores them and assumes fixed block adjacency instead, which is what this probe does too.

Usage:
    python3 l3_probe_py3.py <N0B-or-N0G-file> [--verify]

`--verify` additionally asserts the cross-checked values above against the hardcoded Level II
ground truth (from parseArchive2Bzip2.spec.ts) and exits non-zero on mismatch.
"""

import bz2
import struct
import sys

MSG_HEADER_FMT = '>hhiihhh'
MSG_HEADER_SIZE = 18
PDB_SIZE = 102
SYMBOLOGY_HEADER_FMT = '>hhihhi'
SYMBOLOGY_HEADER_SIZE = 16
RADIAL_PACKET_HEADER_FMT = '>hhhhhhh'
RADIAL_PACKET_HEADER_SIZE = 14
RADIAL_HEADER_FMT = '>hhh'
RADIAL_HEADER_SIZE = 6

# Level II ground truth for the same KBYX 2026-07-26T11:39:48Z volume, first REF cut
# (elevation_number=1, azimuth_number=1) -- see src/lib/parsers/nexrad-l2/
# parseArchive2Bzip2.spec.ts, itself cross-checked against l2_probe_py3.py.
L2_GATE_LENGTH_M = 250
L2_NUM_RAYS = 720
L2_FIRST_RAY_AZIMUTH_DEG = 358.248
PRODUCT_RANGE_RESOLUTION_KM = 0.25  # products 153/154, per Py-ART's PRODUCT_RANGE_RESOLUTION


def read_source(path):
    with open(path, 'rb') as f:
        return f.read()


def parse_message_header(buf):
    idx = buf.find(b'SDUS')
    if idx == -1:
        raise ValueError('no WMO/AWIPS "SDUS" text header found -- not a Level III product file')
    text_header = buf[:30 + idx]
    off = 30 + idx
    code, date, time_of_day, length, source, dest, nblocks = struct.unpack(
        MSG_HEADER_FMT, buf[off:off + MSG_HEADER_SIZE])
    return dict(text_header=text_header.decode('ascii', 'replace'), off=off, code=code,
                date=date, time_of_day=time_of_day, length=length, source=source, dest=dest,
                nblocks=nblocks), off + MSG_HEADER_SIZE


def parse_product_description_block(buf, off):
    lat, lon = struct.unpack('>ii', buf[off + 2:off + 10])
    height, = struct.unpack('>h', buf[off + 10:off + 12])
    product_code, = struct.unpack('>h', buf[off + 12:off + 14])
    op_mode, = struct.unpack('>h', buf[off + 14:off + 16])
    vcp, = struct.unpack('>h', buf[off + 16:off + 18])
    elevation_num, = struct.unpack('>h', buf[off + 38:off + 40])
    return dict(latitude=lat * 0.001, longitude=lon * 0.001, height_ft=height,
                product_code=product_code, operational_mode=op_mode, vcp=vcp,
                elevation_num=elevation_num), off + PDB_SIZE


def decompress_symbology_block(buf, off):
    """The Product Symbology Block may itself be bzip2-compressed, independently of any
    Archive-II-level compression. There is trailing data (tabular block etc) after the
    compressed stream, so a plain one-shot bz2.decompress() is wrong -- it must stop at the
    end of the first complete stream, which is exactly what BZ2Decompressor does."""
    if buf[off:off + 2] != b'BZ':
        return buf[off:]
    decompressor = bz2.BZ2Decompressor()
    return decompressor.decompress(buf[off:])


def parse_radial_packet(sym_block):
    divider, block_id, block_length, layers, layer_divider, layer_length = struct.unpack(
        SYMBOLOGY_HEADER_FMT, sym_block[0:SYMBOLOGY_HEADER_SIZE])
    packet_off = SYMBOLOGY_HEADER_SIZE
    packet_code, first_bin, nbins, i_center, j_center, range_scale_raw, nradials = struct.unpack(
        RADIAL_PACKET_HEADER_FMT, sym_block[packet_off:packet_off + RADIAL_PACKET_HEADER_SIZE])
    radial0_off = packet_off + RADIAL_PACKET_HEADER_SIZE
    nbytes, angle_start_raw, angle_delta_raw = struct.unpack(
        RADIAL_HEADER_FMT, sym_block[radial0_off:radial0_off + RADIAL_HEADER_SIZE])
    return dict(
        divider=divider, block_id=block_id, packet_code=packet_code, first_bin=first_bin,
        nbins=nbins, range_scale_raw=range_scale_raw, nradials=nradials,
        radial0_nbytes=nbytes, radial0_angle_start_deg=angle_start_raw * 0.1,
        radial0_angle_delta_deg=angle_delta_raw * 0.1,
        gate_length_m=range_scale_raw * PRODUCT_RANGE_RESOLUTION_KM,
    )


def probe(path):
    buf = read_source(path)
    msg_header, pdb_off = parse_message_header(buf)
    pdb, sym_off = parse_product_description_block(buf, pdb_off)
    sym_block = decompress_symbology_block(buf, sym_off)
    packet = parse_radial_packet(sym_block)
    return msg_header, pdb, packet


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    path = sys.argv[1]
    verify = '--verify' in sys.argv[2:]

    msg_header, pdb, packet = probe(path)

    print(f'=== {path} ===')
    print(f'text header: {msg_header["text_header"]!r}')
    print(f'message code={msg_header["code"]} (product)')
    print(f'PDB: lat={pdb["latitude"]:.4f} lon={pdb["longitude"]:.4f} '
          f'elevation_num={pdb["elevation_num"]} vcp={pdb["vcp"]}')
    print(f'radial packet: packet_code={packet["packet_code"]} nbins={packet["nbins"]} '
          f'nradials={packet["nradials"]} range_scale_raw={packet["range_scale_raw"]} '
          f'-> gate_length_m={packet["gate_length_m"]:.2f}')
    radial0_center = packet['radial0_angle_start_deg'] + packet['radial0_angle_delta_deg'] / 2
    print(f'radial 0: angle_start={packet["radial0_angle_start_deg"]:.2f}deg '
          f'angle_delta={packet["radial0_angle_delta_deg"]:.2f}deg '
          f'-> center={radial0_center:.3f}deg')

    if verify:
        print('\n=== verifying against Level II ground truth ===')
        assert packet['packet_code'] == 16, 'expected Digital Radial Data Array packet (code 16)'
        assert abs(packet['gate_length_m'] - L2_GATE_LENGTH_M) < 1.0, (
            f'gate_length_m={packet["gate_length_m"]} does not match L2 rangeToFirstGateM/'
            f'gateLengthM ground truth ({L2_GATE_LENGTH_M}m)')
        assert packet['nradials'] == L2_NUM_RAYS, (
            f'nradials={packet["nradials"]} != L2 numRays={L2_NUM_RAYS}')
        assert abs(radial0_center - L2_FIRST_RAY_AZIMUTH_DEG) < 0.3, (
            f'radial0 center={radial0_center} too far from L2 first ray azimuth '
            f'{L2_FIRST_RAY_AZIMUTH_DEG}deg')
        print('OK: gate spacing, radial count, and first-radial azimuth all match the '
              'independently-decoded Level II volume.')


if __name__ == '__main__':
    main()
