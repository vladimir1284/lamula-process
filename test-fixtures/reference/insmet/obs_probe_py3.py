"""Python 3 stdlib-only re-derivation of the .obs layout in Obs_Parser.py.

Obs_Parser.py is Python 2 and reads with native (unaligned-by-platform)
struct mode, which only decodes correctly on the 32-bit environment it was
originally run on. On 64-bit Python it silently produces garbage (double
fields get 8-byte alignment instead of the original 4-byte Delphi record
alignment). This uses explicit '<' (packed, no auto-align) plus the real
padding bytes physically present in the file, verified against all four
fixtures here with 0 decompression failures. See docs/formatos.md for the
resulting byte-layout table.

Usage: python3 obs_probe_py3.py <file.obs> [<file2.obs> ...]
"""

import struct
import sys
import zlib
from datetime import datetime, timedelta

OLE_TIME_ZERO = datetime(1899, 12, 30, 0, 0, 0)
PPI_DESC_SIZE = 28
PPI_HEADER_SIZE = 12

D_RADAR = {
    0: 'rdNone', 1: 'rdLaBajada', 2: 'rdPuntaDelEste', 3: 'rdCasablanca',
    4: 'rdPicoSanJuan', 5: 'rdCamaguey', 6: 'rdPilon', 7: 'rdGranPiedra',
    8: 'rdMcGill', 9: 'rdRoma', 10: 'rdCP2_SCMS', 11: 'rdHolguin',
    12: 'rdVenMaracaibo', 13: 'rdVenJeremba', 14: 'rdVenGuasdualito',
    15: 'rdVenAyacucho', 16: 'rdVenCarupano', 17: 'rdVenKarum',
    18: 'rdVenSantaElena', 19: 'rdVenGuri', 20: 'rdCamaguey1',
}

D_MEASURE = {
    0: 'unNone', 1: 'unDB', 2: 'unDBZ', 3: 'unMMH', 4: 'unMS', 5: 'unMM',
    6: 'unM', 7: 'unKM', 8: 'unKGM', 9: 'unZDR', 10: 'unPDP', 11: 'unRho',
    12: 'unKDP', 13: 'unGCP', 14: 'unTID', 15: 'unM2S2', 16: 'unSW',
}

D_PLANE_KIND = {0: 'pkHorizontal', 1: 'pkVertical'}
D_PACK_METHOD = {0: 'pmNone', 1: 'pmDAS', 2: 'pmZLib'}


def code2angle_deg(code):
    return code * 360 / 4096.0


def probe(path):
    with open(path, 'rb') as f:
        s = f.read()

    print(f'=== {path} ({len(s)} bytes) ===')

    sig_fmt = '<20s4H36s'
    sig_sz = struct.calcsize(sig_fmt)
    signature, v_minor, v_major, v_build, v_release, design = struct.unpack(sig_fmt, s[:sig_sz])
    print('signature:', signature, 'version:', v_major, v_minor, v_build, v_release)
    print('design:', design.split(b'\x00')[0].decode('latin-1'))

    rest_fmt = '<B2?Bd2I'
    rest_sz = struct.calcsize(rest_fmt)
    radar_code, daylight, variance, _dummy, obs_time_raw, ppi_count, channel_count = struct.unpack(
        rest_fmt, s[sig_sz:sig_sz + rest_sz]
    )
    header_size = sig_sz + rest_sz  # 84
    obs_dt = OLE_TIME_ZERO + timedelta(days=float(obs_time_raw))
    print('radar:', D_RADAR.get(radar_code, radar_code), 'daylight:', daylight, 'variance:', variance)
    print('obs_datetime:', obs_dt)
    print('ppi_count:', ppi_count, 'channel_count:', channel_count)

    loc_end = 4 * ppi_count + header_size
    locations = struct.unpack(f'<{ppi_count}I', s[header_size:loc_end])

    ch_fmt = '<2Bh3I3fI'
    ch_sz = struct.calcsize(ch_fmt)  # 32, no padding needed
    for i in range(channel_count):
        off = loc_end + i * ch_sz
        wl, pulse, _d, ncells, celllen, nsectors, beamw, metpot, deltapot, idx = struct.unpack(
            ch_fmt, s[off:off + ch_sz]
        )
        print(
            f'  channel[{i}]: cells={ncells} cell_len={celllen}m sectors={nsectors} '
            f'beamw={beamw:.3f} metpot={metpot:.3f} deltapot={deltapot:.3f} wl={wl} pulse={pulse} idx={idx}'
        )

    # Real padding byte in the file after the 3 leading bytes (Delphi aligned
    # the double to 4 bytes, not 8) -- 'x' below is not a struct quirk, it
    # skips an actual byte present on disk.
    ppi_desc_fmt = '<3BxdI2B3hI'
    ppi_hdr_fmt = '<BxH2I'
    assert struct.calcsize(ppi_desc_fmt) == PPI_DESC_SIZE
    assert struct.calcsize(ppi_hdr_fmt) == PPI_HEADER_SIZE

    ok = fail = 0
    for i, loc in enumerate(locations):
        (radar_c, speed, _dp, time_raw, channel, kind_c, meas_c,
         angle_c, start_c, finish_c, sector_count) = struct.unpack(
            ppi_desc_fmt, s[loc:loc + PPI_DESC_SIZE]
        )
        kind = D_PLANE_KIND.get(kind_c, kind_c)
        measure = D_MEASURE.get(meas_c, meas_c)

        hoff = loc + PPI_DESC_SIZE
        pack_c, _dh, packed_size, unpacked_size = struct.unpack(
            ppi_hdr_fmt, s[hoff:hoff + PPI_HEADER_SIZE]
        )
        pack_method = D_PACK_METHOD.get(pack_c, pack_c)

        data_off = loc + PPI_DESC_SIZE + PPI_HEADER_SIZE
        blob = s[data_off:data_off + packed_size]
        if pack_method == 'pmZLib':
            dec = zlib.decompress(blob)
            if len(dec) == unpacked_size:
                ok += 1
            else:
                fail += 1
                print(f'  !! ppi[{i}] size mismatch: got {len(dec)} expected {unpacked_size}')
        else:
            fail += 1
            print(f'  !! ppi[{i}] unhandled pack method {pack_method}')

        if i < 3 or i == len(locations) - 1:
            print(
                f'  ppi[{i}]: channel={channel} kind={kind} measure={measure} '
                f'angle={code2angle_deg(angle_c):.2f} '
                f'az=[{code2angle_deg(start_c):.1f},{code2angle_deg(finish_c):.1f}] '
                f'sectors={sector_count} pack={pack_method} '
                f'packed={packed_size} unpacked={unpacked_size}'
            )

    print(f'decompress ok={ok} fail={fail} total={len(locations)}')
    print()


if __name__ == '__main__':
    for path in sys.argv[1:]:
        probe(path)
