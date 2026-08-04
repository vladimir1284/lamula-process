#!/usr/bin/env python3
"""
Oracle probe for IDEAM's NetCDF PPIVol files (Bogota, santa_elena/SIATA, S3
bucket s3-radaresideam). Turns out to be standard CfRadial over classic
NETCDF3 (magic "CDF\\x01", confirmed via Dataset.data_model) -- no HDF5, so a
hand-written TS reader is feasible without an HDF5 dependency. netCDF4 is
still the oracle here to confirm layout/scale-factor decoding before porting.

Setup (no system pip on the dev box):
    uv venv /tmp/ideam-oracle && source /tmp/ideam-oracle/bin/activate
    uv pip install netCDF4 xarray

Usage:
    python3 netcdf_probe.py <path-to.nc>
"""

import sys

import netCDF4 as nc
import numpy as np


def main(path: str) -> None:
    ds = nc.Dataset(path)
    print("data_model:", ds.data_model, "disk_format:", ds.disk_format)
    print("Conventions:", getattr(ds, "Conventions", None))
    print("instrument_name:", getattr(ds, "instrument_name", None))

    print("\n=== SITE ===")
    print("lat/lon/alt:", ds.variables["latitude"][...], ds.variables["longitude"][...],
          ds.variables["altitude"][...])

    print("\n=== GEOMETRY ===")
    az = ds.variables["azimuth"][...]
    el = ds.variables["elevation"][...]
    rng = ds.variables["range"][...]
    print("fixed_angle:", ds.variables["fixed_angle"][...])
    print("ray count:", az.size, "azimuth min/max:", az.min(), az.max())
    print("elevation min/max:", el.min(), el.max())
    print("range gates:", rng.size, "gate spacing:", np.diff(rng[:2]), "first gate:", rng[0])
    print("sweep_mode:", bytes(ds.variables["sweep_mode"][0]).decode(errors="ignore").strip())

    print("\n=== MOMENTS ===")
    geometry_vars = {"time", "azimuth", "elevation", "range"}
    for name, var in ds.variables.items():
        if var.dimensions != ("time", "range"):
            continue
        vals = np.ma.filled(var[...].astype("float64"), np.nan)
        finite = vals[np.isfinite(vals)]
        rng_str = (finite.min(), finite.max()) if finite.size else "all fill/NaN"
        print(f"  {name}: units={getattr(var, 'units', None)} "
              f"scale_factor={getattr(var, 'scale_factor', None)} "
              f"add_offset={getattr(var, 'add_offset', None)} range={rng_str}")


if __name__ == "__main__":
    main(sys.argv[1])
