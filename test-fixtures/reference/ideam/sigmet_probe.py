#!/usr/bin/env python3
"""
Oracle probe for IDEAM's Sigmet/IRIS RAW files (Guaviare/Munchique/Carimagua/
Barrancabermeja/Corozal/Tablazo, S3 bucket s3-radaresideam). Same role as
../rainbow/rainbow_probe.py: no legacy Delphi source for this format, so
xradar is the ground truth to confirm the byte layout against before porting
anything to TS.

Setup (no system pip on the dev box):
    uv venv /tmp/ideam-oracle && source /tmp/ideam-oracle/bin/activate
    uv pip install xradar

Usage:
    python3 sigmet_probe.py <path-to.RAWxxxx>
"""

import sys

import numpy as np
import xradar as xd


def main(path: str) -> None:
    dtree = xd.io.open_iris_datatree(path)
    root = dtree["/"].ds
    sweeps = [k for k in dtree.groups if k.startswith("/sweep_")]

    print("=== ROOT ===")
    print("site lat/lon/alt:", float(root.latitude), float(root.longitude), float(root.altitude))
    print("instrument_name:", root.attrs.get("instrument_name"))
    print("scan_name:", root.attrs.get("scan_name"))
    print("comment:", root.attrs.get("comment"))
    print("sweep count:", len(sweeps))

    for key in sweeps:
        sw = dtree[key].ds
        print(f"\n=== {key} ===")
        print("azimuths:", sw.azimuth.size, "range gates:", sw.range.size)
        print("range[:3]:", sw.range.values[:3], "gate spacing:", np.diff(sw.range.values[:2]))
        print("elevation (fixed angle):", float(sw.sweep_fixed_angle.values))
        print("sweep_mode:", sw.sweep_mode.values)
        print("moments:", [v for v in sw.data_vars if sw[v].dims == ("azimuth", "range")])
        for var in sw.data_vars:
            if sw[var].dims != ("azimuth", "range"):
                continue
            vals = sw[var].values
            finite = vals[np.isfinite(vals)] if np.issubdtype(vals.dtype, np.floating) else vals
            rng = (finite.min(), finite.max()) if finite.size else None
            print(f"  {var}: dtype={vals.dtype} units={sw[var].attrs.get('units')} range={rng}")


if __name__ == "__main__":
    main(sys.argv[1])
