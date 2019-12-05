; docformat = 'rst'

;+
; Draws a North pointer with center [screen coordinates] at (xcen, ycen), circle
; radius 'cirrad', tip radius 'tiprad'.
; 
; If the coordinates fall outside the displayable screen area, the coordinates
; are clipped to the screen boundary.
;
; :Params:
;   xcen, ycen : in, required, type=float
;     sun center coordinates
;   pixrs : in, required, type=float
;     # pixels/Rsun
;   scroll : in, required, type=float
;     spacecraft roll
;   cirrad : in, required, type=float
;     circle radius [Rsun]
;   tiprad : in, required, type=float
;     tip radius    [Rsun]
;   cindex : in, required, type=integer
;     color LUT index [0-255]
;   g_mincol, g_maxcol : in, required, type=integer
;     min and max horizontal pixels
;   g_minrow, g_maxrow : in, required, type=integer
;     min and max vertical pixels.
;
; :Uses:
;   wvec.pro    draw a vector on the display screen.
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   SMM C/P
;
; :History:
;    5 Jun 1989  creation date.
;   21 Aug 1990: Remove 2 degree offset previously used.
;    4 Mar 1991: Make inner circle 0.1 Rsun.
;    4 Apr 1991: SGI/GL version.
;   30 Dec 2005: IDL version
;   17 Nov 2015 [ALS] Adapt for kcor.
;-
pro kcor_north, xcen, ycen, pixrs, scroll, cirrad, tiprad, cindex, $
                g_mincol, g_maxcol, g_minrow, g_maxrow
  compile_opt strictarr

  cproll =  0   ; C/P North is 43 deg CCW from +Y axis
  nres   =  1   ; low resolution only

  ; draw a dot at sun center
  r  = 0.0
  th = 0.0
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)

  xc = ((xx / nres) + 0.5) + g_mincol
  yc = ((yy / nres) + 0.5) + g_minrow
  wvec, xc-1, yc-1, xc+1, yc-1, 254
  wvec, xc-1, yc  , xc+1, yc  , 254
  wvec, xc-1, yc+1, xc+1, yc+1, 254

  ; north pointer tip coordinates
  r  = tiprad
  th = 0.0
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xpn = ((xx / nres) + 0.5) + g_mincol
  ypn = ((yy / nres) + 0.5) + g_minrow

  ; east wing tip coordinates
  r  = tiprad
  th = 90.0
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xwe = ((xx / nres) + 0.5) + g_mincol
  ywe = ((yy / nres) + 0.5) + g_minrow

  r = 0.1
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xce = ((xx / nres) + 0.5) + g_mincol
  yce = ((yy / nres) + 0.5) + g_minrow

  ; west wing tip coordinates
  r  = tiprad
  th = 270.0
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xww = ((xx / nres) + 0.5) + g_mincol
  yww = ((yy / nres) + 0.5) + g_minrow

  r = 0.1
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xcw = ((xx / nres) + 0.5) + g_mincol
  ycw = ((yy / nres) + 0.5) + g_minrow

  ; draw dots surrounding disk center pixel
  r  = 0.0
  th = 0.0
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xg = ((xx / nres) + 0.5) + g_mincol
  yg = ((yy / nres) + 0.5) + g_minrow

  if (xg ge g_mincol and xg le g_maxcol and yg ge g_minrow and yg le g_maxrow) then begin
    wvec, xg-1, yg-1, xg+1, yg-1, cindex
    wvec, xg-1, yg,   xg-1, yg,   cindex
    wvec, xg+1, yg,   xg+1, yg,   cindex 
    wvec, xg-1, yg+1, xg+1, yg+1, cindex
  endif

  ; draw circle around disk center
  r = cirrad

  for th = 0.0, 360.0, 10.0 do begin
    ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
    xg = ((xx / nres) + 0.5) + g_mincol
    yg = ((yy / nres) + 0.5) + g_minrow

    if (xg ge g_mincol and xg le g_maxcol and $
        yg ge g_minrow and yg le g_maxrow) then begin
      wvec, xg-1, yg-1, xg+1, yg+1, cindex
      wvec, xg-1, yg+1, xg+1, yg-1, cindex
    endif
  endfor

  ; draw line from circle to north pointer tip
  r = cirrad
  th = 0.0
  ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
  xg = ((xx / nres) + 0.5) + g_mincol
  yg = ((yy / nres) + 0.5) + g_minrow

  ; draw north pointer

  ; north pointer tip to east wing tip
  if (xpn ge g_mincol and $
      xpn le g_maxcol and $
      ypn ge g_minrow and $
      ypn le g_maxrow and $
      xwe ge g_mincol and $
      xwe le g_maxcol and $
      ywe ge g_minrow and $
      ywe le g_maxrow) then wvec, xpn, ypn, xwe, ywe, cindex

  ; circle to east wing tip
  if (xce ge g_mincol and $
      xce le g_maxcol and $
      yce ge g_minrow and $
      yce le g_maxrow and $
      xwe ge g_mincol and $
      xwe le g_maxcol and $
      ywe ge g_minrow and $
      ywe le g_maxrow) then wvec, xce, yce, xwe, ywe, cindex

  ; north pointer tip to west wing tip
  if (xpn ge g_mincol and $
      xpn le g_maxcol and $
      ypn ge g_minrow and $
      ypn le g_maxrow and $
      xww ge g_mincol and $
      xww le g_maxcol and $
      yww ge g_minrow and $
      yww le g_maxrow) then wvec, xpn, ypn, xww, yww, cindex

  ; circle to west wing tip
  if (xcw ge g_mincol and $
      xcw le g_maxcol and $
      ycw ge g_minrow and $
      ycw le g_maxrow and $
      xww ge g_mincol and $
      xww le g_maxcol and $
      yww ge g_minrow and $
      yww le g_maxrow) then wvec, xcw, ycw, xww, yww, cindex
end
