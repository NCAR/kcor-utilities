; docformat = 'rst'

;+
; Perform a Mk4 rpb radial scan using a FITS image [cartesian].
;
; Note: this procedure works best in private colormap mode (256 levels).
;
; :Params:
;   fits_file : in, required, type=string
;     FITS filename
;   angle : in, required, type=numeric
;     position angle [degrees CCW from solar North]
;   radmin : in, required, type=numeric
;     beginning radius [Rsun]
;   radmax : in, required, type=numeric
;     ending radius [Rsun]
;   radinc : in, required, type=numeric
;     angle increment [Rsun]
;
; :Keywords:
;   ymin : in, optional, type=numeric
;     Y-axis minimum value
;   ymax : in, optional, type=numeric
;     Y-axis maximum value
;   text : in, optional, type=boolean
;     write scan data to the text file "{basename}_pa{angle}.txt"
;   ps : in, optional, type=boolean
;     option to write plot to a postscript file
;
; :Uses:
;   readfits, fxpar
;   rscan.pro    performs radial scan
;   lct.pro      loads a color table from an ASCII file
;   rcoord.pro   converts between [r,th] and [x,y] coordinates
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   03 Aug 2001
;
; :History:
;   05 Nov 2015 [ALS] adapt for use with KCor
;-
pro kcor_frscan, fits_file, angle, radmin, radmax, radinc, $
                 ymin=ymin, ymax=ymax, text=text, ps=ps
  compile_opt strictarr

  ; default variable values
  stars = '***'
  date_obs = ''
  time_obs = ''
  ftspos   = strpos(fits_file, '.fts')
  basename = strmid(fits_file, 0, ftspos)
  print, 'basename: ', basename

  ; load color table
  ;lct, 'bwcp.lut'
  ;lct, 'bwy.lut'
  ;lct, 'quallab.lut'
  loadct, 0

  ; color designations in LUT
  yellow = 250
  grey   = 251
  blue   = 252
  green  = 253
  red    = 254
  white  = 255

  ; read color lookup tables
  redlut   = bytarr(256)
  greenlut = bytarr(256)
  bluelut  = bytarr(256)

  ; read color table into arrays
  tvlct, redlut, greenlut, bluelut, /get

  ; read FITS image & header
  img = readfits(fits_file, hdu)

  ; get parameters from FITS header
  telescop = fxpar(hdu, 'TELESCOP')                  ; telescope name
  instrume = fxpar(hdu, 'INSTRUME')                  ; instrument name
  date_obs = fxpar(hdu, 'DATE-OBS')                  ; observation date
  xdim     = fxpar(hdu, 'NAXIS1')                    ; X dimension
  ydim     = fxpar(hdu, 'NAXIS2')                    ; Y dimension
  bzero    = fxpar(hdu, 'BZERO')                     ; brightness offset
  bscale   = fxpar(hdu, 'BSCALE')                    ; brightness scaling factor
  xcen     = fxpar(hdu, 'CRPIX1')                    ; X center
  ycen     = fxpar(hdu, 'CRPIX2')                    ; Y center
  cdelt1   = fxpar(hdu, 'CDELT1')                    ; resolution [arcsec/pixel]
  roll     = fxpar(hdu, 'INST_ROT')                  ; rotation angle [degrees]
  rsun     = fxpar(hdu, 'RSUN')                      ; solar radius [arcsec/Rsun]
  dispmin  = fxpar(hdu, 'DISPMIN', count=qdispmin)   ; display min value
  dispmax  = fxpar(hdu, 'DISPMAX', count=qdispmax)   ; display max value
  dispexp  = fxpar(hdu, 'DISPEXP', count=qdispexp)   ; display exponent

  dateobs = strmid(date_obs,  0, 10)   ; yyyy-mm-dd
  timeobs = strmid(date_obs, 11,  8)   ; hh:mm:ss

  print, 'date_obs: ', date_obs
  print, 'dateobs:  ', dateobs
  print, 'timeobs:  ', timeobs

  xcen -= 1   ; FITS keyword value has origin = 1, IDL index origin = 0
  ycen -= 1   ; FITS keyword value has origin = 1, IDL index origin = 0
  if (xcen lt 0.0) then xcen = (xdim - 1) / 2.0
  if (ycen lt 0.0) then ycen = (ydim - 1) / 2.0

  ; Do not change bscale. This was meant to fix a problem in the old level 1
  ; data. J. Burkepile, July 2019
  ;if (bscale eq 1.0) then bscale = 0.001	; BSCALE incorrect for L1 < 15 Jul 2015.

  img = img * bscale + bzero

  pixrs   = rsun / cdelt1 
  print, 'pixrs: ', pixrs

  ; convert numerical values to strings
  sangle  = string(angle, format='(F7.2)')
  sangle  = strtrim(sangle, 2)
  sradmin = string(radmin, format='(F4.2)')
  sradmin = strtrim(radmin, 2)
  sradmax = string(radmax, format='(F4.2)')
  sradmax = strtrim(sradmax, 2)
  sradmin = strtrim(string(radmin, format='(f4.2)'), 2)

  ; do radial scan
  rscan, namimg, img, pixrs, roll, xcen, ycen, $
         radmin, radmax, radinc, angle,	$
         scan, scandx, ns

  ;for i = 0, ns-1  do	$
  ;print, 'scandx: ', scandx [i], '  scan: ', scan [i]

  ; if 'text' keyword set, write scan values to a text file
  if (keyword_set(text)) then begin
    text_file  = basename + '_pa' + sangle + '.txt'
    openw, lun, text_file, /get_lun
    printf, lun, fits_file, '   Radial Scan   ', sangle, ' degrees'

    for i = 0, ns - 1 do begin
      printf, lun, $
              'scandx: ', scandx [i], ' Rsun   scan: ', scan [i], $
              ' pB [B/Bsun]'
    endfor

    free_lun, lun
  endif

  ; reduce image size for display (if needed)
  print, 'xdim/ydim: ', xdim, ydim

  sizemax = 1024        ; maximum image size: 1024x1024 pixels
  sizeimg = size(img)   ; get image size.

  while (sizeimg [1] gt sizemax or sizeimg [2] gt sizemax) do begin
    img = rebin(img, xdim / 2, ydim / 2)
    xdim = xdim / 2
    ydim = ydim / 2
    xcen = xcen / 2.0
    ycen = ycen / 2.0
    pixrs = pixrs / 2.0
    sizeimg = size(img)
  endwhile

  ; display image
  set_plot, 'Z'
  device, set_resolution=[xdim, ydim], set_colors=256, z_buffering=0

  device, decomposed=1
  gamma_ct, 0.5

  ;window, xsize=xdim, ysize=ydim
  ;imgb = bytscl(img, min=imin, max=imax, top=249)
  ;imgb = bytscl(img, min=dispmin, max=dispmax, top=249)
  ;imgb = bytscl(img^0.7, min=0, max=1.2, top=249)

  dmin = -0.4
  dmax = 0.6
  dexp = 0.5
  imgb = bytscl((img * 1.0e6)^dexp, min=dmin, max=dmax, top=249)
  tv, imgb

  ; label image
  xyouts,        5, ydim-15, fits_file,       /device, color=green,  charsize=1.2
  xyouts,        5, ydim-35, telescop,        /device, color=green,  charsize=1.2
  xyouts, xdim-110, ydim-15, dateobs,         /device, color=green,  charsize=1.2
  xyouts, xdim-110, ydim-35, timeobs + ' UT', /device, color=green,  charsize=1.2
  xyouts,        5,  25, sangle + ' deg',     /device, color=red,    charsize=1.2
  xyouts,        5,   5, sradmin + ' - ' + sradmax + ' Rsun', 	$
                 /device, color=red, charsize=1.2

  ; plot radial scan on image
  radius = radmin - radinc
  for i = 0, ns - 1 do begin
    radius += radinc
    ierr = rcoord(radius, angle, x, y, 1, roll, xcen, ycen, pixrs)
    ixg = fix(x + 0.5)
    iyg = fix(y + 0.5)
    ;plots, [ixg, ixg], [iyg, iyg], /device, color=red
    plots, [ixg-1, ixg+1], [iyg-1, iyg-1], /device, color=red
    plots, [ixg-1, ixg+1], [iyg,   iyg  ], /device, color=red
    plots, [ixg-1, ixg+1], [iyg+1, iyg+1], /device, color=red
  endfor

  ; draw a dotted circle (10 degree increments) at 1.0 Rsun
  th = -10.0
  r  =   1.0
  for i = 0, 360, 10 do	begin
    th += 10.0
    ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
    ixg = fix(x + 0.5)
    iyg = fix(y + 0.5)
    plots, [ixg, ixg], [iyg, iyg], /device, color=grey
  endfor

  ; draw dots every 30 degrees from 0.2 to 1.0 Rsun
  th = 0.0
  for it = 0, 11 do begin
    r  =  -0.2
    for i = 0, 5 do begin
      r += 0.2
      ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
      ixg = fix(x + 0.5)
      iyg = fix(y + 0.5)
      plots, [ixg, ixg], [iyg, iyg], /device, color=grey
    endfor
    th += 30.0
  endfor

  ; draw dots every 90 degrees from 0.1 to 1.0 Rsun
  th = 0.0
  for it = 0, 3 do begin
    r  =  0.1
    for i = 0, 9 do begin
      r += 0.1 
      ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
      ixg = fix(x + 0.5)
      iyg = fix(y + 0.5)
      plots, [ixg, ixg], [iyg, iyg], /device, color=yellow
    endfor
    th += 90.0
  endfor

  ; read displayed image into 2D array
  imgnew = tvrd()
  extpos = strpos(fits_file, ".fts")
  gif_file = basename + '_pa' + sangle + '_img.gif'
  print, 'gif_file: ', gif_file

  ; write GIF image to disk
  write_gif, gif_file, imgnew, redlut, greenlut, bluelut

  yminset = 0
  ymaxset = 0
  if (n_elements(ymin) gt 0L) then yminset = 1 else ymin = min(scan)
  if (n_elements(ymax) gt 0L) then ymaxset = 1 else ymax = max(scan)

  print, 'yminset, ymaxset: ', yminset, ymaxset
  print, 'ymin/ymax: ', ymin, ymax

  ; plot radial scan & save to a GIF file
  device, /close
  set_plot, 'Z'
  device, set_resolution=[1440, 768], set_colors=256, z_buffering=0

  gif_file  = strmid(fits_file, 0, extpos) + '_pa' + sangle + '_plot.gif'
  print, 'gif_file: ', gif_file

  if (yminset OR ymaxset) then begin
    plot, scandx, scan, $
          charsize=1.5, thick=2, charthick=2, xthick=2, ythick=2, $
          title=fits_file + ' Radial Scan @' + sangle + ' degrees', $
          xtitle='Radius [Rsun]', $
          ytitle='Calibrated Polarization Brightness Intensity B/Bsun',	$
          yrange=[1.0e-09, 1.0e-05], ystyle=2, ylog=1
  endif else begin
    plot, scandx, scan, $
          charsize=1.5, thick=2, charthick=2, xthick=2, ythick=2, $
          background=255, color=0, $
          title=fits_file + ' Radial Scan @' + sangle + ' degrees', $
          xtitle='Radius [Rsun]', $
          ytitle='Calibrated Polarization Brightness Intensity B/Bsun', $
          yrange=[1.0e-09, 1.0e-05], ystyle=2, ylog=1
  endelse

  save = tvrd()
  write_gif, gif_file, save, redlut, greenlut, bluelut

  device, /close

  ; plot radial scan to a postscript file
  if (keyword_set(ps)) then begin
   ps_file  = strmid(fits_file, 0, extpos) + '_pa' + sangle + '_plot.ps'
   print, 'ps_file: ', ps_file
   set_plot, 'PS'
   device, filename=ps_file

   if (yminset or ymaxset) then	begin
     plot, scandx, scan * 1.0e-06, $
           charsize=1.5, thick=2, charthick=2, xthick=2, ythick=2, $
           title=fits_file + ' Radial Scan @' + sangle + ' degrees', $
           xtitle='Radius [Rsun]', $
           ytitle='Calibrated Polarization Brightness Intensity B/Bsun', $
           yrange=[1.0e-09, 1.0e-05], ystyle=2, ylog=1

   endif else begin
     plot, scandx, scan * 1.0e-06, $
           charsize=1.5, thick=2, charthick=2, xthick=2, ythick=2, $
           title=fits_file + ' Radial Scan @' + sangle + ' degrees', $
           xtitle='Radius [Rsun]', $
           ytitle='Calibrated Polarization Brightness Intensity B/Bsun', $
           yrange=[1.0e-09, 1.0e-05], ystyle=2, ylog=1
   endelse

   device, /close
 endif

  set_plot, 'X'
end
