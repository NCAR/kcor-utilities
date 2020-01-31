#!/usr/bin/env python

import argparse
import warnings

import matplotlib.cm
import matplotlib.pyplot as plt
import numpy as np
import numpy.ma as ma
import skimage.exposure

import astropy.io.fits
import astropy.units as u

from sunpy import log
import sunpy.time
from sunpy.net import Fido, attrs as a
from sunpy.map import Map
from sunpy.map.maputils import all_coordinates_from_map


def process_lasco_map(m):
    # nothing to do right now
    return(m)


def process_kcor_map(m, rsun=2.7, gamma=0.7):
    hpc_coords = all_coordinates_from_map(m)
    r = np.sqrt(hpc_coords.Tx ** 2 + hpc_coords.Ty ** 2) / m.rsun_obs
    mask = r > rsun

    # remote negative values for gamma correction
    rescaled_data = m.data
    rescaled_data[rescaled_data < 0.0] = 0.0

    adjusted_data = skimage.exposure.adjust_gamma(rescaled_data, gamma=gamma)

    processed_map = sunpy.map.Map(adjusted_data, m.meta, mask=mask)

    return(processed_map)


def process_aia_map(m, rsun=1.2, threshold=35):
    hpc_coords = all_coordinates_from_map(m)
    r = np.sqrt(hpc_coords.Tx ** 2 + hpc_coords.Ty ** 2) / m.rsun_obs

    mask = ma.logical_and(r > rsun, m.data < threshold)

    processed_map = sunpy.map.Map(m.data, m.meta, mask=mask)
    return(processed_map)


def get_aia_map(time, wavelength=171 * u.angstrom):
    aia_results = Fido.search(a.Time(time - 30 * u.minute, time + 30 * u.minute,
                                     near=time),
                              a.Instrument("AIA"),
                              a.Wavelength(wavelength),
                              a.vso.Sample(10 * u.minute))
    aia_files = Fido.fetch(aia_results, path="./data/aia/")
    if len(aia_files) == 0:
        return None
    maps = [Map(f) for f in aia_files]
    time_diffs = np.array([abs(m.date - time) for m in maps])
    min_index = np.argmin(time_diffs)
    return maps[min_index]


def get_lasco(time):
    lasco_results = Fido.search(a.Time(time - 30 * u.minute, time + 30 * u.minute),
                                a.Instrument("LASCO"),
                                a.vso.Sample(10 * u.minute))
    lasco_files = Fido.fetch(lasco_results, path="./data/lasco/")
    if len(lasco_files) == 0:
        return None
    maps = [Map(f) for f in lasco_files]
    time_diffs = np.array([abs(m.date - time) for m in maps])
    min_index = np.argmin(time_diffs)
    return(lasco_files[min_index])


def display_map(m, date, output_filename, names, width=8.0, height=8.0):
    fig = plt.figure(figsize=(width, height))
    ax = plt.subplot()
    m.plot()

    name = "-".join(names)
    dt = date.datetime.strftime("%Y-%m-%dT%H:%M:%S")
    ax.set_title(f"{name} composite for {dt}")

    plt.savefig(output_filename, bbox_inches="tight")


def main():
    version = "0.2.0"
    name = f"KCor composite image {version}"
    parser = argparse.ArgumentParser(description=name)
    parser.add_argument("time", type=str,
                        help="date/time to create composite for, i.e., 2019-05-03T21:21:14")

    parser.add_argument("--aia-radius", type=float, default=1.11,
                        help="[Rsun] AIA outer radius")
    parser.add_argument("--aia-intensity-threshold", type=float, default=35,
                        help="[Rsun] AIA min intentisyt threshold")

    parser.add_argument("--kcor-filename", type=str, help="KCor L2 filename")
    parser.add_argument("--kcor-radius", type=float, default=2.7,
                        help="[Rsun] KCor outer radius")

    parser.add_argument("--lasco-filename", type=str, help="LASCO C2 filename")

    parser.add_argument("-o", "--output", type=str, help="output filename")
    parser.add_argument("--width", type=float, default=8.0,
                        help="[inches] width")
    parser.add_argument("--height", type=float, default=8.0,
                        help="[inches] height")

    args = parser.parse_args()

    time = sunpy.time.parse_time(args.time)

    maps = []
    names = []

    # LASCO files produce a lot of VerifyWarning's and a SunpyUserWarning
    warnings.simplefilter('ignore', category=astropy.io.fits.verify.VerifyWarning)
    warnings.simplefilter('ignore', category=sunpy.util.SunpyUserWarning)

    if args.lasco_filename is not None:
        processed_lasco_map = process_lasco_map(Map(args.lasco_filename))
        maps.append(processed_lasco_map)
        names.append("LASCO")

    if args.kcor_filename is not None:
        processed_kcor_map = process_kcor_map(Map(args.kcor_filename),
                                              rsun=args.kcor_radius)
        maps.append(processed_kcor_map)
        names.append("KCor")

    aia_map = get_aia_map(time)
    processed_aia_map = process_aia_map(aia_map,
                                        rsun=args.aia_radius,
                                        threshold=args.aia_intensity_threshold)
    maps.append(processed_aia_map)
    names.append("AIA")

    output_filename = args.output
    if output_filename is None:
        dt = time.datetime.strftime("%Y%m%d.%H%M%S")
        name = "-".join(names).lower()
        output_filename = f"{dt}.{name}.png"

    composite = Map(*tuple(maps), composite=True)
    display_map(composite, time, output_filename, names,
                width=max(args.width, args.height),
                height=max(args.width, args.height))

    print(f"Output written to: {output_filename}")


if __name__ == "__main__":
    main()
