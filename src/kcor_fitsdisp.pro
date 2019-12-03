; docformat = 'rst'

;+
; Display a FITS image.
;
; :Examples:
;   Try::
;
;     kcor_fitsdisp, fits_name, xdim_prev, ydim_prev, xb, yb
;     kcor_fitsdisp, fits_name, xdim_prev, ydim_prev, xb, yb, /gif
;     kcor_fitsdisp, fits_name, xdim_prev, ydim_prev, xb, yb, wmin=1.0
;     kcor_fitsdisp, fits_name, xdim_prev, ydim_prev, xb, yb, wmax=250.0
;
; :Uses:
;   kcor_fits_annotate
;
; :History:
;   Andrew L. Stanger   HAO/NCAR   14 September 2001
;   26 Sep 2001 [ALS] wide format (no colorbar BELOW image).
;   17 Nov 2015 [ALS] Adapt for kcor.
;-
pro kcor_fitsdisp, fits_name, xdim_prev, ydim_prev, xb, yb, $
	           gif=gif, wmin=wmin, wmax=wmax, wexp=wexp
  compile_opt strictarr

  print, '>>> kcor_fitsdisp'
  ;xb = 160		; X-axis border for annotation.
  ;yb =   0		; Y-axis border for annotation.

  ftspos   = strpos(fits_name, '.fts')
  basename = strmid(fits_name, 0, ftspos)

  img = readfits(fits_name, hdu, /noscale)

  ; extract information from header
  xdim     = fxpar(hdu, 'NAXIS1')
  ydim     = fxpar(hdu, 'NAXIS2')

  ; "Erase" annotation area
  print, '### kcor_fitsdisp: erasing annotation area.'
  leftborder   = bytarr(xb,        yb + ydim)
  bottomborder = bytarr(xb + xdim, yb       )
  leftborder   [*, *] = 255
  bottomborder [*, *] = 255
  tv, leftborder
  tv, bottomborder

  ; resize window if it has changed
  ;if (xdim NE xdim_prev OR ydim NE ydim_prev)  THEN $
  ;  window, xsize=xdim+xb, ys=ydim+yb

  xdim_prev = xdim
  ydim_prev = ydim

  ; annotate image
  ;kcor_fits_annotate, hdu, xdim, ydim, xb, yb, wmin=wmin, wmax=wmax, wexp=wexp

  ; get information from FITS header

  ;orbit_id = fxpar (hdu, 'ORBIT-ID')
  ;image_id = fxpar (hdu, 'IMAGE-ID')

  bitpix   = fxpar(hdu, 'BITPIX',   count=qbitpix)
  telescop = fxpar(hdu, 'TELESCOP', count=qtelescop)
  instrume = fxpar(hdu, 'INSTRUME', count=qinstrume)
  date_obs = fxpar(hdu, 'DATE-OBS', count=qdate_obs)
  time_obs = fxpar(hdu, 'TIME-OBS', count=qtime_obs)
  rsun     = fxpar(hdu, 'RSUN_OBS', count=qrsun)
  if (qrsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=qrsun)
  bunit    = fxpar(hdu, 'BUNIT',    count=qbunit)
  bzero    = fxpar(hdu, 'BZERO',    count=qbzero)
  bscale   = fxpar(hdu, 'BSCALE',   count=qbscale)
  datamin  = fxpar(hdu, 'DATAMIN',  count=qdatamin)
  datamax  = fxpar(hdu, 'DATAMAX',  count=qdatamax)
  dispmin  = fxpar(hdu, 'DISPMIN',  count=qdispmin)
  dispmax  = fxpar(hdu, 'DISPMAX',  count=qdispmax)
  dispexp  = fxpar(hdu, 'DISPEXP',  count=qdispexp)

  telescop = strtrim(telescop, 2)
  srsun    = string(rsun, FORMAT='(F7.2)')

  if (bitpix eq 16 and bscale eq 1.0) then bscale = 0.001 ; =1.0 < 15 Jul 2015.
  if (bscale ne 1.0) then img = img * bscale + bzero

  ; default display parameters
  dmin = 0.0
  dmax = 1.2
  dexp = 0.7

  ; display image
  if (qdispmin NE 0) then dmin = dispmin   ; display min from header
  if (qdispmax NE 0) then dmax = dispmax   ; display max from header
  if (qdispexp NE 0) then dexp = dispexp   ; display exponent from header

  if (keyword_set(wmin)) then dmin = wmin   ; display min from keyword
  if (keyword_set(wmax)) then dmax = wmax   ; display max from keyword
  if (keyword_set(wexp)) then dexp = wexp   ; display exponent from keyword
  
  tv, bytscl(img^dexp, min=dmin, max=dmax, top=249), xb, yb

  ; annotate image
  kcor_fits_annotate, hdu, xdim, ydim, xb, yb, wmin=wmin, wmax=wmax, wexp=wexp
end
