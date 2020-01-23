#!/usr/bin/env python

import argparse

import astropy.units as u

import matplotlib.cm
import matplotlib.pyplot as plt

import numpy as np
import numpy.ma as ma

from sunpy import log
import sunpy.time
from sunpy.net import Fido, attrs as a
from sunpy.map import Map
from sunpy.map.maputils import all_coordinates_from_map

# masking out solar disk
# https://docs.sunpy.org/en/stable/generated/gallery/computer_vision_techniques/mask_disk.html

def get_aia(time, wavelength=171 * u.angstrom, rsun=1.2, threshold=35):
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
    m = maps[min_index]

    hpc_coords = all_coordinates_from_map(m)
    r = np.sqrt(hpc_coords.Tx ** 2 + hpc_coords.Ty ** 2) / m.rsun_obs

    # radii_mask = ma.masked_greater_equal(r, 1)
    # intensity_mask = ma.masked_less_equal(m.data, 50)
    # mask = ma.logical_and(radii_mask.mask, intensity_mask.mask)
    mask = ma.logical_and(r > rsun, m.data < threshold)

    palette = m.cmap
    palette.set_bad("black", alpha=0.0)

    scaled_map = sunpy.map.Map(m.data, m.meta, mask=mask)
    return(scaled_map)


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


def display_map(map, date):
    fig = plt.figure(figsize=(8, 8))
    ax = plt.subplot()
    #map.set_gamma(0.7)
    #map.plot(gamma=0.7)
    map.plot()
    ax.set_title(f"AIA-KCor-LASCO composite {date}")
    plt.show()
    #map.peek()


def main():
    version = "0.0.1"
    name = f"KCor composite image {version}"
    parser = argparse.ArgumentParser(description=name)
    parser.add_argument("time", type=str,
                        help="date/time to create composite")
    parser.add_argument("--kcor-filename", type=str, help="KCor L2 filename")
    args = parser.parse_args()
    time = sunpy.time.parse_time(args.time)

    aia_map = get_aia(time, rsun=1.11, threshold=35)
    lasco_file = "~/Desktop/22722720.fts"
    #kcor_file = "~/Desktop/20190503_214445_kcor_l2.fts.gz"
    #kcor_map = Map(args.kcor_filename)
    composite = Map(aia_map, args.kcor_filename, lasco_file, composite=True)
    display_map(composite, time)


if __name__ == "__main__":
    main()
