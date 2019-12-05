; docformat = 'rst'

;+
; Annotate a FITS image.
;
; :Params:
;   hdu : in
;     FITS header
;   xdim : in
;     x-axis dimension
;   ydim : in
;     y-axis dimension
;   xb : in
;     x-axis border for annotation
;   yb: in
;     y-axis border for annotation
;
; :History:
;   Andrew L. Stanger   HAO/NCAR   14 September 2001
;   28 Dec 2005: update for SMM C/P.
;   12 Nov 2015: Adapt for kcor.
;-
pro kcor_fits_annotate, hdu, xdim, ydim, xb, yb, $
                        wmin=wmin, wmax=wmax, wexp=wexp
  compile_opt strictarr

  print, '*** kcor_fits_annotate ***'

  month_name = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  ; define fonts

  !p.font = 1
  ;device, set_font='Helvetica', /tt_font

  ;bfont = '-adobe-courier-bold-r-normal--20-140-100-100-m-110-iso8859-1'
  bfont = '-*-times-bold-r-normal-*-16-*-100-100-*-*-*-*'
  bfont = '-*-helvetica-*-r-*-*-24-*-*-*-*-*-*-*'
  ;bfont = (get_dfont (bfont))(0)
  if (bfont eq '') then bfont = 'fixed'
  ;bfont = 0
  bfont = -1
  ;bfont = 6

  ;lfont = '-misc-fixed-bold-r-normal--13-100-100-100-c-70-iso8859-1'
  ;lfont = '-*-lucida-*-r-*-*-14-*-*-*-*-*-*-*'
  lfont = '-*-helvetica-*-r-*-*-14-*-*-*-*-*-*-*'
  lfont = '-*-helvetica-*-r-*-*-10-*-*-*-*-*-*-*'
  ;lfont = (get_dfont (lfont))(0)
  if (lfont eq '') then lfont = 'fixed'
  lfont = -1

  tfont = '-*-itc bookman-*-r-*-*-14-*-*-*-*-*-*-*'
  ;tfont = (get_dfont (tfont))(0)
  if (tfont eq '') then tfont = 'fixed'
  tfont = -1

  ;-----------------
  ; Character sizes:
  ;-----------------

  xoff =  2
  yoff =  2

  xx1   =  8
  xx2   =  9
  xx3   = 12

  xx1   =  5
  xx2   =  8
  xx3   = 10

  yy1   = 14
  yy2   = 16
  yy3   =  8

  yy1   = 10
  yy2   = 12
  yy3   = 14

  cfac = 1.0
  cfac = 1.8
  if (strlowcase(!version.os) eq 'irix') then cfac = 1.0
  if (strlowcase(!version.os) eq 'sunos' ) then cfac = 2.0

  cs1 = cfac * 0.75   ; character size
  cs2 = cfac * 1.0
  cs3 = cfac * 1.25
  cs4 = cfac * 1.5

  print, 'cs1/cs2/cs3/cs4: ', cs1, cs2, cs3, cs4
  
  x1 = fix(xx1 * cs1 + 0.5)
  x2 = fix(xx1 * cs2 + 0.5)
  x3 = fix(xx1 * cs3 + 0.5)
  x4 = fix(xx1 * cs4 + 0.5)

  y1 = fix(yy1 * cs1 + 0.5)
  y2 = fix(yy1 * cs2 + 0.5)
  y3 = fix(yy1 * cs3 + 0.5)
  y4 = fix(yy1 * cs4 + 0.5)

  print, 'y1/y2/y3: ', y1, y2, y3

  xend = xdim + xb - x1 
  yend = ydim + yb - y1

  ; color assignments for annotation
  white  = 255
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250
  black  =   0

  ; get information from FITS header
  object    = fxpar(hdu, 'OBJECT')
  datatype  = fxpar(hdu, 'DATATYPE', count=qdatatype)
  ;type_obs  = fxpar(hdu, 'TYPE-OBS')
  origin    = fxpar(hdu, 'ORIGIN')
  telescop  = strtrim(fxpar (hdu, 'TELESCOP'), 2)
  instrume  = strtrim(fxpar (hdu, 'INSTRUME'), 2)
  date_obs  = fxpar(hdu, 'DATE-OBS', count=qdate_obs)
  time_obs  = fxpar(hdu, 'TIME-OBS', count=qtime_obs)

  xcen      = fxpar(hdu, 'CRPIX1') - 1
  ycen      = fxpar(hdu, 'CRPIX2') - 1
  bunit     = fxpar(hdu, 'BUNIT')
  bscale    = fxpar(hdu, 'BSCALE')
  bzero     = fxpar(hdu, 'BZERO')
  datamin   = fxpar(hdu, 'DATAMIN',  count=qdatamin)
  datamax   = fxpar(hdu, 'DATAMAX',  count=qdatamax)
  dispmin   = fxpar(hdu, 'DISPMIN',  count=qdispmin)
  dispmax   = fxpar(hdu, 'DISPMAX',  count=qdispmax)
  dispexp   = fxpar(hdu, 'DISPEXP',  count=qdispexp)

  cdelt1    = fxpar(hdu, 'CDELT1',   count=qcdelt1)
  rsun      = fxpar(hdu, 'RSUN_OBS', count=n_rsun)
  if (n_rsun eq 0L) then rsun = fxpar (hdu, 'RSUN', count=n_rsun)
  
  expdur    = fxpar(hdu, 'EXPTIME')
  roll      = fxpar(hdu, 'INST_ROT')

  dateobs  = strmid(date_obs,  0, 11)
  timeobs  = strmid(date_obs, 11,  8)

  year     = strmid(date_obs, 0, 4)
  month    = strmid(date_obs, 5, 2)
  day      = strmid(date_obs, 8, 2)
  iyear    = fix(year)
  imonth   = fix(month)
  iday     = fix(day)
  syear    = strtrim(string(iyear), 2)
  smonth   = month_name[imonth - 1]
  sday     = strtrim(string(iday),  2)
  sdate    = sday + ' ' + smonth + ' ' + syear

  date_img  = syear + '-' + smonth + '-' + sday
  time_img  = timeobs + ' UT'
  type_obs  = object

  pixrs    = rsun / cdelt1
  srsun    = string(rsun, format='(F7.2)')

  ;if (datamin EQ 0.0 and datamax EQ 0.0) then $
  ;begin
  ;  datamin = MIN (img)
  ;  datamax = MAX (img)
  ;end

  print, 'xcen, ycen: ', xcen, ycen
  print, 'rsun, cdelt1, pixrs : ', rsun, cdelt1, pixrs
  print, 'bscale/bzero: ', bscale, bzero
  print, 'datamin/datamax: ', datamin, datamax
  print, 'dispmin/dispmax,dispexp: ', dispmin, dispmax, dispexp

  ; determine min/max intensity range to display
  dmin = datamin
  dmax = datamax
  dexp = 1.0

  dmin = 0.0
  dmax = 1.2
  dexp = 0.7

  if (dispmin ne dispmax) then begin
    dmin = dispmin
    dmax = dispmax
  endif

  if (qdispmin ne 0) then dmin = dispmin
  if (qdispmax ne 0) then dmax = dispmax
  if (qdispexp ne 0) then dexp = dispexp

  if (keyword_set(wmin)) then dmin = wmin
  if (keyword_set(wmax)) then dmax = wmax
  if (keyword_set(wexp)) then dexp = wexp

  print, 'dmin/dmax/dexp: ', dmin, dmax, dexp

  ixcen     = fix(xcen + 0.5)
  iycen     = fix(ycen + 0.5)
  iexpdur   = fix(expdur + 0.5)
  iroll     = fix(roll + 0.5)

  img_source = object

  ; choose data format for min/max values
  sdatamin   = strtrim(string(datamin, format='(E8.2)'), 2)
  if (datamin eq 0.0) then begin
    sdatamin = strtrim(string(datamin, format='(I4)'  ), 2)
  endif

  sdatamax = strtrim(string(datamax, format='(E8.2)'), 2)
  if (datamax eq 0.0) then begin
    sdatamax = strtrim(string(datamax, format='(I4)'  ), 2)
  endif

  sdispmin = strtrim(string(dispmin, format='(E8.2)'), 2)
  if (dispmin EQ 0.0) then begin
    sdispmin = strtrim(string(dispmin, format='(I4)'  ), 2)
  endif

  sdispmax = strtrim(string(dispmax, format='(E8.2)'), 2)
  if (dispmax eq 0.0) then begin
    sdispmax = strtrim(string(dispmax, format='(I4)'), 2)
  endif

  if (dmin ge 10000.0 or dmin lt 1.0) then begin
    sdmin = strtrim(string(dmin, format='(E8.2)'), 2)
  endif
  if (dmin lt 10000.0 and dmin gt 1.0) then begin
    sdmin = strtrim(string(dmin, format='(F9.1)'), 2)
  endif
  if (dmin eq 0.0) then begin
    sdmin = strtrim(string(dmin, format='(I4)'  ), 2)
  endif

  if (dmax ge 10000.0 or dmax lt 1.0) then begin
    print, '>10k dmax: ', dmax
    sdmax    = strtrim(string(dmax, format='(E8.2)'), 2)
  endif

  if (dmax lt 10000.0 and dmax gt 1.0) then begin
    print, '<10k dmax: ', dmax
    sdmax = strtrim(string(dmax, format='(F9.1)'), 2)
  endif

  if (dmax eq 0.0) then begin
    print,'zero dmax: ', dmax
    sdmax = strtrim(string(dmax, format='(I4)'), 2)
  endif

  sdexp = strtrim(string(dexp, format='(F4.2)'), 2)

  sexpdur   = strtrim(string(iexpdur, format='(I4)' ), 2)
  sexpdur   = strtrim(string(expdur, format='(F7.3)'), 2)
  sroll     = strtrim(string(iroll, format='(I4)'   ), 2)

  ; draw box around image
  wvec, 0,         yb,        0,         yb+ydim-1, grey
  wvec, 0,         yb+ydim-1, xdim+xb-1, yb+ydim-1, grey
  wvec, 0,         yb+ydim-1, 0,         yb+ydim-1, grey
  wvec, xb,        yb,        xdim+xb-1, yb,        grey
  wvec, xdim+xb-1, yb,        xdim+xb-1, ydim+yb-1, grey 
  wvec, xdim+xb-1, ydim+yb-1, xb,        ydim+yb-1, grey
  wvec, xb,        ydim+yb-1, xb,        yb,        grey
  wvec, 0,         yb,        xb,        yb,        grey

  ; annotate image
  ylab = yend - yoff
  ydat = ylab - y2
  xyouts, xoff, ylab, 'DATE',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, sdate,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'TIME',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, time_img,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'OBJECT',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, img_source,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

  if (object eq 'CORONA') then pixval = 'K-CORONA' else pixval = 'CALIBRATION'

  ;  IF (lfc  EQ 0) THEN pixval = '(K+F)'         
  ;  IF (lstr EQ 0) THEN pixval = 'S+'    + pixval
  ;  IF (lvig EQ 0) THEN pixval =           pixval + '*V'
  ;  IF (lcc  EQ 0) THEN pixval = '[' +     pixval + ']/C'

  pixval = strtrim(pixval, 2)
  print, 'pixval: ', pixval
  lenpixval = strlen(pixval)
  xloc = (xb - (lenpixval * x2)) / 2
  xloc = xoff
  if (xloc < 0) then xloc = xoff

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xloc, ylab,'INTENSITY SOURCE',	$
;          /device, charsize=1.0, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xloc, ydat, pixval,			$
;          /device, charsize=1.5, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'DATATYPE',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, datatype,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'FILTER',	$
;          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, colorfil,	$
;          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'POLAROID',	$
;          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, polaroid,	$
;          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  XYOUTS, xoff, ylab, 'SECTOR',	$
;          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  XYOUTS, xoff, ydat, sector,	$
;          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'EXPOSURE [sec]',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, sexpdur,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'SPACECRAFT ROLL',	$
;          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, sroll,	$
;          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'TELESCOPE',	$
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, telescop,	$
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y2 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'INSTRUMENT',	$
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, instrume,	$
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'OBJECT',	$
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, object,	$
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'TYPE-OBS',	$
;	  /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, type_obs,	$
;	  /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'DATA FORM',	$
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, dataform,	$
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'DATA MIN',	$
;          /device, charsize=1.0, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, sdatamin,	$
;          /device, charsize=1.5, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'DATA MAX',	$
;          /device, charsize=cs2, color=red
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, sdatamax,	$
;          /device, charsize=cs3, color=grey
;          /device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'DISP MIN',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, sdmin,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'DISP MAX',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, sdmax,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

  ylab = ylab - y1 - y2 - y3
  ydat = ylab - y2
  xyouts, xoff, ylab, 'DISP EXP',	$
          /device, charsize=cs2, color=red
          ;/device, font=lfont, charsize=cs1, color=red
  xyouts, xoff, ydat, sdexp,	$
          /device, charsize=cs3, color=grey
          ;/device, font=bfont, charsize=cs2, color=grey

;  print, 'wmin: ', wmin
;  if (keyword_set(wmin) or wmin eq 0.0) then	$
;  if (keyword_set(wmin)) then begin
;     wmin = strtrim(string(wmin, format='(E8.2)'), 2)
;     ylab = ylab - y1 - y2 - y3
;     ydat = ylab - y2
;     xyouts, xoff, ylab, 'WMIN',	$
;             /device, font=lfont, charsize=cs1, color=red
;     xyouts, xoff, ydat, wmin,	$
;             /device, font=bfont, charsize=cs2, color=grey
;  end

;  if (keyword_set(wmax)) then begin
;     wmax = strtrim (string (wmax, format='(e8.2)'), 2)
;     ylab = ylab - y1 - y2 - y3
;     ydat = ylab - y2
;     xyouts, xoff, ylab, 'wmax',	$
;             /device, font=lfont, charsize=cs1, color=red
;     xyouts, xoff, ydat, wmax,	$
;             /device, font=bfont, charsize=cs2, color=grey
;  end

;  ylab = ylab - y1 - y2 - y3
;  ydat = ylab - y2
;  xyouts, xoff, ylab, 'brightness unit',	$
;          /device, font=lfont, charsize=cs1, color=red
;  xyouts, xoff, ydat, bunit,		$
;          /device, font=bfont, charsize=cs2, color=grey

  ; draw sun circle
  g_mincol = xb
  g_maxcol = xb + xdim - 1
  g_minrow = yb
  g_maxrow = yb + ydim - 1

  radius =   1.0
  angmin =   0.0
  angmax = 360.0
  anginc =  10.0

  sun_circle, radius, angmin, angmax, anginc, yellow,  		$
              xcen, ycen, pixrs, roll,				$
              g_mincol, g_maxcol, g_minrow, g_maxrow

  radius = 1.6

  ; draw radial lines.
  rmin    =  1.2
  rmax    =  1.7
  rinc    =  0.2
  anginc  = 30.0
  dotsize =  3

  rmin    =  0.2
  rmax    =  1.0
  rinc    =  0.2
  anginc  = 90.0
  dotsize =  3

  kcor_sunray, rmin, rmax, rinc, anginc, dotsize,	$
               xcen, ycen, pixrs, roll, red,    	$
               g_mincol, g_maxcol, g_minrow, g_maxrow

  ; draw north pointer
  cirrad = 1.0
  tiprad = 0.2

  kcor_north,  xcen, ycen, pixrs, roll, cirrad, tiprad, yellow,	$
               g_mincol, g_maxcol, g_minrow, g_maxrow

  ; draw solar radius scale along bottom of image
  npixrs = fix(pixrs + 0.5)
  xcenwin = xcen + xb
  xloc = fix(xcenwin + 0.5)
  i = 0
  while (xloc ge xb and xloc le xdim+xb-1) do begin
    wvec, xloc, yb, xloc, yb-6, grey
    i = i + 1
    xloc = fix(xcenwin + pixrs * i + 0.5)
  endwhile

  xloc = FIX (xcenwin + 0.5)
  i = 0
  while (xloc ge xb and xloc le xdim+xb-1) do begin
    wvec, xloc, yb, xloc, yb-6, grey
    i = i + 1
    xloc = fix(xcenwin - pixrs * i - 0.5)
  endwhile

  wvec, ixcen+xb-3, yb-3, ixcen+xb+3, yb-3, grey

  ycenwin = ycen + yb
  yloc = FIX (ycenwin + 0.5)
  i = 0
  while (yloc ge yb and yloc le ydim+yb-1) do begin
    wvec, xb-6, yloc, xb, yloc, grey
    i = i + 1
    yloc = fix(ycenwin + pixrs * i + 0.5)
  endwhile

  yloc = FIX (ycenwin + 0.5)
  i = 0
  while (yloc ge yb and yloc le ydim+yb-1) do begin
    wvec, xb-6, yloc, xb, yloc, grey
    i = i + 1
    yloc = fix(ycenwin - pixrs * i - 0.5)
  endwhile

  wvec, xb-3, iycen+yb-3, xb-3, iycen+yb+3, grey

  ; create color bar array
  collin = bindgen(256)
  collin = rebin(collin, 512)
  colbar = bytarr(512, 12)
  for i = 0, 11 do colbar[*, i] = collin[*]

  ; draw color bar
  xc1 = xdim / 2 + xb -1 - 256   ; left   of color bar
  xc2 = xc1 + 511                ; right  of color bar
  yc1 = 26                       ; bottom of color bar
  yc2 = 37                       ; top    of color bar

  print, 'xc1,xc2,yc1,yc2: ', xc1, xc2, yc1, yc2

  tv, colbar, xc1, yc1

  ; draw border around color bar
  plots, [xc1-1,     yc1-1], /device, color=251
  plots, [xc1-1,     yc2+1], /device, color=251, /continue
  plots, [xc1-1+514, yc2+1], /device, color=251, /continue
  plots, [xc1-1+514, yc1-1], /device, color=251, /continue
  plots, [xc1-1,     yc1-1], /device, color=251, /continue

  ; draw tick marks below color bar
  plots, [xc1,     yc1- 3], /device, color=251
  plots, [xc1,     yc1- 7], /device, color=251, /continue
  plots, [xc1+ 63, yc1- 3], /device, color=251
  plots, [xc1+ 63, yc1- 7], /device, color=251, /continue
  plots, [xc1+127, yc1- 3], /device, color=251
  plots, [xc1+127, yc1- 7], /device, color=251, /continue
  plots, [xc1+191, yc1- 3], /device, color=251
  plots, [xc1+191, yc1- 7], /device, color=251, /continue
  plots, [xc1+255, yc1- 3], /device, color=251
  plots, [xc1+255, yc1- 7], /device, color=251, /continue
  plots, [xc1+319, yc1- 3], /device, color=251
  plots, [xc1+319, yc1- 7], /device, color=251, /continue
  plots, [xc1+382, yc1- 3], /device, color=251
  plots, [xc1+382, yc1- 7], /device, color=251, /continue
  plots, [xc1+447, yc1- 3], /device, color=251
  plots, [xc1+447, yc1- 7], /device, color=251, /continue
  plots, [xc2,     yc1- 3], /device, color=251
  plots, [xc2,     yc1- 7], /device, color=251, /continue

  ; label color bar
  print, 'cs1: ', cs1
  xyouts, xc1 -         x1 / 2, yc1 -  8 - y1,   '0', /device, $
          charsize=cs2, color=grey
          ;font=lfont, charsize=cs1, color=grey
  xyouts, xc1 + 127 - 2*x1 / 2, yc1 -  8 - y1,  '63', /device, $
          charsize=cs2, color=grey
          ;font=lfont, charsize=cs1, color=grey
  xyouts, xc1 + 255 - 3*x1 / 2, yc1 -  8 - y1, '127', /device, $
          charsize=cs2, color=grey
          ;font=lfont, charsize=cs1, color=grey
  xyouts, xc1 + 383 - 3*x1 / 2, yc1 -  8 - y1, '191', /device, $
          charsize=cs2, color=grey
          ;font=lfont, charsize=cs1, color=grey
  xyouts, xc1 + 512 - 1.5*x1 - 1, yc1 -  8 - y1, '255', /device, $
          charsize=cs2, color=grey
          ;font=lfont, charsize=cs1, color=grey

  ; draw title
  title = telescop
  lentit = STRLEN (title)
  print, 'lentit: ', lentit
  print, 'x4: ', x4
  print, 'lentit * x4 : ', lentit * x4
  xloc = xb + (xdim - (lentit * x4)) / 2
  ylab = yc2 + (yb - yc2 - y4) / 2 + FIX (y4 * 0.2) - 3
  ylab = yc2 + 10
  print, 'xloc: ', xloc
  print, 'yb, y4, ylab: ', yb, y4, ylab
  xyouts, xloc, ylab, title, $
          /device, charsize=cs4, color=red
          ;/device, font=bfont, charsize=cs4, color=red

  print, '<<<<<<< Leaving fits_annotate_kcor'
end
