; docformat = 'rst'

;+
; Produce a basic display of an NRGF image.
;-
pro kcor_nrgf_display, filename
  compile_opt strictarr

  im = readfits(filename, header, /silent)
  dims = size(im, /dimensions)

  display_min = sxpar(header, 'DISPMIN')
  display_max = sxpar(header, 'DISPMAX')

  original_device = !d.name
  device, get_decomposed=original_decomposed
  device, decomposed=0
  tvlct, original_rgb, /get

  lct, filepath('quallab.lut', subdir=['..', 'resources'], root=mg_src_root())

  window, xsize=dims[0], ysize=dims[1], /free, title=file_basename(filename)
  tv, bytscl(im, min=display_min, max=display_max, top=249)

  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end
