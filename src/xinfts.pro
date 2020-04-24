; docformat = 'rst'

;+
; Animate a sequence of FITS images.
;
; :Examples:
;   For example, to animate the FITS files in a test file `fits.ls`::
;
;     IDL> xinfts, 'fits.ls'
;
;   To control the rate of animation::
;
;     IDL> xinfts, 'fits.ls', rate=25
;     IDL> xinfts, 'fits.ls', rate=8, /label
;     IDL> xinfts, 'fits.ls', rate=2, /label, cm='~/color/sunset.lut'
;
;   To control the scaling of the image intensities::
;
;     IDL> xinfts, 'fits.ls', wmin=-1200, wmax=600
;
;   To use different colormaps::
;
;     IDL> xinfts, 'fits.ls', cm='dif'
;     IDL> xinfts, 'fits.ls', cm='chip1'
;     IDL> xinfts, 'fits.ls', cm='bwy'
;
;   `XINFTS` brings up a GUI to control the playback of the animation::
;
;   .. image:: xinfts-screenshot.png
;
; :Params:
;   listfile : in, required, type=string
;     filename of text file containing the names of the FITS files to be
;     animated
;
; :Keywords:
;   rate : in, optional, type=numerical, default=100
;     animation rate (range: 0-100)
;   label : in, optional, type=boolean
;     if present, label each image with frame #, date, time
;   cm : in, optional, type=string
;     name of color map file (ASCII, each line: index, red, green, blue)
;   order : in, optional, type=boolean, default=0
;     if set, image is displayed top to bottom; default is bottom to top
;   wmin : in, optional, type=float, default=DISPMIN value
;     window minimum intensity scaling value (overrides 'DISPMIN').
;   wmax : in, optional, type=float, default=DISPMIN value
;     window maximum intensity scaling value (overrides 'DISPMAX').
;
; :Uses:
;   fxread, fxpar
;
; :History:
;   07 Aug 1995: procedure created by Andrew L. Stanger, HAO/NCAR
;   11 Aug 1995: added order keyword, ALS, HAO/NCAR
;   11 Mar 1996: reduce image size if image is larger than 1000x1000.
;   14 Apr 1998: replaced "readfits" with "fxread", since "readfits"
;      did not always apply 'BSCALE/BZERO' to MK3 FITS images.
;   14 Oct 1999: Fix label position: ypos = nypix - 20 --> ypos = ydim - 20 
;      Move label to bottom of window.
;      Increase label size for SunOS.
;   07 Apr 2000: Rotate image if CROTA1 is not zero.
;      Also rotate PICS image if CROTA1 missing
;      but SOLAR_P0 is present in FITS header.
;   20 Apr 2000: Do NOT rotate image IF 'DATAFORM'='POLAR'.
;   20 Apr 2000: Use either 'CRROTA1' and 'CROTA1' in PICS images.
;      Note: CRROTA1 (incorrect spelling) was used for some
;      cropped & rotated PICS images.
;   15 Nov 2000: Add min & max keywords so that user may set scaling.
;   25 Jan 2001: Rotate ONLY if crpix1 & crpix2 are non-negative.
;   04 Sep 2001: Add /NAN keyword to BYTSCL call.
;   05 Sep 2001: Add default directory for color table (/home/cordyn/color).
;-
pro xinfts, listfile, $
            rate=rate, $
            label=label, $
            cm=cm, $
            order=order, $
            wmin=wmin, $
            wmax=wmax
  compile_opt strictarr

  if (not keyword_set(rate)) then rate = 100

  ; set character size
  label_size = 1
  if (strlowcase(!version.os) eq 'irix' ) then label_size = 2
  if (strlowcase(!version.os) eq 'sunos') then label_size = 2
  if (strlowcase(!version.os) eq 'linux') then label_size = 2

  rotang = 0.0

  n_images = file_lines(listfile)
  files = strarr(n_images)
  openr, lun, listfile, /get_lun
  readf, lun, files
  free_lun, lun

  ; read first image to get size information.
  fxread, files[0], imgbuf, first_header

  nbitpx = fxpar(first_header, 'BITPIX')
  naxis  = fxpar(first_header, 'NAXIS')
  nxpix  = fxpar(first_header, 'NAXIS1')
  nypix  = fxpar(first_header, 'NAXIS2')
  idate  = fxpar(first_header, 'DATE-OBS')
  itime  = fxpar(first_header, 'TIME-OBS')

  nxmax = 1000
  nymax = 1000
  xdim = nxpix
  ydim = nypix

  while (xdim gt nxmax or ydim gt nymax) do begin
    xdim = xdim / 2
    ydim = ydim / 2
  endwhile

  if      (nbitpx eq   8) then imgbuf = bytarr(xdim, nypix) $
  else if (nbitpx eq  16) then imgbuf = intarr(xdim, nypix) $
  else if (nbitpx eq  32) then imgbuf = lonarr(xdim, nypix) $
  else if (nbitpx eq -32) then imgbuf = fltarr(xdim, nypix) $
  else if (nbitpx eq -64) then imgbuf = dblarr(xdim, nypix) $
  else begin
    print, nbitpx, format='(%"unknown BITPIX: %d")'
    return
  endelse

  bkgbuf = intarr(xdim, ydim) 
  bkgbuf[*, *] = 0

  ; create a display window
  if (keyword_set(label)) then begin
    window, 20, xsize=xdim, ysize = ydim, color=256, /pixmap
    wset, 20
    device, set_character_size=[6, 9]
  endif

  ; load color table
  if (keyword_set(cm)) then begin
    print, 'cm: ', cm
    dirend = -1

    for i = 0, strlen(cm) - 1 do begin
      dirloc = strpos(cm, '/', i)
      if (dirloc ge 0) then dirend = dirloc
    endfor

    if (dirend ne -1) then begin
      print, 'dirend: ', dirend
      coldir = strmid(cm, 0, dirend)
      print, 'coldir: ', coldir
      ccm = strmid(cm, dirend+1, strlen (cm) - dirend - 1)
      print, 'ccm: ', ccm
    endif

    if (dirend eq -1) then begin
      lct, '/home/cordyn/color/' + cm + '.lut'
    endif else begin
      lct, cm					; Load specified colormap.
    endelse
  endif else loadct, 0   ; load greyscale colormap

  init = 'y'    ; --- init can be set to 'n'  once everything
  ; --- has been initialized,  
  ; --- i.e. once this routine has been run once... 

  if (init eq 'y') then begin
    xinteranimate, set=[xdim + 4, ydim + 4, n_images], /showload

    ; image loop
    for f = 0L, n_images - 1L do begin
      ; read image into array & scale intensity levels to range: 0-255.
      fxread, files[f], imgbuf, hdu   ; read FITS image in listfile

      dispmin = 0.0
      dispmax = 0.0
      wintop  = 249

      ; get information from FITS header
      nbitpx   = fxpar(hdu, 'BITPIX')
      naxis    = fxpar(hdu, 'NAXIS')
      nxpix    = fxpar(hdu, 'NAXIS1')
      nypix    = fxpar(hdu, 'NAXIS2')
      dispmin  = fxpar(hdu, 'DISPMIN')
      dispmax  = fxpar(hdu, 'DISPMAX')
      telescop = fxpar(hdu, 'TELESCOP')
      crpix1   = fxpar(hdu, 'CRPIX1',   COUNT=crpix1count)
      crpix2   = fxpar(hdu, 'CRPIX2',   COUNT=crpix2count)
      crota1   = fxpar(hdu, 'CROTA1',   COUNT=rotcount)
      crrota1  = fxpar(hdu, 'CRROTA1',  COUNT=rrotcount)
      pangle   = fxpar(hdu, 'SOLAR_P0', COUNT=pangcount)
      dataform = fxpar(hdu, 'DATAFORM', COUNT=dformcount)
      if (dformcount eq 1) then begin
        dform = dataform
      endif else begin
        dform = 'NONE'
      endelse

      if (n_elements(wmin) gt 0L) then winmin = wmin else winmin = dispmin
      if (n_elements(wmax) gt 0L) then winmax = wmax else winmax = dispmax

      print, 'winmin/winmax: ', winmin, winmax
      dimfac = 1.0

      ; reduce image size if xdim or ydim > 1000 pixels
      nxmax = 1000
      nymax = 1000
      xdim = nxpix
      ydim = nypix

      while (xdim gt nxmax or ydim gt nymax) do begin
        dimfac = dimfac * 2.0
        xdim = xdim / 2
        ydim = ydim / 2
      endwhile

      if (nxpix ne xdim or ydim ne nypix) then begin
        imgbuf = rebin(imgbuf, xdim, ydim)
      endif

      ; scale image to the range 0 -> 249
      if (nbitpx eq 8) then begin
        imgbuf = bytscl(imgbuf, top=wintop, /nan)
      endif else begin
        if (winmin lt winmax) then begin
          imgbuf = bytscl(imgbuf, min=winmin, max=winmax, top=wintop, /nan)
        endif else begin
          imgbuf = bytscl(imgbuf, top=wintop, /nan)
        endelse
      endelse

      ; if order keyword is set, reverse image top to bottom
      if (keyword_set(order)) then imgbuf = reverse(imgbuf, 2)

      ; rotate image (if needed)
      dpmpos = strpos(telescop, 'DPM')
      if (dpmpos ge 0 and rotcount eq 0 and rrotcount eq 0) then begin
        if (pangcount eq 1) then begin
          rotang = pangle
        endif else begin
          if (rrotcount eq 1) then begin
            rotang = -crrota1
          endif else begin
            if (rotcount eq 1) then begin
              rotang = -crota1
            endif else begin
              rotang = 0.0
            endelse
          endelse
        endelse
      endif

      if (rotcount eq 1) then begin
        if (crota1 ne 0.0 and strpos('POLAR', dform) lt 0) then begin
          rotang = -crota1
        endif else begin
          rotang = 0.0
        endelse
      endif

      mag = 1.0
      if (crpix1count eq 1 and crpix1 ge 0.0) then begin
        xcen = crpix1 / dimfac - 0.5
      endif else begin
        xcen = (xdim * 0.5) - 0.5
      endelse

      if (crpix2count eq 1 and crpix2 ge 0.0) then begin
        ycen = crpix2 / dimfac - 0.5
      endif else begin
        ycen = (ydim * 0.5) - 0.5
      endelse

      arotang = abs(rotang)
      if (rotang gt 0.0) then rotdir = 'CW' else rotdir = 'CCW'
      if (rotang ne 0.0) then begin
        print, filename, '  rotated ', arotang, ' degrees ', rotdir
        imgbuf = rot(imgbuf, rotang, mag, xcen, ycen, missing=0)
      endif

      ; label image if "label" keyword is set
      if (keyword_set(label)) then begin
        idate = fxpar(hdu, 'DATE-OBS', count=count)
        sizdate = size(idate)
        if (count eq 0 or sizdate[1] lt 8) then idate = filename

        itime = fxpar(hdu, 'TIME-OBS', count=count)
        siztime = size(itime)
        if (count eq 0 or siztime[1] lt 8) then itime = ''

        xpos = 10
        ypos = 10
        sframe = string(f, format='(%"FRAME %3d")')
        tv, imgbuf
        imglabel = sframe + '     ' + idate + '   ' + itime
        xyouts, xpos, ypos, imglabel, charsize=label_size, /device
        xinteranimate, frame=f, window=!d.window   ; load image window
      endif else begin
        xinteranimate, frame=f, image=imgbuf   ;l oad image array
      endelse
    endfor
  endif

  ; activate animation
  xinteranimate, rate 
end
