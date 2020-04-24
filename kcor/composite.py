#!/usr/bin/env python

import argparse

import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import numpy.ma as ma

import astropy.units as u

#from sunpy import log

from sunpy.map import Map


def kcor_nrgf_cmap():
    r = [  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   1,   2,
           2,   3,   5,   6,   7,   9,  10,  12,  14,  15,  17,  19,  20,  22,  23,  25,
          26,  28,  29,  31,  33,  34,  36,  37,  39,  40,  42,  43,  45,  46,  48,  49,
          50,  52,  53,  55,  56,  58,  59,  61,  62,  63,  65,  66,  67,  69,  70,  72,
          73,  74,  76,  77,  78,  80,  81,  83,  84,  85,  86,  88,  89,  90,  92,  93,
          94,  96,  97,  98,  99, 101, 102, 103, 104, 106, 107, 108, 109, 111, 112, 113,
         114, 116, 117, 118, 119, 120, 122, 123, 124, 125, 126, 128, 129, 130, 131, 132,
         133, 135, 136, 137, 138, 139, 140, 141, 143, 144, 145, 146, 147, 148, 149, 150,
         152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 163, 164, 165, 166, 167, 168,
         169, 170, 171, 172, 173, 174, 175, 176, 177, 179, 180, 181, 182, 183, 184, 185,
         186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 200,
         201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 215,
         216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230,
         231, 232, 233, 234, 234, 235, 236, 237, 238, 239, 240, 241, 241, 242, 244, 245,
         245, 246, 247, 248, 248, 249, 250, 250, 250, 250, 250, 251, 251, 251, 251, 251,
         251, 252, 252, 252, 252, 252, 252, 253, 253, 253, 255, 128,   0,   0, 255, 255]
    r = np.array(r, dtype=np.float32) / 255.0

    g = [  0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   1,   2,
           2,   3,   5,   6,   7,   9,  10,  12,  14,  15,  17,  19,  20,  22,  23,  25,
          26,  28,  29,  31,  33,  34,  36,  37,  39,  40,  42,  43,  45,  46,  48,  49,
          50,  52,  53,  55,  56,  58,  59,  61,  62,  63,  65,  66,  67,  69,  70,  72,
          73,  74,  76,  77,  78,  80,  81,  83,  84,  85,  86,  88,  89,  90,  92,  93,
          94,  96,  97,  98,  99, 101, 102, 103, 104, 106, 107, 108, 109, 111, 112, 113,
         114, 116, 117, 118, 119, 120, 122, 123, 124, 125, 126, 128, 129, 130, 131, 132,
         133, 135, 136, 137, 138, 139, 140, 141, 143, 144, 145, 146, 147, 148, 149, 150,
         152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 163, 164, 165, 166, 167, 168,
         169, 170, 171, 172, 173, 174, 175, 176, 177, 179, 180, 181, 182, 183, 184, 185,
         186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 200,
         201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 215,
         216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 225, 226, 227, 228, 229, 230,
         231, 232, 233, 234, 234, 235, 236, 237, 238, 239, 240, 241, 241, 242, 244, 245,
         245, 246, 247, 248, 248, 249, 250, 250, 250, 250, 250, 251, 251, 251, 251, 251,
         251, 252, 252, 252, 252, 252, 252, 253, 253, 253, 255, 127,   0, 255,   0, 255]
    g = np.array(g, dtype=np.float32) / 255.0

    b = [  0,   8,  16,  24,  30,  33,  39,  45,  50,  55,  59,  63,  67,  71,  74,  78,
          81,  84,  87,  90,  93,  95,  98, 100, 103, 105, 108, 110, 112, 114, 116, 118,
         120, 122, 124, 125, 127, 129, 130, 132, 134, 135, 137, 138, 140, 141, 142, 144,
         145, 146, 148, 149, 150, 152, 153, 154, 155, 156, 157, 158, 159, 161, 162, 163,
         164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 174, 175, 176, 177, 178,
         179, 180, 181, 181, 182, 183, 184, 185, 185, 186, 187, 188, 188, 189, 190, 191,
         191, 192, 193, 193, 194, 195, 196, 196, 197, 198, 198, 199, 200, 200, 201, 201,
         202, 203, 203, 204, 205, 205, 206, 206, 207, 208, 208, 209, 209, 210, 210, 211,
         211, 212, 213, 213, 214, 214, 215, 215, 216, 216, 217, 217, 218, 218, 219, 219,
         220, 220, 221, 221, 222, 222, 223, 223, 224, 224, 224, 225, 225, 226, 226, 227,
         227, 228, 228, 229, 229, 229, 230, 230, 231, 231, 232, 232, 232, 233, 233, 234,
         234, 234, 235, 235, 236, 236, 236, 237, 237, 238, 238, 238, 239, 239, 239, 240,
         240, 241, 241, 241, 242, 242, 242, 243, 243, 244, 244, 244, 245, 245, 245, 246,
         246, 246, 246, 247, 247, 247, 247, 247, 248, 248, 248, 248, 248, 248, 248, 248,
         249, 249, 249, 249, 249, 249, 250, 250, 250, 250, 250, 251, 251, 251, 251, 251,
         251, 252, 252, 252, 252, 252, 252, 253, 253, 253,   0, 127, 255,   0,   0, 255]
    b = np.array(b, dtype=np.float32) / 255.0

    colors = np.hstack((r.reshape(len(r), 1), g.reshape(len(g), 1), b.reshape(len(b), 1)))
    nrgf_cmap = matplotlib.colors.ListedColormap(colors)

    return(nrgf_cmap)


def process_lasco_map(m):
    # nothing to do right now
    return(m)


def process_kcor_map(m, rsun=2.7, gamma=0.7):
    import skimage.exposure
    from sunpy.map.maputils import all_coordinates_from_map

    hpc_coords = all_coordinates_from_map(m)
    r = np.sqrt(hpc_coords.Tx ** 2 + hpc_coords.Ty ** 2) / m.rsun_obs
    mask = r > rsun

    # remove negative values for gamma correction
    rescaled_data = m.data

    # don't scale if NRGF
    if "PRODUCT" in m.fits_header:
        display_min = m.fits_header["DISPMIN"]
        display_max = m.fits_header["DISPMAX"]
        processed_data = np.clip(rescaled_data, display_min, display_max) - display_min
        processed_data /= display_max - display_min
        processed_map = Map(processed_data, m.meta, mask=mask)

        processed_map.plot_settings["cmap"] = kcor_nrgf_cmap()
        processed_map.plot_settings["norm"] = matplotlib.colors.NoNorm()

        return(processed_map)

    rescaled_data[rescaled_data < 0.0] = 0.0
    adjusted_data = skimage.exposure.adjust_gamma(rescaled_data, gamma=gamma)

    processed_map = Map(adjusted_data, m.meta, mask=mask)

    return(processed_map)


def process_aia_map(m, rsun=1.2, threshold=35):
    from sunpy.map.maputils import all_coordinates_from_map

    hpc_coords = all_coordinates_from_map(m)
    r = np.sqrt(hpc_coords.Tx ** 2 + hpc_coords.Ty ** 2) / m.rsun_obs

    mask = ma.logical_and(r > rsun, m.data < threshold)

    processed_map = Map(m.data, m.meta, mask=mask)
    return(processed_map)


def get_aia_map(time, wavelength=171 * u.angstrom):
    from sunpy.net import Fido, attrs as a

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


#def get_lasco(time):
#    lasco_results = Fido.search(a.Time(time - 30 * u.minute, time + 30 * u.minute),
#                                a.Instrument("LASCO"),
#                                a.vso.Sample(10 * u.minute))
#    lasco_files = Fido.fetch(lasco_results, path="./data/lasco/")
#    if len(lasco_files) == 0:
#        return None
#    maps = [Map(f) for f in lasco_files]
#    time_diffs = np.array([abs(m.date - time) for m in maps])
#    min_index = np.argmin(time_diffs)
#    return(lasco_files[min_index])


def display_map(m, date, output_filename, names, lasco_present=True, width=8.0, height=8.0):
    import matplotlib.pyplot as plt

    fig = plt.figure(figsize=(width, height))
    ax = plt.subplot()
    m.plot()

    if not lasco_present:
        lim = 2300.0   # in arcsec
        ax.set_xlim((-lim, lim))
        ax.set_ylim((-lim, lim))

    name = "-".join(names)
    dt = date.datetime.strftime("%Y-%m-%dT%H:%M:%S")
    ax.set_title(f"{name} composite for {dt}")

    ax.set_facecolor("black")

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

    parser.add_argument("--verbose", action="store_true", default=False)
    parser.add_argument("-v", "--version", action="version", version=name)

    args = parser.parse_args()

    import sunpy.time
    time = sunpy.time.parse_time(args.time)

    maps = []
    names = []

    # LASCO files produce a lot of VerifyWarning's and a SunpyUserWarning
    if not args.verbose:
        import astropy.io.fits
        import warnings
        warnings.simplefilter("ignore", category=astropy.io.fits.verify.VerifyWarning)
        warnings.simplefilter("ignore", category=sunpy.util.SunpyUserWarning)

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
    display_map(composite, time, output_filename, names, args.lasco_filename is not None,
                width=max(args.width, args.height),
                height=max(args.width, args.height))

    print(f"Output written to: {output_filename}")


if __name__ == "__main__":
    main()
