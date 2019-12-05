; docformat = 'rst'

;+
; Draw radial rays.
;
; :Params:
;   rmin, rmax : in
;     start/stop radii [Rsun]
;   rinc : in
;     increment for radius [Rsun]
;   anginc : in
;     angular increment [degrees].
;   dotsize : in
;     dot size [1, 3, 5, 7, ...] [pixels]
;   xcen, ycen : in
;     sun center [pixels]
;   pixrs : in
;     # pixels/Rsun
;   scroll : in
;     spacecraft roll [degrees]
;   cindex : in
;     color index [0-255]
;   xmin, ymin : in
;     lower left  corner of window
;   xmax, ymax : in
;     upper right corner of window
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
