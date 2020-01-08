; docformat = 'rst'

;+
; Draw radial rays.
;
; :Params:
;   rmin : in, required, type=numeric
;     minimum radii [Rsun]
;   rmax : in, required, type=numeric
;     maximum radii [Rsun]
;   rinc : in, required, type=numeric
;     increment for radius [Rsun]
;   anginc : in, required, type=numeric
;     angular increment [degrees]
;   dotsize : in, required, type=integer
;     dot size [1, 3, 5, 7, ...] [pixels]
;   xcen : in, required, type=numeric
;     x-coordinate of sun center [pixels]
;   ycen : in, required, type=numeric
;     y-coordinate of sun center [pixels]
;   pixrs : in, required, type=float
;     # pixels/Rsun
;   scroll : in, required, type=float
;     spacecraft roll [degrees]
;   cindex : in, required, type=integer
;     color index [0-255]
;   xmin : in, required, type=numeric
;     x-coordinate of lower left  corner of window
;   ymin : in, required, type=numeric
;     y-coordinate of lower left  corner of window
;   xmax : in, required, type=numeric
;     x-coordinate of upper right corner of window
;   ymax : in, required, type=numeric
;     y-coordinate of upper right corner of window
;
; :Uses:
;   rcoord, wvec
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   10 Jan 2006
;   Adapted from "glcp_suncir.c".
;
; :History:
;   18 Nov 2015 [ALS] Modify for kcor
;-
pro kcor_sunray, rmin, rmax, rinc, anginc, dotsize, $
                 xcen, ycen, pixrs, scroll, cindex, $
                 xmin, xmax, ymin, ymax
  compile_opt strictarr

  nres = 1   ; low resolution only
  ;cproll = 43.0		; C/P axis is 43 deg CCW from +Y axis.
  cproll = 0.0
  p = fix(dotsize) / 2

  ; draw radial scans (r=r1min -> r1max) every ang1inc degrees
  for th = 0.0, 360.0, anginc do begin
    ;if (th eq 180.0) then rmin = 0.2 else rmin = 0.4

    for r = rmin, rmax, rinc do	begin
      ierr = rcoord(r, th, xx, yy, 1, scroll + cproll, xcen, ycen, pixrs)
      xg = ((xx / nres) + 0.5) + xmin
      yg = ((yy / nres) + 0.5) + ymin

      for yp = yg - p, yg + p do begin
        if (xg - p ge xmin and xg + p le xmax  and $
            yp     ge ymin and yp     le ymax) then begin
          wvec, xg-p, yp, xg+p, yp, cindex
        endif
      endfor
    endfor
  endfor
end
