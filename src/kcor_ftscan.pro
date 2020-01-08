; docformat = 'rst'

;+
; Perform a K-coronagraph azimuthal scan using a FITS image [cartesian coord].
;
; Note: this procedure works best in private colormap mode (256 levels).
;
; :Params:
;   fits_file : in, required, type=string
;     FITS filename
;   radius : in, required, type=numeric
;     radius value [Rsun units]
;   thmin : in, required, type=numeric
;     beginning angle [degrees]
;   thmax : in, required, type=numeric
;     ending angle [degrees]
;   thinc : in, required, type=numeric
;     angle increment [degrees]
;
; :Keywords:
;   ymin : in, optional, type=numeric, default=0.0
;     Y-axis minimum value
;   ymax : in, optional, type=numeric, default=60000.0
;     Y-axis maximum value
;   text : in, optional, type=boolean
;     write scan values to a text file "{basename}_r{radius}_plot.txt"
;
; :Uses:
;   readfits, fxpar
;   tscan.pro    performs azimuthal (theta) scan
;   lct.pro      loads a color table from an ASCII file
;   rcoord.pro   converts between [r,th] and [x,y] coordinates
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   08 Feb 2001
;
; :History:
;   07 Jun 2001 adapt for SOHO/LASCO C2 (French version)
;   11 Nov 2015 adapt for KCor
;   04 Dec 2017 JB: set default ymin and ymax values
;-
pro kcor_ftscan, fits_file, radius, thmin, thmax, thinc, $
                 ymin=ymin, ymax=ymax, text=text
  compile_opt strictarr

  ; default variable values
  stars = '***'
  date_obs = ''
  time_obs = ''

  ftspos   = strpos(fits_file, '.fts')
  basename = strmid(fits_file, 0, ftspos)
  print, 'basename: ', basename

  ; read FITS image & header
  img = readfits(fits_file, hdu, /noscale)

  imin = min(img, max=imax)
  print, 'imin/imax: ', imin, imax

  ; get parameters from FITS header
  telescop = fxpar(hdu, 'TELESCOP')     ; telescope name
  instrume = fxpar(hdu, 'INSTRUME')     ; instrument name
  date_obs = fxpar(hdu, 'DATE-OBS')     ; observation date
  xdim     = fxpar(hdu, 'NAXIS1')       ; X dimension
  ydim     = fxpar(hdu, 'NAXIS2')       ; Y dimension
  xcen     = fxpar(hdu, 'CRPIX1')       ; X center
  ycen     = fxpar(hdu, 'CRPIX2')       ; Y center
  object   = fxpar(hdu, 'OBJECT')       ; object observed
  bunit    = fxpar(hdu, 'BUNIT')        ; brightness unit  (e.g., Bsun)
  cdelt1   = fxpar(hdu, 'CDELT1')       ; resolution   [arcsec/pixel]
  bscale   = fxpar(hdu, 'BSCALE')       ; physical = data * bscale + bzero
  bzero    = fxpar(hdu, 'BZERO')
  datamin  = fxpar(hdu, 'DATAMIN', count=qdatamin)  ; data minimum intensity
  datamax  = fxpar(hdu, 'DATAMAX', count=qdatamax)  ; data maximum intensity
  dispmin  = fxpar(hdu, 'DISPMIN', count=qdispmin)  ; display minimum intensity
  dispmax  = fxpar(hdu, 'DISPMAX', count=qdispmax)  ; display maximum intensity
  dispexp  = fxpar(hdu, 'DISPEXP', count=qdispexp)  ; display exponent
  roll     = fxpar(hdu, 'INST_ROT')                 ; instrument rotation angle (degrees)
  rsun     = fxpar(hdu, 'RSUN')                     ; solar radius [arcsec/Rsun]

  xcen = xcen - 1.0   ; FITS keyword origin = 1, IDL index origin = 0
  ycen = ycen - 1.0   ; FITS keyword origin = 1, IDL index origin = 0

  pixrs    = rsun / cdelt1
  type_obs = object

  dateobs = strmid(date_obs,  0, 10)   ; yyyy-mm-dd
  timeobs = strmid(date_obs, 11,  8)   ; hh:mm:ss

  ; Do not change bscale. This was meant to fix a problem in the old level 1
  ; data. J. Burkepile, July 2019
  ;if (bscale eq 1.0) then bscale = 0.001

  img = img * bscale + bzero

  print, 'bscale/bzero: ', bscale, bzero
  print, 'datamin/datamax: ', datamin, datamax
  print, 'dispmin/dispmax,dispexp: ', dispmin, dispmax, dispexp
  print, 'roll:  ', roll
  print, 'pixrs: ', pixrs

  if (qdispmin gt 0) then dmin = dispmin
  if (qdispmax gt 0) then dmax = dispmax
  if (qdispexp gt 0) then dexp = dispexp

  if (xcen lt 0.0) then xcen = (xdim - 1) / 2.0
  if (ycen lt 0.0) then ycen = (ydim - 1) / 2.0

  ylab = type_obs + ' [' + bunit + ']'

  print, 'date_obs: ', date_obs
  print, 'time_obs:  ', time_obs
  print, 'xdim/ydim: ', xdim, ydim
  print, 'xcen/ycen: ', xcen, ycen
  print, 'pixrs:     ', pixrs

  ; convert numerical values to strings
  srad   = string(radius, format='(F5.2)')
  srad   = strtrim(srad, 2)
  sthmin = string(thmin, format='(F7.2)')
  sthmin = strtrim(sthmin, 2)
  sthmax = string(thmax, format='(F7.2)')
  sthmax = strtrim(sthmax, 2)

  ; do theta scan
  tscan, namimg, img, pixrs, roll, xcen, ycen, $
         thmin, thmax, thinc, radius, $
         scan, scandx, ns

  if (keyword_set(text)) then begin
    text_file = basename + '_r' + srad + '_plot.txt'
    openw, lun, text_file, /get_lun
    printf, lun, fits_file, '   Azimuthal scan   ', srad, ' Rsun'

    for i = 0, ns - 1 do begin
      printf, lun, 'scandx: ', scandx [i], ' degrees   scan: ', scan [i], $
              ' pB [B/Bsun]'
    endfor
    free_lun, lun
  endif

  ; reduce image size for display (if needed)
  sizemax = 1024
  sizeimg = size(img)

  while (sizeimg [1] gt sizemax or sizeimg [2] gt sizemax) do begin
    img  = rebin(img, xdim/2, ydim/2)
    xdim = xdim / 2
    ydim = ydim / 2
    xcen = xcen / 2.0
    ycen = ycen / 2.0
    pixrs = pixrs / 2.0
    sizeimg = size(img)
  endwhile

  ; establish graphics device
  ;set_plot, 'X'
  ;device, pseudo_color=8
  ;window, xsize=xdim, ysize=ydim, retain=2

  set_plot, 'Z'
  device, set_resolution=[1024, 1024], set_colors=256, z_buffering=0

  ; load color table
  ;lct, filepath('bwcp.lut', subdir=['..', 'resources'], root=mg_src_root())
  ;lct, filepath('bwy.lut', subdir=['..', 'resources'], root=mg_src_root())
  ;lct, filepath('dif.lut', subdir=['..', 'resources'], root=mg_src_root())
  lct, filepath('quallab.lut', subdir=['..', 'resources'], root=mg_src_root())

  redlut   = bytarr(256)
  greenlut = bytarr(256)
  bluelut  = bytarr(256)

  ; color LUT designations for annotation
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250

  ; read color lookup tables
  tvlct, redlut, greenlut, bluelut, /get   ; read color table into arrays

  ; display image
  imin = min(img, max=imax)
  dmin = 0.0
  dmax = 1.2
  dexp = 0.7

  ;imgb = bytscl(img, min=imin, max=imax, top=249)
  ;imgb = bytscl(img, min=dispmin, max=dispmax, top=249)
  ;imgb = bytscl(img, min=-35, max=35)

  imgb = bytscl(img^dexp, min=dmin, max=dmax, top=249)
  tv, imgb

  ; label image
  xyouts,        2, ydim-15, fits_file, /device,       color=green, charsize=1.2
  xyouts,        2, ydim-30, telescop,  /device,       color=green, charsize=1.2
  xyouts, xdim-110, ydim-15, dateobs,   /device,       color=green, charsize=1.2
  xyouts, xdim-110, ydim-30, timeobs + ' UT', /device, color=green, charsize=1.2
  xyouts,        2,  20, srad + ' Rsun', /device,      color=red,   charsize=1.2
  xyouts,        2,   5, sthmin + ' - ' + sthmax + ' deg.', 	$
                 /device, color=red, charsize=1.2

  ; plot theta scan on image
  th = thmin - thinc
  for i = 0, ns - 1 do begin
    th += thinc
    ierr = rcoord(radius, th, x, y, 1, roll, xcen, ycen, pixrs)
    ixg = fix(x + 0.5)
    iyg = fix(y + 0.5)
    plots, [ixg, ixg], [iyg, iyg],         /device, color=red
    plots, [ixg-1, ixg+1], [iyg-1, iyg+1], /device, color=red
    plots, [ixg-1, ixg+1], [iyg,   iyg  ], /device, color=red
    plots, [ixg-1, ixg+1], [iyg+1, iyg-1], /device, color=red
    plots, [ixg,   ixg  ], [iyg+1, iyg-1], /device, color=red
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
    r = -0.2
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
    r = 0.1
    for i = 0, 9 do begin
      r += 0.1 
      ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
      ixg = fix(x + 0.5)
      iyg = fix(y + 0.5)
      plots, [ixg, ixg], [iyg, iyg], /device, color=yellow
    endfor
    th += 90.0
  endfor

  ; read annotated image into 2D array
  img_plot = tvrd()
  gif_file = basename + '_r' + srad + '_img.gif'
  print, 'gif_file: ', gif_file

  ; save annotated image to a GIF file
  write_gif, gif_file, img_plot, redlut, greenlut, bluelut

  ; Y-axis plot range
  yminset = 0
  ymaxset = 0

  if (n_elements(ymin) eq 0L) then begin
    ymin = 0.0
  endif

  if (n_elements(ymax) eq 0L) then begin
    ymax = 60000.0
  endif

  print, 'ymin/ymax: ', ymin, ymax
  print, 'yrange: ', ymin, ymax

  ; plot theta scan to a GIF file
  gif_file  = basename + '_r' + srad + '_plot.gif'
  print, 'plot name: ', gif_file
  set_plot, 'Z'
  device, set_resolution=[1440, 768], decomposed=0, set_colors=256, $
        z_buffering=0

  plot, scandx, scan, $
        background=255, color=0, charsize=1.0,	$
        title='Theta Scan ' + fits_file + ' ' + srad + ' Rsun', $
        xtitle='Position Angle', $
        ytitle=ylab, yrange=[ymin, ymax]

  img_disp = tvrd()
  write_gif, gif_file, img_disp
  device, /close

  ; plot theta scan to a postscript file
  ps_file  = basename + '_r' + srad + '_plot.ps'
  print, 'ps_file: ', ps_file
  set_plot, 'PS'
  device, filename=ps_file

  plot, scandx, scan, $
        title='Theta Scan ' + fits_file + ' ' + srad + ' Rsun',	$
        xtitle='Position Angle', $
        ytitle=ylab, $
        yrange=[ymin, ymax]

  device, /close

  set_plot, 'X'
end
