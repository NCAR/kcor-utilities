; docformat = 'rst'

;+
; Display a kcor FITS image & report cursor position.
;
; :Examples:
;   Try::
;
;     kcor_fvp, '19981101.1234.mk3.cpb.fts'
;     kcor_fvp, '19981101.1234.mk3.rpb.fts', $
;               cm='/home/stanger/color/bwy.lut'
;     kcor_fvp, '19981101.1234.mk3.rpb.fts', /gif
;
; :Params:
;   fits_name : in, required, type=string
;     filename of Spartan WLC FITS image
;
; :Keywords:
;   gif : in, optional, type=boolean
;     write displayed image as a GIF file
;   cm : in, optional, type=string
;     pathname of ASCII colormap file where each line has the syntax::
;
;       index red green blue
;
;     where index = 0, 1, 2, ... 255, and red/green/blue are in the range 0 to
;     255
;   wmin : in, optional, type=float, default=0.0
;     minimum value used for display scaling
;   wmax : in, optional, type=float, default=1.2
;     maximum value used for display scaling
;   wexp : in, optional, type=float, default=0.7
;     exponent used for display scaling
;   text : in, optional, type=boolean
;     write scan data to a text file "{file_basename(fits_name)}.pos"
;   nolabel : in, optional, type=boolean
;     if set, do NOT display the position # label
;
; :Uses:
;    headfits                   read FITS header
;    fxpar                      read FITS keyword parameter
;
;    kcor_fitsdisp.pro          display kcor image
;    kcor_fits_annotate.pro     annotate kcor image
;    mouse_pos_lab.pro          mouse position + label procedure
;
; :History:
;   Andrew L. Stanger   HAO/NCAR   17 Nov 2001
;   17 Nov 2015 [ALS] Adapted from fvp.pro for kcor
;-
pro kcor_fvp, fits_name, $
              gif=gif, cm=cm, wmin=wmin, wmax=wmax, wexp=wexp, $
              text=text, nolabel=nolabel
  compile_opt strictarr

  disp_label = 1   ; set display label option variable

  ; load color table
  if (n_elements(cm) gt 0) then begin
    print, 'cm: ', cm
    dirend = -1

    ; find index of last "/" in cm pathname
    dirend = strpos(cm, '/', /reverse_search)

    if (dirend ne -1) then begin
      print, 'dirend: ', dirend
      coldir = strmid(cm, 0, dirend)   ; directory containing color map
      print, 'coldir: ', coldir
      ccm = strmid(cm, dirend+1, strlen(cm) - dirend - 1)   ; color map file
      print, 'ccm: ', ccm
    endif

    ; if cm does not contain a directory, use default color directory
    if (dirend eq -1) then begin
      cm = filepath(cm + '.lut', $
                    subdir=['..', 'resources'], $
                    root=mg_src_root())
    endif

    ; load specified colormap
    lct, cm
  endif else begin
    ; load B-W color table if CM not specified
    loadct, 0, ncolors=249, /silent
    tvlct, 255B, 0B, 0B, 254B
  endelse

  ; read color map arrays
  redlut   = bytarr(256)
  greenlut = bytarr(256)
  bluelut  = bytarr(256)
  tvlct, redlut, greenlut, bluelut, /get   ; fetch RGB color look-up tables

  ; default variable values
  xb = 160        ; x-axis border [pixels]
  yb =  80        ; y-axis border [pixels]
  xdim_prev = 0   ; x-dimension previous image
  ydim_prev = 0   ; y-dimension previous image

  ; read FITS image & header
  ftspos   = strpos(fits_name, '.fts')
  basename = strmid(fits_name, 0, ftspos)
  print, 'basename: ', basename

  ; open text file and write title
  if (keyword_set(text)) then begin
    pfile = basename + '.pos'
    openw, lun, pfile, /get_lun
    printf, lun, fits_name, '   Position Measurement[s]'
    free_lun, lun
  endif

  ; read FITS header
  hdu = headfits(fits_name)

  ; extract information from header
  xdim     = fxpar(hdu, 'NAXIS1')
  ydim     = fxpar(hdu, 'NAXIS2')
  xcen     = fxpar(hdu, 'CRPIX1') + xb - 1
  ycen     = fxpar(hdu, 'CRPIX2') + yb - 1
  roll     = fxpar(hdu, 'INST_ROT', count=qinst_rot)
  cdelt1   = fxpar(hdu, 'CDELT1',   count=qcdelt1)
  rsun     = fxpar(hdu, 'RSUN_OBS', count=qrsun)
  if (qrsun eq 0L) then rsun = fxpar(hdu, 'RSUN', count=qrsun)

  pixrs    = rsun / cdelt1   ; pixels/Rsun
  print, 'pixrs   : ', pixrs

  ; resize window [if image size has changed]
  if (xdim ne xdim_prev or ydim ne ydim_prev) then begin
    window, xsize=xdim + xb, ys=ydim + yb, retain=2
  endif

  print, 'xdim + xb: ', xdim + xb
  print, 'ydim + yb: ', ydim + yb

  xdim_prev = xdim
  ydim_prev = ydim

  ; annotate image
  ;kcor_fits_annotate, hdu, xdim, ydim, xb, yb

  ; display image
  kcor_fitsdisp, fits_name, $
                 left_margin=xb, bottom_margin=yb, $
                 wmin=wmin, wmax=wmax, wexp=wexp

  ; use mouse to extract radius & position angle for cursor position
  mouse_pos_lab, xdim, ydim, xcen, ycen, pixrs, roll, $
                 pos=1, pfile=pfile, disp_label=keyword_set(nolabel) eq 0B

  ; write displayed image to a GIF file (if "gif" keyword is set)
  if (keyword_set(gif)) then begin
    gif_file = basename + '.gif'
    img_gif = tvrd()
    write_gif, gif_file, img_gif, redlut, greenlut, bluelut
  endif
end
