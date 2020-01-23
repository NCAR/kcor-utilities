; docformat = 'rst'

;+
; Display a FITS image.
;
; :Examples:
;   Try::
;
;     kcor_fitsdisp, fits_name
;     kcor_fitsdisp, fits_name, wmin=1.0e-6
;     kcor_fitsdisp, fits_name, wmax=2.0e-6
;
; :Params:
;   fits_name : in, required, type=string
;     FITS filename
;
; :Keywords:
;   left_margin : in, optional, type=numeric, default=160
;     x-axis border for annotation
;   bottom_margin : in, optional, type=numeric, default=80
;     y-axis border for annotation
;;   wmin : in, optional, type=numeric, default=0.0
;     minimum used for display scaling, uses DISPMIN FITS keyword for default,
;     if not present then 0.0
;   wmax : in, optional, type=numeric, default=1.2e-7
;     maximum used for display scaling, uses DISPMAX FITS keyword for default,
;     if not present then 1.2e-7
;   wexp : in, optional, type=numeric, default=0.7
;     exponent used for display scaling, uses DISPEXP FITS keyword for default,
;     if not present then 0.7
;
; :Uses:
;   fxpar, readfits, kcor_fits_annotate
;
; :History:
;   Andrew L. Stanger   HAO/NCAR   14 September 2001
;   26 Sep 2001 [ALS] wide format (no colorbar BELOW image).
;   17 Nov 2015 [ALS] adapt for KCor
;-
pro kcor_fitsdisp, fits_name, $
                   left_margin=xb, bottom_margin=yb, $
                   wmin=wmin, wmax=wmax, wexp=wexp
  compile_opt strictarr

  ;print, '>>> kcor_fitsdisp'

  _xb = n_elements(xb) eq 0L ? 160 : xb
  _yb = n_elements(yb) eq 0L ? 80 : yb

  ftspos   = strpos(fits_name, '.fts')
  basename = strmid(fits_name, 0, ftspos)

  img = readfits(fits_name, hdu, /noscale, /silent)

  ; extract information from header
  xdim     = fxpar(hdu, 'NAXIS1')
  ydim     = fxpar(hdu, 'NAXIS2')

  ; "Erase" annotation area
  ;print, '### kcor_fitsdisp: erasing annotation area.'
  leftborder   = bytarr(_xb,        _yb + ydim) + 255B
  bottomborder = bytarr(_xb + xdim, _yb       ) + 255B
  tv, leftborder
  tv, bottomborder

  ; resize window if it has changed
  ;if (xdim ne xdim_prev or ydim ne ydim_prev) then $
  ;  window, xsize=xdim+_xb, ys=ydim+_yb

  xdim_prev = xdim
  ydim_prev = ydim

  ; annotate image
  ;kcor_fits_annotate, hdu, xdim, ydim, _xb, _yb, wmin=wmin, wmax=wmax, wexp=wexp

  ; get information from FITS header

  ;orbit_id = fxpar(hdu, 'ORBIT-ID')
  ;image_id = fxpar(hdu, 'IMAGE-ID')

  bitpix   = fxpar(hdu, 'BITPIX',   count=qbitpix)
  telescop = fxpar(hdu, 'TELESCOP', count=qtelescop)
  instrume = fxpar(hdu, 'INSTRUME', count=qinstrume)
  date_obs = fxpar(hdu, 'DATE-OBS', count=qdate_obs)
  time_obs = fxpar(hdu, 'TIME-OBS', count=qtime_obs)
  rsun     = fxpar(hdu, 'RSUN_OBS', count=qrsun)
  if (qrsun eq 0L) then rsun = fxpar(hdu, 'RSUN', count=qrsun)
  bunit    = fxpar(hdu, 'BUNIT',    count=qbunit)
  bzero    = fxpar(hdu, 'BZERO',    count=qbzero)
  bscale   = fxpar(hdu, 'BSCALE',   count=qbscale)
  datamin  = fxpar(hdu, 'DATAMIN',  count=qdatamin)
  datamax  = fxpar(hdu, 'DATAMAX',  count=qdatamax)
  dispmin  = fxpar(hdu, 'DISPMIN',  count=qdispmin)
  dispmax  = fxpar(hdu, 'DISPMAX',  count=qdispmax)
  dispexp  = fxpar(hdu, 'DISPEXP',  count=qdispexp)

  telescop = strtrim(telescop, 2)
  srsun    = string(rsun, format='(F7.2)')

  if (bitpix eq 16 and bscale eq 1.0) then bscale = 0.001 ; =1.0 < 15 Jul 2015.
  if (bscale ne 1.0) then img = img * bscale + bzero

  ; default display parameters
  dmin = 0.0
  dmax = 1.2e-6
  dexp = 0.7

  ; display image
  if (qdispmin gt 0) then dmin = dispmin    ; display min from header
  if (qdispmax gt 0) then dmax = dispmax    ; display max from header
  if (qdispexp gt 0) then dexp = dispexp    ; display exponent from header

  if (n_elements(wmin) gt 0L) then dmin = wmin   ; display min from keyword
  if (n_elements(wmax) gt 0L) then dmax = wmax   ; display max from keyword
  if (n_elements(wexp) gt 0L) then dexp = wexp   ; display exponent from keyword

  tv, bytscl(img^dexp, min=dmin, max=dmax, top=249), _xb, _yb

  ; annotate image
  kcor_fits_annotate, hdu, xdim, ydim, _xb, _yb, wmin=wmin, wmax=wmax, wexp=wexp
end
