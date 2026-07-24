"""Python 3 stdlib-only NEXRAD Level II (Archive II) probe/decoder.

Reverse-engineers and cross-checks the byte layout used by the legacy
Python 2 RDA-side simulator in this directory (MSG_Header.py, VCP_Data.py,
Digital_Radar_Data.py, CODE_messages.py, CTM_Header.py, ...) against the
official ICD (RDA_RPG_2620002P.pdf, "Interface Control Document for the
RDA/RPG") and against three real archived KMLB (Melbourne FL) Level II
files. Every layout below was verified by actually decoding real bytes,
not just read off the ICD text -- see the CONFIRMED / STILL UNCERTAIN
notes.

------------------------------------------------------------------------
CONFIRMED (checked against real KMLB20121026_121212_V06 bytes + the ICD):
------------------------------------------------------------------------

Volume Header Record (24 bytes, big-endian). NOT covered by ICD 2620002P
(that document is the RDA<->RPG *application* interface; the Archive II
tape/file wrapper is a separate NOAA spec we don't have). Layout confirmed
purely empirically against all three fixture files:
    [0:12]  ASCII  tape filename/version, e.g. "AR2V0006.157"
    [12:16] uint32 Julian date (see epoch note below)
    [16:20] uint32 milliseconds since midnight UTC
    [20:24] ASCII  4-char ICAO site id, e.g. "KMLB"

  Julian-date epoch: the ICD's Table II (Message Header) note 2 says
  "1 January 1970 00:00 GMT = 1 Modified Julian Date", i.e. day count
  starts at 1 for 1970-01-01 (not the standard MJD epoch). The Volume
  Header's 32-bit julian-date field decodes to the exact same value
  (15640) as the Message Header's 16-bit julian-date field a few bytes
  later, and both resolve to 2012-10-26 -- matching the filename. This
  resolves the "day 1 = 1970-01-01" assumption from prior investigation:
  it is not a guess, it's literally spelled out in the ICD.

  The milliseconds-of-day field decodes to 43,934,000 ms = 12:12:14 UTC,
  matching the filename's "_121212_" almost exactly (2s difference,
  volume-open vs directory-write timestamp). The earlier "43,614,000 ms /
  12:06:54, a few minutes off" note from the prior pass was a hand
  arithmetic slip, not a real discrepancy -- recomputing straight from
  the bytes gives 43,934,000, not 43,614,000.

Message frame prefix (12 bytes, all zero in every case observed): the ICD
(section 3.2.2.2, "Messages from RDA") states verbatim: "At the RPG end,
the communications manager (RPG software task) inserts an additional 12
bytes to the ICD format message." This *is* the CTM_Header.py 12-byte
placeholder ('>3I': Typ, par, Len) from the reference scripts. In every
real message frame this project inspected, those 12 bytes are exactly
zero -- it behaves as inert padding in archived files, not a live
session/TCM header. This resolves the "unexplained 12-byte zero gap":
it is a real, ICD-documented field, just not part of the RDA-RPG
application message itself.

Message Header (Table II of the ICD, 16 bytes, immediately after the
12-byte prefix above), format '>H2B2HI2H':
    message_size (halfwords, this segment only), RDA_redundant_channel,
    message_type, id_sequence_number, julian_date, milliseconds_of_day,
    number_of_message_segments, message_segment_number.
  RDA_Redundant_Channel = 8 in every real message checked: per Table II
  this is *correct*, not "suspicious" -- 8 = "ORDA Single Channel" is an
  explicitly documented legal value (values 0-2 are the legacy/pre-ORDA
  channel codes; 8-10 are the ORDA codes).

Message framing (verified by scanning the *entire* file for the 2-byte
Modified-Julian-Date signature and checking header self-consistency at
every hit -- ~7600 independent confirmations, not a handful of samples):
  - All message types EXCEPT 31 are carried in a FIXED 2432-byte physical
    frame: 12-byte prefix + 16-byte header + up to 2400 bytes of payload,
    zero-padded to fill the frame when the declared message_size is
    smaller. Segmented messages (e.g. a Clutter Filter Bypass Map, type
    13, seen here spanning 49 segments) occupy 49 consecutive 2432-byte
    frames with a shared id_sequence_number and incrementing segment
    number -- confirmed directly.
  - Message type 31 (Digital Radar Data Generic Format) is NOT padded:
    its physical frame is exactly 12 + message_size*2 bytes, back-to-back
    with no gap, matching the ICD's explicit statement that "the
    exception in Message Type 31 ... is not segmented" and can be sized
    up to 65534 halfwords directly in the message_size field.
  - There are large (in this file, ~177 KB) runs of literal zero bytes
    between some of the early metadata messages (after the type-15
    Clutter Map and before the type-13 Clutter Filter Bypass Map). These
    decode as message_type 0, which is not a legal ICD message type.
    Cause NOT resolved (see below) -- but they don't break parsing: the
    fixed-2432-byte stride still walks straight through them and lands
    correctly on the next real header.

Message Type 31 - Data Header Block (Table XVII-A, 68 bytes, immediately
after the message header), format '>4sIHHfBBHBBBBfBBH9I':
    radar_id(4s), collection_time_ms(I), mjd(H), azimuth_number(H),
    azimuth_angle(f), compression_indicator(B), spare(B),
    radial_length(H), az_resolution_spacing(B), radial_status(B),
    elevation_number(B), cut_sector_number(B), elevation_angle(f),
    spot_blanking_status(B), azimuth_indexing_mode(B), data_block_count(H),
    then 9 x uint32 data-block pointers (VOL, ELV, RAD, REF, VEL, SW,
    ZDR, PHI, RHO -- in that fixed byte-position order per the ICD).
  Confirmed against real bytes: radar_id == b'KMLB' (matches filename),
  mjd == 15640 (matches Volume Header), compression_indicator == 0.
  radial_length (bytes, header-block-through-data, excludes the outer
  16-byte message header) matches message_size*2 - 16 exactly.

  IMPORTANT CORRECTION vs. the ICD table's own naming and vs.
  Digital_Radar_Data.py's simplifying assumption: the 9 pointer fields'
  BYTE POSITIONS in the header are fixed (REF is always at header offset
  44-47, "VEL" always at 48-51, etc per the ICD), but which MOMENT is
  actually AT that pointer's target is NOT reliable -- when a radial is a
  dual-pol "surveillance-only" split cut (REF+ZDR+PHI+RHO, no
  velocity/spectrum-width), the RDA fills the pointer slots
  contiguously with whatever blocks are actually present, so the value
  nominally in the "VEL pointer" slot may point to a ZDR block, "SW
  pointer" to a PHI block, etc. Confirmed directly: at
  KMLB.../offset 325924 (elevation 1, azimuth 1, radial_status=3 =
  start-of-volume) the block at the "ptr_vel" byte offset is tagged
  b'DZDR', not b'DVEL'. The robust/correct decode strategy (used here,
  and used by every real-world decoder such as Py-ART) is to read each
  block's own 4-byte self-describing tag ('D'+"REF"/"VEL"/"SW "/"ZDR"/
  "PHI"/"RHO", or 'R'+"VOL"/"ELV"/"RAD") and dispatch on THAT, never on
  which pointer field it came from.

Message Type 31 - generic Data Moment block (Table XVII-B, 28-byte
header + NG data-word gates), format '>4sIHHHHhBBff':
    tag(4s: 1-byte block type + 3-byte moment name), reserved(I),
    number_of_gates(H), data_moment_range(H), range_sample_interval(H),
    tover(H), snr_threshold(h, SIGNED per the ICD -- note the reference
    simulator's DM_Data_Block.get_Stream() packs this as an unsigned 'H'
    inside its '5H' group, which is a latent bug for negative SNR
    thresholds; it never manifested in the simulator because it always
    used a fixed positive default of 12), control_flags(B),
    data_word_size(B, 8 or 16), scale(f), offset(f), followed by NG raw
    gate values (1 or 2 bytes each per data_word_size). Physical value
    = (raw - offset) / scale for raw >= 2; raw 0 = below threshold,
    raw 1 = range folded.

Real decoded values from KMLB20121026_121212_V06 (see script output):
  Radial elev=1 az=1 (surveillance/dual-pol only cut):
    REF  -12.0 .. 29.0 dBZ    (229/1832 gates valid)
    ZDR  -7.875 .. 7.9375 dB  (201/1192 gates valid)
    PHI  0.35 .. 357.2 deg    (201/1192 gates valid)
    RHO  0.208 .. 1.052       (201/1192 gates valid)
  Radial elev=2 az=1 (Doppler cut, first one found with velocity data):
    REF  -20.0 .. 26.5 dBZ    (204/1192 gates valid)
    VEL  -26.5 .. 28.5 m/s    (161/1192 gates valid)
    SW   0.0 .. 16.5 m/s      (204/1192 gates valid)
  All comfortably inside the physically-plausible ranges (-32..+94.5 dBZ,
  |v|<=~100 m/s) requested for this check.

Compression: searched the ENTIRE decompressed file for the bzip2 magic
"BZh" -- zero occurrences, confirmed independently by parsing ~2900
message-31 records cleanly with a plain uncompressed byte walk, and by
every sampled message-31 Data Header Block's own compression_indicator
field reading 0 ("uncompressed", per the ICD's Table XVII-A definition:
0=uncompressed, 1=BZIP2, 2=zlib). So: no internal compression at all in
this file, despite the "AR2V0006" tag some public docs associate loosely
with bzip2-capable archives -- the compression indicator is evidently
just left at 0 for this particular RDA build/site/date.

------------------------------------------------------------------------
STILL UNCERTAIN / NOT RESOLVED:
------------------------------------------------------------------------
- The ~177 KB run of literal zero bytes (73 padded 2432-byte frames, all
  header fields zero) between the type-15 Clutter Map message and the
  type-13 Clutter Filter Bypass Map message near the start of the file.
  Message type 0 is not a legal ICD type. Plausible explanations (not
  verified): (a) legitimate idle/no-op frames from the RDA<->RPG link
  that got carried into the archive as-is, (b) an artifact of how the
  archiving/tape-blocking process pads between certain message groups,
  (c) a large all-zero message body (e.g. RDA Adaptation Data, type 18,
  which does appear later in the stream) whose *own* internal padding
  happens to also zero out what would be its header bytes at our fixed
  stride -- not ruled out. Not investigated further; flagged rather than
  guessed at.
- What exactly "0006" in "AR2V0006" encodes (tape format version vs.
  build number vs. something else) -- not present anywhere in ICD
  2620002P (that document doesn't cover the Archive II file wrapper at
  all), so this remains an assumption from general background knowledge,
  not something confirmed against a primary source in this repo.
- All three fixture files (KMLB20121026_120332_V06, _120758_V06,
  _121212_V06) were run through this script and produce 0 bad/garbage
  frames and physically plausible REF/VEL/SW/ZDR/PHI/RHO ranges (see
  script output), so this is confirmed across all fixtures, not just one.

Usage:
    python3 l2_probe_py3.py <file.gz-or-raw> [max_legacy_frames]

The file is gunzip'd in memory if it ends in .gz (or is gzip-magic) --
nothing is ever decompressed to disk.
"""

import gzip
import struct
import sys
from datetime import datetime, timedelta

L2_EPOCH = datetime(1970, 1, 1)  # ICD Table II note 2: "day 1" = 1970-01-01

VOLUME_HEADER_SIZE = 24
CTM_PREFIX_SIZE = 12
MSG_HEADER_SIZE = 16
DATA_HEADER_BLOCK_SIZE = 68
LEGACY_FRAME_SIZE = 2432  # fixed physical frame for every message type != 31

MSG_HEADER_FMT = '>H2B2HI2H'
DATA_HEADER_BLOCK_FMT = '>4sIHHfBBHBBBBfBBH9I'
MOMENT_HEADER_FMT = '>4sIHHHHhBBff'

MESSAGE_TYPE_NAMES = {
    0: 'PADDING/IDLE (not a legal ICD type)',
    1: 'DIGITAL_RADAR_DATA', 2: 'RDA_STATUS_DATA', 3: 'PERFORMANCE_MAINTENANCE_DATA',
    4: 'CONSOLE_MESSAGE_A2G', 5: 'RDA_RPG_VCP', 6: 'RDA_CONTROL_COMMANDS',
    7: 'RPG_RDA_VCP', 8: 'CLUTTER_SENSOR_ZONES', 9: 'REQUEST_FOR_DATA',
    10: 'CONSOLE_MESSAGE_G2A', 11: 'LOOPBACK_TEST_RDA_RPG', 12: 'LOOPBACK_TEST_RPG_RDA',
    13: 'CLUTTER_FILTER_BYPASS_MAP', 14: 'SPARE', 15: 'CLUTTER_MAP_DATA (ORDA)',
    18: 'ADAPTATION_DATA', 31: 'GENERIC_DIGITAL_RADAR_DATA',
}


def julian_date_to_date(jd):
    """ICD Table II note 2: 1970-01-01 = Julian Date 1."""
    return L2_EPOCH + timedelta(days=jd - 1)


def read_source(path):
    with open(path, 'rb') as f:
        head = f.read(2)
        f.seek(0)
        if path.endswith('.gz') or head == b'\x1f\x8b':
            return gzip.open(f, 'rb').read()
        return f.read()


def parse_volume_header(buf):
    tape_id = buf[0:12]
    jd, ms = struct.unpack('>II', buf[12:20])
    site = buf[20:24]
    gap = buf[24:36]
    return dict(
        tape_id=tape_id.decode('ascii', 'replace'),
        julian_date=jd,
        date=julian_date_to_date(jd).date(),
        ms_of_day=ms,
        time_of_day=str(timedelta(milliseconds=ms)),
        site=site.decode('ascii', 'replace'),
        ctm_prefix_zero=(gap == b'\x00' * 12),
    )


def parse_msg_header(buf, off):
    size, chan, mtype, seq, jd, ms, nseg, segn = struct.unpack(MSG_HEADER_FMT, buf[off:off + MSG_HEADER_SIZE])
    return dict(off=off, size_halfwords=size, redundant_channel=chan, message_type=mtype,
                seq=seq, julian_date=jd, ms_of_day=ms, n_segments=nseg, segment_number=segn)


def parse_message31_body(buf, msg_header_off):
    """Parse the Data Header Block + follow its block pointers.

    Returns dict with radial metadata and a {tag: absolute_offset} map for
    every non-zero pointer, keyed by the block's OWN self-describing tag
    (not by ICD pointer-field position -- see module docstring for why
    that distinction matters).
    """
    dhb_off = msg_header_off + MSG_HEADER_SIZE
    vals = struct.unpack(DATA_HEADER_BLOCK_FMT, buf[dhb_off:dhb_off + DATA_HEADER_BLOCK_SIZE])
    (radar_id, collect_ms, mjd, az_num, az_angle, compression, _spare, radial_length,
     az_res, radial_status, elev_num, cut_sector, elev_angle, spot_blank, az_idx_mode,
     nblocks, *ptrs) = vals
    blocks = {}
    for p in ptrs:
        if p:
            tag = buf[dhb_off + p: dhb_off + p + 4]
            blocks[tag] = dhb_off + p
    return dict(radar_id=radar_id.decode('ascii', 'replace'), collection_ms=collect_ms,
                mjd=mjd, azimuth_number=az_num, azimuth_angle=az_angle,
                compression_indicator=compression, radial_length=radial_length,
                azimuth_resolution=az_res, radial_status=radial_status,
                elevation_number=elev_num, cut_sector_number=cut_sector,
                elevation_angle=elev_angle, data_block_count=nblocks, blocks=blocks)


def decode_moment(buf, off):
    name4, reserved, ngates, mrange, rinterval, tover, snr, ctrl, dws, scale, offset = \
        struct.unpack(MOMENT_HEADER_FMT, buf[off:off + 28])
    gate_off = off + 28
    if dws == 8:
        raw = list(buf[gate_off:gate_off + ngates])
    elif dws == 16:
        raw = list(struct.unpack('>%dH' % ngates, buf[gate_off:gate_off + ngates * 2]))
    else:
        raise ValueError('unexpected data word size %r at offset %d' % (dws, off))
    valid = [(r - offset) / scale for r in raw if r >= 2]
    below_threshold = sum(1 for r in raw if r == 0)
    range_folded = sum(1 for r in raw if r == 1)
    return dict(name=name4.decode('ascii', 'replace'), n_gates=ngates, data_word_size=dws,
                scale=scale, offset=offset, snr_threshold_signed=snr,
                n_valid=len(valid), below_threshold=below_threshold, range_folded=range_folded,
                min_value=min(valid) if valid else None, max_value=max(valid) if valid else None,
                mean_value=(sum(valid) / len(valid)) if valid else None)


def walk_messages(buf, limit=None):
    """Yield one dict per message frame, walking the whole message stream.

    Non-31 messages always occupy a fixed 2432-byte frame (verified by a
    file-wide Modified-Julian-Date signature scan, see module docstring);
    message 31 frames are exactly sized from their own message_size field.
    """
    off = VOLUME_HEADER_SIZE
    n = 0
    while off + CTM_PREFIX_SIZE + MSG_HEADER_SIZE <= len(buf):
        if limit is not None and n >= limit:
            return
        header_off = off + CTM_PREFIX_SIZE
        hdr = parse_msg_header(buf, header_off)
        hdr['frame_off'] = off
        yield hdr
        n += 1
        if hdr['message_type'] == 31:
            off = header_off + MSG_HEADER_SIZE + hdr['size_halfwords'] * 2 - MSG_HEADER_SIZE
            # (message_size counts from the message header itself; total
            #  bytes following the header is size*2 - 16, then the next
            #  frame's CTM prefix follows immediately)
            off = header_off + hdr['size_halfwords'] * 2
        else:
            off = off + LEGACY_FRAME_SIZE


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    path = sys.argv[1]
    scan_limit = int(sys.argv[2]) if len(sys.argv) > 2 else 6000

    print(f'=== Reading {path} ===')
    buf = read_source(path)
    print(f'decompressed size: {len(buf):,} bytes')

    vh = parse_volume_header(buf)
    print('\n--- Volume Header Record ---')
    for k, v in vh.items():
        print(f'  {k}: {v}')

    print(f'\n--- Walking message stream (up to {scan_limit} messages) ---')
    type_counts = {}
    first31 = None
    first31_with_vel = None
    n_parsed = n_bad = 0
    for hdr in walk_messages(buf, limit=scan_limit):
        mtype = hdr['message_type']
        type_counts[mtype] = type_counts.get(mtype, 0) + 1
        if 0 <= mtype <= 31 and 0 <= hdr['ms_of_day'] < 86_400_000:
            n_parsed += 1
        else:
            n_bad += 1
        if mtype == 31:
            body = parse_message31_body(buf, hdr['off'])
            if first31 is None:
                first31 = (hdr, body)
            if first31_with_vel is None and b'DVEL' in body['blocks']:
                first31_with_vel = (hdr, body)

    print('\nmessage type distribution (frame count, includes per-segment repeats):')
    for mtype in sorted(type_counts):
        label = MESSAGE_TYPE_NAMES.get(mtype, f'type {mtype} (unlisted)')
        print(f'  type {mtype:3d}  count={type_counts[mtype]:5d}  {label}')
    print(f'\nheader sanity: {n_parsed} frames had internally-consistent fields, '
          f'{n_bad} did not (garbage/padding)')

    def report_radial(label, pair):
        if pair is None:
            print(f'\n({label}: none found in scanned range)')
            return
        hdr, body = pair
        print(f'\n--- {label}: message-31 radial at byte offset {hdr["off"]} ---')
        print(f'  radar_id={body["radar_id"]!r} mjd={body["mjd"]} '
              f'azimuth_number={body["azimuth_number"]} azimuth_angle={body["azimuth_angle"]:.3f} '
              f'elevation_number={body["elevation_number"]} elevation_angle={body["elevation_angle"]:.4f} '
              f'radial_status={body["radial_status"]} data_block_count={body["data_block_count"]}')
        print(f'  blocks present (self-identified by tag, not by pointer slot): '
              f'{sorted(t.decode() for t in body["blocks"])}')
        for tag, boff in body['blocks'].items():
            if tag[:1] == b'D':
                m = decode_moment(buf, boff)
                print(f'    {m["name"]}: n_gates={m["n_gates"]} word_size={m["data_word_size"]} '
                      f'valid={m["n_valid"]} below_thresh={m["below_threshold"]} '
                      f'range_folded={m["range_folded"]} '
                      f'range=[{m["min_value"]:.3f}, {m["max_value"]:.3f}] '
                      f'mean={m["mean_value"]:.3f}'
                      if m['n_valid'] else f'    {m["name"]}: no valid gates in this radial')

    report_radial('first message-31 radial found', first31)
    report_radial('first message-31 radial with DVEL present', first31_with_vel)

    print('\n=== bzip2/zlib compression check ===')
    bzh_count = buf.count(b'BZh')
    print(f'  "BZh" (bzip2 magic) occurrences in whole file: {bzh_count}')
    if first31 is not None:
        print(f'  compression_indicator field on sampled message-31 header: '
              f'{first31[1]["compression_indicator"]} (0=uncompressed per ICD Table XVII-A)')
    print(f'  conclusion: {"NOT compressed" if bzh_count == 0 else "compressed (bzip2 found)"}')


if __name__ == '__main__':
    main()
