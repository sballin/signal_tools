; This file is an adapted combination of create_periscope_view_Xpt.pro and make_image_from_fl_map.pro from
; /usr/local/cmod/codes/spectroscopy/ir/FLIR

@/usr/local/cmod/codes/spectroscopy/ir/FLIR/get_ref_frame.pro
@/home/labombard/edge/modelling/geometry/xyz2rzphi.pro
@/usr/local/cmod/codes/spectroscopy/ir/FLIR/oplot_periscope_view.pro
@/usr/local/cmod/codes/spectroscopy/ir/FLIR/get_cmod_continuous_div_surface.pro
@/home/terry/idl_lib/ps.pro
@/home/terry/idl_lib/vector_rotation.pro
@/home/terry/kn1d/sol_lc.pro
pro create_periscope_view,shot=shot,xbox,ybox,nseg,lseg,Xseg,Yseg,ColorSeg,LabelSeg,IndexSeg,Rpixel,Zpixel,Phipixel,$
                          cmod=cmod,plot=plot,showrays=showrays,zrot=zrot,xshift=xshift,yshift=yshift,$
                          Rpin=Rpin,Zpin=Zpin,phipin=phipin,show_roi=show_roi,mag=mag,rzphiplot=rzphiplot,$
                          windowmag=windowmag,camera_view=camera_view,roi=roi,set_roi_slot=set_roi_slot,$
                          view_ramped_tiles=view_ramped_tiles,show_field_line=show_field_line,$
                          proj_onto_pixels=proj_onto_pixels,ps=ps,locate_pt=locate_pt,continuous_div=continuous_div,$
                          shadow1=shadow1,shadow2=shadow2,back_illum_regis=back_illum_regis,$
                          fl_shot=fl_shot,fl_time=fl_time

common tile_outline,_xbox,_ybox,_nseg,_lseg,_Xseg,_Yseg,_ColorSeg,_LabelSeg,_IndexSeg,_Rpixel,_Zpixel,_Phipixel,_roi,_cmod,_ramp_version

; Hardcoded test6 settings found to best match calibration with glowsticks
Rpin=1.00
Zpin=-0.252
phipin=11.
zrot=24.0
camera_view='X-pt'
proj_onto_pixels=1
show_field_line=1
alpha=-34.
beta=-14.
f_o_v_angle=15.
plot=0

;
; KEYWORDS
; shot - specifying this sets the geometry of the ramped tiles to the
;        date of shot
; cmod - show the stick figure of the C-Mod PFCs
; show_background_tiles - not used
; view_ramped_tiles - load the J divertor ramped tiles if they
;                     will be in the periscope view
; camera_view - 'DIV' for the 2008-2012 A-port camera view or 'IR-A
;               port' for the IR view of J port from A port or
;               'X-PT' for the 2015 telescope view from the 
; showrays - if set, then rays from each ZYZseg point to the XYZ_eye
;            point are drawn (used for debugging only) 
; rzphiplot - plot the rzphi grids in the image plane
; zrot - in degrees
; xshift - in pixels assuming a xpix x ypix sized pixel image (used
;          when aligning with an actual camera image)
; yshift - in pixels assuming a xpix x ypix sized pixel image (used
;          when aligning with an actual camera image)
; locate_pt - if set, then you can use the cursor function to choose
;             up to 10 points in the image and determine the point-locations,
;             as well as angles and lengths of rays to those points
; continuous_div - if set, then the geometry of the 2014 continuous
;                  divertor (as designed 11/2012) is used in the view determination  
; mag - magnification of the stick plot 
; windowmag - keep at the default value (1) since otherwise it screws up the ROI
;             determinations
; show_field_line - shows the projections of specified fieldlines
;                   (set in lines 318-321) within the field-of-view
; roi - [not implemented]
; show_roi - [not implemented]
; set_roi_slot - [not implemented]


key_default,shot,1120904020L

if shot gt 1100601001 then ramp_version=2 else ramp_version=1
if shot eq -1 then ramp_version=2 

if ramp_version eq 1 then begin
  key_default,zrot,15.7
  key_default,xshift,0.013
  key_default,yshift,0.28
endif
if ramp_version eq 2 then begin
; use the 2010 reference frame 
   key_default,zrot,15.7
   key_default,xshift,-0.114
   key_default,yshift,0.092
endif
if ramp_version eq 1 then begin
;use the 2011 reference frame 
   key_default,zrot,15.7
   key_default,xshift,0.10
   key_default,yshift,0.166
endif
key_default,Rpin,1.05
key_default,Zpin,-0.165
key_default,phipin,0.
key_default,zrot,0
key_default,xshift,0.0
key_default,yshift,0.
key_default,plot,0
key_default,rzphiplot,0
key_default,showrays,0
key_default,cmod,1
key_default,mag,1.08
key_default,windowmag,1.0
key_default,camera_view,' '
key_default,show_roi,0
key_default,set_roi_slot,0
key_default,view_ramped_tiles,0
key_default,show_field_line,0
;key_default,psfile,''
key_default,ps,0
key_default,locate_pt,0
key_default,continuous_div,0
key_default,shadow1,180.
key_default,shadow2,180.
key_default,proj_onto_pixels,0
key_default,back_illum_regis,0

xpix=480
ypix=640
if camera_view eq 'IR-A port' then begin
   xpix=320
   ypix=256
endif
if locate_pt then plot=1
port_names=['A','B','C','D','E','F','G','H','J','K']
loadct,45,/sil
;if strlen(psfile) gt 0 then ps=1 else ps=0
if ps then begin
;  ps,file=psfile,/psfont
  pso
endif
;print,'zrot,xshift,yshift=',zrot,xshift,yshift
;
; Decide if the common block is already loaded
;
if (not plot) and (not show_roi) and (not set_roi_slot) then begin
  if type_of(_roi) ne 0 then begin
    if _cmod eq cmod and _ramp_version eq ramp_version then begin
;      xbox=_xbox & ybox=_ybox & nseg=_nseg & lseg=_lseg & Xseg=_Xseg & Yseg=_Yseg & ColorSeg=_ColorSeg & LabelSeg=_LabelSeg & IndexSeg=_IndexSeg
;      Rpixel=_Rpixel & Zpixel=_Zpixel & Phipixel=_Phipixel & roi=_roi
;      return
    endif
  endif
endif

p_pos=!p.position
if plot then begin
  if not ps then x,title='C-Mod Vacuum Vessel',mag=1.5,window=1
  create_XYZ_Coord,[-1.5,1.5],[-1.5,1.5],[-.7,.7],xrot=60,zrot=170,ps=ps
endif
;
; Optionally read and plot C-Mod Tiles
;
if cmod and not continuous_div then Get_CMod_Tile_Surface,nseg_CMOD,lseg_CMOD,XYZseg_CMOD,ColorSeg_CMOD,LabelSeg_CMOD,IndexSeg_CMOD,plot=plot
if cmod and continuous_div then Get_CMod_continuous_div_Surface,nseg_CMOD,lseg_CMOD,XYZseg_CMOD,ColorSeg_CMOD,LabelSeg_CMOD,IndexSeg_CMOD,plot=plot
; XYZseg_CMOD is a [3,120,714] array of XYZ coordinates of tile
; corners such that XYZseg_CMOD(3,i,j) are the XYZ coordinate vectors,
; nseg is the number of coordinate vectors,
; lseg(n) is the number of elements describing the path of the nth segment
; colorseg (intarr(nseg)) is the plot color of that segment
; labelseg=strarr(nseg)  &; text label that segment
; indexseg=intarr(nseg)  &; index that segment 

;
; Read and optionally plot J-divertor tile gaps and hardware
;
if view_ramped_tiles then begin
;   Get_J_Divertor_Surface,ramp_version=ramp_version,nseg,lseg,XYZseg,ColorSeg,LabelSeg,IndexSeg,RZPhiseg=RZPhiseg,plot=plot
   Get_J_Divertor_Surface,ramp_version=ramp_version,nseg_CMOD,lseg_CMOD,XYZseg_CMOD,ColorSeg_CMOD,LabelSeg_CMOD,IndexSeg_CMOD,RZPhiseg=RZPhiseg,plot=plot
   cmod=0
;
; A-port periscope is roughly at R=.76, Z=+.44, phi=0 degrees, i.e., on x=0 plane
;
;   rzphi2xyz,0.62913,-0.41641,270,xyz_spot
endif else begin
   cmod=1
endelse
;   print, 'enter coordinates [R(m),Z(m)] of the A port periscope pinhole '
;   read,Rpin,Zpin
rzphi2xyz,Rpin,Zpin,phipin,xyz_eye
print, 'enter the viewing angles (degs) at the pinhole (alpha (rel to the R_maj of the pinhole), beta (rel to horizontal), and the full angle of the f-o-v'
;read, alpha, beta,f_o_v_angle
;
; search the XYZseg_CMOD array for a segment point that makes the line
; between that segment point and the viewing point (xyz_eye) have
; angles close to the input viewing angles (alpha & beta) 
for i=0,nseg_CMOD-1 do begin
   for j=0,lseg_cmod(i)-1 do begin
; define the the vector between the 'eye' and each segment point
; the length of that vector is sqrt(total(v*v)) 
; the length of the component of that vector in the x-y plane is sqrt(total(v(0:1)*v(0:1)))
       v=(XYZseg_CMOD(*,j,i)-xyz_eye)
       if sqrt(total(v*v)) gt 0.1 and sqrt(total(v(0:1)*v(0:1))) gt 0.1 and sqrt(total(v*v)) lt 1.5*xyz_eye(1) then begin 
; note that the last condition is to keep the xyz_spot on the same
; side of the tokamak as the view
; since alpha is the angle in the horizontal plane (Z=const) and since
; (A dot B)=|A||B|cos(angle between them), cos(alpha) is the dot
; product of the x-y component of V and the x-y component of the
; xyz_eye vector divided by the product of the lengths of thos
; components, i.e. cos(alpha)= total(-xyz_eye(0:1)*v(0:1) / {(sqrt(total(v(0:1)*v(0:1)))xsqrt(total(xyz_eye(0:1)*xyz_eye(0:1)))}
           alpha_test=sign(XYZseg_CMOD(0,j,i))*acos(total(-xyz_eye(0:1)*v(0:1))/sqrt(total(v(0:1)*v(0:1)))/sqrt(total(xyz_eye(0:1)*xyz_eye(0:1))) < 1.)/!dtor
; since beta is the angle out of the horizontal plane of V, we have
; that sin(beta)=Vz/|V|,i.e. sin(beta)=V(2)/sqrt(total(v*v))
           beta_test=asin(v(2)/sqrt(total(v*v)) < 1.)/!dtor
;           if (abs(alpha-alpha_test) lt 5. and abs(beta-beta_test) lt 5.) then begin
;               print,XYZseg_CMOD(*,j,i),i,j,alpha_test,beta_test
               if (abs(alpha-alpha_test) lt 1. and abs(beta-beta_test) lt .3) then begin
                   xyz_spot=XYZseg_CMOD(*,j,i)
; Center of view is to be the point that approximately aligns with the desired alpha and beta
                   goto,get_out
               endif
;           endif
       endif
   endfor
endfor
; if we are here, then we were not able to find the vector from
; xyz_eye to a segment point that aligned with the view as defined by
; xyz_eye, alpha, and beta.
print, ' unable to find a line from xyz_eye to a segment point that aligns with alpha,beta - aborting'
goto, finish
get_out:
index1=j
index2=i
v_sight=xyz_spot-xyz_eye
v_sight_length=sqrt(total(v_sight*v_sight))
; see how close the xyz_spot is to the desired alpha and beta - see
; the equations above 
alpha_act=acos(total(-xyz_eye(0:1)*v_sight(0:1))/sqrt(total(v_sight(0:1)*v_sight(0:1)))/sqrt(total(xyz_eye(0:1)*xyz_eye(0:1))) < 1.)/!dtor
;alpha_act=asin(v_sight(0)/(sqrt(total(v_sight(0:1)*v_sight(0:1)))))/!dtor
beta_act=asin(v_sight(2)/v_sight_length)/!dtor
; calculate the angel between the central ray (v_sight) and the axis
; of the endoscope ([0,Rpin,Zpin]-[0,0,Zpin]
;v_endo=-[0,Rpin,Zpin]+[0,0,Zpin]
v_endo=-xyz_eye+[0,0,xyz_eye(2)]
gamma=acos(total(v_endo*v_sight)/v_sight_length/sqrt(total(v_endo*v_endo)) < 1.)
print,'angle between central ray and the endoscope axis is ',gamma/!dtor
;stop
;
; Draw line from center of ramped tiles to periscope aperture
;
xyz_sightline=[[xyz_spot],[xyz_eye]]
if plot then plots,xyz_sightline(0,*),xyz_sightline(1,*),xyz_sightline(2,*) ,/t3d,/data,color=2,thi=3
;
; If CMod and view_ramped_tiles, then concatenate arrays
;
if cmod and view_ramped_tiles then begin
  _XYZseg=fltarr(3,max([lseg_CMOD,lseg]),nseg_CMOD+nseg)
  _XYZseg(*,0:max(lseg_cmod)-1,0:nseg_CMOD-1)=XYZseg_CMOD
  _XYZseg(*,0:max(lseg)-1,nseg_CMOD:nseg_CMod+nseg-1)=XYZseg
  XYZSeg=_XYZseg
  _RZPhiseg=fltarr(3,max([lseg_CMOD,lseg]),nseg_CMOD+nseg)
  _RZPhiseg(*,0:max(lseg)-1,nseg_CMOD:nseg_CMod+nseg-1)=RZPhiseg
  RZPhiSeg=_RZPhiseg
  nseg=nseg_CMOD+nseg
  lseg=[lseg_CMOD,lseg]
  ColorSeg=[ColorSeg_CMOD,ColorSeg]
  LabelSeg=[LabelSeg_CMOD,LabelSeg]
  IndexSeg=[IndexSeg_CMOD,IndexSeg]
endif else begin
   XYZSeg=XYZseg_CMOD
   nseg=nseg_CMOD
   lseg=lseg_CMOD
   ColorSeg=ColorSeg_CMOD
   LabelSeg=LabelSeg_CMOD
   IndexSeg=IndexSeg_CMOD
endelse
if camera_view eq 'X-pt' then begin
   phi_cal=316.5
   if back_illum_regis then begin
      back=1
      view_corners_r_pre_meas=[0.51,0.583,0.5825,0.5095]
      view_corners_z_pre_meas=[-0.355,-0.357,-0.431,-0.429]
;      view_corner_R_post_meas=[0.536,0.5965,0.558,0.498] ; measured using back illumination on 1/29/2016
;      view_corner_z_post_meas=[-0.344,-0.383,-0.445,-0.4065] ; measured using back illumination on 1/29/2016
      view_corner_R_post_meas=[0.536,0.5965,0.558,0.498]-0.003 ; measured using shifted in from back illumination on 1/29/2016
      view_corner_z_post_meas=[-0.344,-0.383,-0.445,-0.4065]-0.005 ; shifted down from back illumination on 1/29/2016
      print,' select pre_2015 [0] or post-2015 [1] back-illumination registration'
      read,back
      if back eq 1 then begin 
         view_corners_r=view_corner_R_post_meas
         view_corners_z=view_corner_z_post_meas
      endif else begin
         view_corners_r=view_corner_R_pre_meas
         view_corners_z=view_corner_z_pre_meas
      endelse
   endif else begin
      ; this means that we are relying on
      ; the glo-stick registration of 1/2016
      view_corners_r=[0.51,0.583-0.005,0.5825-0.005,0.5095]
      view_corners_z=[-0.355,-0.357,-0.431,-0.429]
      view_corner_R_post_meas=[0.5965,0.536,0.558,0.498] ; measured using back illumination on 1/29/2016
      view_corner_z_post_meas=[-0.383,-0.344,-0.445,-0.4065] ; measured using back illumination on 1/29/2016
      center_r=avg(view_corners_r)
      center_z=avg(view_corners_z)
      vect_r=view_corners_r-center_r
      vect_z=view_corners_z-center_z
      view_rot_ang=26.
      for i=0,3 do begin 
         VECTOR_ROTATION,[vect_r(i),vect_z(i)],view_rot_ang,vect_p
         print,vect_p(0)+center_r,vect_p(1)+center_z
         view_corners_r(i)=vect_p(0)+center_r
         view_corners_z(i)=vect_p(1)+center_z 
;after applying a 26 deg rotation on the unshifted corners, I get 
;      view_corners_r=[0.530352,0.595087,0.562198, 0.497463]
;      view_corners_z=[-0.342845,-0.376644,-0.442936,-0.409137]
      endfor
   endelse

   for i=0,n_elements(view_corners_r)-1 do begin
      print,view_corners_r(i),view_corners_z(i)
      _CR=fltarr(2)+view_corners_r(i)
      _CZ=fltarr(2)+view_corners_z(i)
      _CPhi=(phi_cal+indgen(2)*0.5)*!dtor
; now make segments of this field line in the same format as the
; machine feature segments. Remember:
; XYZseg_CMOD is an [3,120,714] array of XYZ coordinates of tile
; corners such that XYZseg_CMOD(3,i,j) are the XYZ coordinate vectors,
; nseg is the number of coordinate vectors,
; lseg(n) is the number of elements describing the path of the nth segment
; colorseg (intarr(nseg)) is the plot color of that segment
; labelseg=strarr(nseg)  &; text label that segment
; indexseg=intarr(nseg)  &; index that segment
      rzphi2xyz,_CR,_CZ,_Cphi/!dtor,xyzseg_cal
      nseg_cal=1
      lseg_cal=n_elements(_CPhi)
      colorseg_cal=intarr(nseg_cal)+2 ; assign them a red color
      indexseg_cal=nseg+indgen(nseg_cal)
      labelseg_cal=strarr(nseg_cal)+'X-pt view corner at 316.5'
                                ; add another (3,max of lseg, seg #)
                                ; element to the _xyzseg array by 1st
                                ; writing the old array into the n-1
                                ; slots and then adding the new
                                ; segment to the nth slot. That is
                                ; done in the next 4 lines
      _XYZseg=fltarr(3,max([lseg,lseg_cal]),nseg+nseg_cal)
      _XYZseg(*,0:max(lseg)-1,0:nseg-1)=XYZseg
      _XYZseg(*,0:max(lseg_cal)-1,nseg)=XYZseg_cal
      XYZSeg=_XYZseg
; increase the # of segments by 1
      nseg=nseg+nseg_cal
; add the length of the new segment to the lseg array and do the same
; for tht ColorSeg, LabelSeg, and IndexSeg arrays 
      lseg=[lseg,lseg_cal]
      ColorSeg=[ColorSeg,ColorSeg_cal]
      LabelSeg=[LabelSeg,LabelSeg_cal]
      IndexSeg=[IndexSeg,IndexSeg_cal]
      if plot then plots,xyzseg_cal(0,*),xyzseg_cal(1,*),xyzseg_cal(2,*),/t3d,/data,color=3,thick=6
   endfor
endif
if show_field_line then begin
   print,'enter shot # and time for the field-line mapping, enter 0,0 if you want to map purely toroidal field-lines'
;   fl_shot=1150611004
;   fl_time=1.0

;   n_fl_R=20  ; for test2
;   n_fl_R=6 ; for texst1
;   n_fl_Z=20
;   fl_R=0.53+0.08*(indgen(n_fl_R)/(n_fl_R-1.))
;   fl_Z=-0.479+0.133*(indgen(n_fl_Z)/(n_fl_Z-1.))  ; for test2
;   fl_Z=-0.479+0.183*(indgen(n_fl_Z)/(n_fl_Z-1.)) ; for test1
;   fl_Z=[-0.43,-0.43] ;fl_z=[-.479, -.346, -.479, -.346] ;[-0.365,-0.367,-0.421,-0.47]
;   fl_R=[0.53,0.563]  ;fl_r=[.53, .53, .60, .60]
;   ;[0.52,0.57,0.57,0.565]
   if fl_shot ne 0 and fl_time ne 0 then begin
;      n_fl_Z=24
;      n_fl_R=19
      n_fl_Z=40
      n_fl_R=34
      fl_R=0.495+0.115*(indgen(n_fl_R)/(n_fl_R-1.))
      fl_Z=-0.49+0.14*(indgen(n_fl_Z)/(n_fl_Z-1.))
   endif else begin
      n_fl_Z=2
      n_fl_R=11
      fl_R_top_row=0.5097+indgen(n_fl_R)*0.00797 ; this is by measuring the top row of holes  and assumming the girdle is at 46.84 cm
      fl_Z=-0.4302+0.05459*indgen(n_fl_Z) ; this is by measuring the height of the holes and assumming the floor just beneath the girdle is at -47.53 cm
      fl_R_bot_row=0.5055+indgen(n_fl_R)*0.00793 ; this is by measuring the top row of holes  and assumming the girdle is at 46.84 cm
; The drawing shows that the top and bottom rows of holes should have been mades as
; fl_R=0.5137+0.008*indgen(n_fl_R) with fl_Z=-0.43+0.055*indgen(n_fl_Z)
      fl_R=fl_R_bot_row
   endelse
   print,fl_r
   for i=0,n_fl_Z-1 do begin
      for ii=0,n_fl_r-1 do begin
         if fl_shot ne 0 and fl_time ne 0 then SOL_LC,fl_shot,fl_time,reform(fl_R(ii)),reform(fl_Z(i)),0.5*!pi,0.01,LC,error,phipos=phi_cal+40.,plot=0,/limiters,cr=cr,cz=cz,cphi=cphi else begin
            if i eq 0 then _CR=fltarr(300)+fl_R_bot_row(ii)
            if i eq 1 then _CR=fltarr(300)+fl_R_top_row(ii)
            _CZ=fltarr(300)+fl_Z(i)
            _CPhi=(phi_cal+40.-(indgen(300)*80./299.))*!dtor
            goto,jump_fl
         endelse
         if error then goto,jump_fl
; now make segments of this field line in the same format as the
; machine feature segments. Remember:
; XYZseg_CMOD is a [3,120,714] array of XYZ coordinates of tile
; corners such that XYZseg_CMOD(3,i,j) are the XYZ coordinate vectors,
; nseg is the number of coordinate vectors,
; lseg(n) is the number of elements describing the path of the nth segment
; colorseg (intarr(nseg)) is the plot color of that segment
; labelseg=strarr(nseg)  &; text label that segment
; indexseg=intarr(nseg)  &; index that segment
         if cphi(1) gt cphi(0) then begin
;            SOL_LC,fl_shot,fl_time,reform(fl_R(ii)),$
;                   reform(fl_Z(i)),-0.5*!pi,0.01,LC,error,phipos=phipin,$
;                   plot=0,/limiters,cr=cr,cz=cz,cphi=cphi
            SOL_LC,fl_shot,fl_time,reform(fl_R(ii)),$
                   reform(fl_Z(i)),-0.5*!pi,0.01,LC,error,phipos=phi_cal+40,$
                   plot=0,/limiters,cr=cr,cz=cz,cphi=cphi
            if error then goto,jump_fl
;            fl_sign=-1.
            if cphi(1) gt cphi(0) then begin
;               print,'neither sol_lc direction gives a fieldline
;               going in the correct direction, so skipping
;               ',fl_R(ii),fl_Z(i)
               print, 'at R,Z='+sval(fl_R(ii),l=5)+','+sval(fl_z(i),l=6)+$
                      ' neither sol_lc direction gives a fieldline going in the correct direction, assuming fieldline is toroidal'
               _CPhi=CPhi(0)+(((alpha/abs(alpha))*!pi/1.5)-CPhi(0))*findgen(100)/99.0
               _CR=fltarr(100)+fl_R(ii)
               _CZ=fltarr(100)+fl_z(i)
               goto,jump_fl    
            endif
         endif
;         print,fl_R(ii),fl_Z(i)
         _CPhi=CPhi(0)+(CPhi(n_elements(CPhi)-1)-CPhi(0))*findgen(1000)/999.0
         _CPhi=_Cphi(0:locate(_Cphi,_Cphi(0)+(alpha/abs(alpha))*!pi/1.5))
         _CR=interpol(CR,CPhi,_CPhi)
         _CZ=interpol(CZ,CPhi,_CPhi)
         jump_fl:
         rzphi2xyz,_CR,_CZ,_Cphi/!dtor,xyzseg_fl
         nseg_fl=1
         lseg_fl=n_elements(_CPhi)
         colorseg_fl=intarr(nseg_fl)+4
         indexseg_fl=nseg+indgen(nseg_fl)
         labelseg_fl=strarr(nseg_fl)+'fieldline'+strtrim(i*n_elements(fl_r)+ii+1,2)
         _XYZseg=fltarr(3,max([lseg,lseg_fl]),nseg+nseg_fl)
         _XYZseg(*,0:max(lseg)-1,0:nseg-1)=XYZseg
         _XYZseg(*,0:max(lseg_fl)-1,nseg)=XYZseg_fl
         XYZSeg=_XYZseg
         nseg=nseg+nseg_fl
         lseg=[lseg,lseg_fl]
         ColorSeg=[ColorSeg,ColorSeg_fl]
         LabelSeg=[LabelSeg,LabelSeg_fl]
         IndexSeg=[IndexSeg,IndexSeg_fl]
         if plot then plots,xyzseg_fl(0,*),xyzseg_fl(1,*),xyzseg_fl(2,*),/t3d,/data,color=4,thi=3
;         jump_fl:
      endfor
   endfor
endif
;stop 
;
; find those segments in the XYZseg array that are within the desired cone of the view, ie
; those vectors [XYZseg-xyz_eye] whose dot product with
; [xyz_spot-xyz_eye] yields an angle le 0.5 of f_o_v_angle
;

nseg_sub=0
XYZseg_sub=fltarr(3,n_elements(XYZseg(0,*,0)),nseg) & ;XYZ coordinate vectors
lseg_sub=intarr(nseg)
colorseg_sub=intarr(nseg)
labelseg_sub=strarr(nseg)
indexseg_sub=intarr(nseg)
;stop
for i=0,nseg-1 do begin
   lcount=0
   for j=0,lseg(i)-1 do begin
      v=(XYZseg(*,j,i)-xyz_eye)
      ang=acos((total(v*v_sight)/v_sight_length/sqrt(total(v*v))) <1.)/!dtor
      if ang le f_o_v_angle/2. then begin
; If you are at this point, then this segment is to be included with
; those in the prescibed f-o-v
; now try to eliminate those segments that are shadowed by other
; segments with this view
          xyz2rzphi,XYZseg(*,j,i),a,b,c
          xyz2rzphi,xyz_spot,aa,bb,c_spot
; c is in degrees
          jt1=min([abs(c_spot-c),abs(c_spot+360.-c)],njt)
          if ((jt1 le shadow1 and njt eq 0) or (jt1 le shadow2 and njt eq 1)) then begin 
              XYZseg_sub(*,lcount,nseg_sub)=XYZseg(*,j,i)
              lcount=lcount+1
;              if j eq 0 then print,i
          endif
      endif
   endfor
;   if lcount gt 1 then begin
   if lcount ge 1 then begin
      lseg_sub(nseg_sub)=lcount
      colorseg_sub(nseg_sub)=colorseg(i)
      labelseg_sub(nseg_sub)=labelseg(i)
      indexseg_sub(nseg_sub)=indexseg(i)
;      print,nseg_sub, '  ',labelseg(i),'  ', colorseg(i)
      nseg_sub=nseg_sub+1
   endif
endfor
;
; trim the sub arrays
;
;nseg_sub=nseg_sub-1
XYZseg_sub=XYZseg_sub(*,0:max(lseg_sub)-1,0:nseg_sub-1)
; make the RZPhiseg_sub array and
; find the indices in the sub array that coorespond to the center of
; the view using the indices of the center from the large array 
RZPhiseg_sub=XYZseg_sub
for i=0,nseg_sub-1 do begin
   for j=0,lseg_sub(i)-1 do begin
      xyz2rzphi,XYZseg_sub(*,j,i),a,b,c
      RZPhiseg_sub(0,j,i)=a
      RZPhiseg_sub(1,j,i)=b
      RZPhiseg_sub(2,j,i)=c
      if XYZseg_sub(0,j,i) eq XYZseg(0,index1,index2) and XYZseg_sub(1,j,i) eq XYZseg(1,index1,index2) and $
XYZseg_sub(2,j,i) eq XYZseg(2,index1,index2) then begin
         spot_index1=j
         spot_index2=i
;         print,' the spot indices for the sub array are ',spot_index1,spot_index2
      endif
   endfor
endfor
lseg_sub=lseg_sub(0:nseg_sub-1)
ColorSeg_sub=ColorSeg_sub(0:nseg_sub-1)
;stop
;jtt=where(RZPhiseg_sub(0,0,*) gt 0.48,njtt)
;if njtt gt 0 then ColorSeg_sub(jtt)=2
jt2=where((RZPhiseg_sub(2,0,*) MOD 36) eq 0 and (RZPhiseg_sub(2,1,*) MOD 36) eq 0,njt)
if njt gt 0 then ColorSeg_sub(jt2)=1+nint((RZPhiseg_sub(2,0,jt2) MOD 360)/36)
LabelSeg_sub=LabelSeg_sub(0:nseg_sub-1)
IndexSeg_sub=IndexSeg_sub(0:nseg_sub-1)

;stop
;
; The image plane should be located a focal distance away from xyz_spot, along the sight line
;
fd=0.3 &;focal distance
xyz_slope=xyz_sightline(*,1)-xyz_sightline(*,0) ; note that this is also (xyz_eye-xyz_spot)
distance=sqrt(total((xyz_sightline(*,1)-xyz_sightline(*,0))^2))
image_plane_origin=xyz_eye-fd*xyz_slope/distance
; the minus sign moves the image (along the xyz_sightline) to a point IN FRONT
; OF xyz_eye, since this will keep the pinhole image of the view
; upright and not inverted/mirrored
; if you want to move the image plane behind the pinhole then comment
; out the next line
;image_plane_origin=xyz_eye+fd*xyz_slope/distance

;
; Build an image plane in a local x-y space.
;
scale=0.05/mag
dx=1.0 & dy=ypix*dx/xpix
xbox=[-dx,dx,dx,-dx]-xshift & ybox=[-dy,-dy,dy,dy]-yshift & z_image_plane=[0,0,0,0]
;
; Define the box in a local 3D space
;
_xyz_image_plane=fltarr(3,4)  
_xyz_image_plane(0,*)=xbox*scale
_xyz_image_plane(1,*)=ybox*scale
_xyz_image_plane(2,*)=z_image_plane
;
; Define a set of local coordinate axes to align the image plane with the view.
;  Select the local Z axis to be along the sightline
Zaxis=-xyz_spot+xyz_eye
;
;  Select the local X axis to be aligned with major radius coordinate to the image plane origin
Xaxis=image_plane_origin
Xaxis(*)=Xaxis(*)-[0,0,image_plane_origin(2)]
;
; Plot the desired local Z and X axes in C-Mod space
;
;if plot then begin
;  plots,[image_plane_origin(0),image_plane_origin(0)+Zaxis(0)],[image_plane_origin(1),image_plane_origin(1)+Zaxis(1)],$
;        [image_plane_origin(2),image_plane_origin(2)+Zaxis(2)],/t3d,/data,color=1
;  plots,[image_plane_origin(0),image_plane_origin(0)+Xaxis(0)],[image_plane_origin(1),image_plane_origin(1)+Xaxis(1)],$
;        [image_plane_origin(2),image_plane_origin(2)+Xaxis(2)],/t3d,/data,color=3
;
;  press_return,/psprompt
;endif
;
; Build a coordinate transformation centered on the image plane origin and aligned with new Z and X axes. Make Z-axis alignment exact.
;  Use it to transform the local x-y image plane to C-Mod coordinates.

xyz_image_plane=rotate_XYZ_axes(_xyz_image_plane,-1,XYZorigin=image_plane_origin,Xaxis=Xaxis,Zaxis=Zaxis,fixed='Z',$
                 xprime=xprime,yprime=yprime,zprime=zprime) 
;
; Plot xprime,yprime,zprime coordinate axes
;
if plot then begin
  plots,[image_plane_origin(0),image_plane_origin(0)+xprime(0)],[image_plane_origin(1),image_plane_origin(1)+xprime(1)],$
        [image_plane_origin(2),image_plane_origin(2)+xprime(2)],/t3d,/data,color=3
  plots,[image_plane_origin(0),image_plane_origin(0)+yprime(0)],[image_plane_origin(1),image_plane_origin(1)+yprime(1)],$
        [image_plane_origin(2),image_plane_origin(2)+yprime(2)],/t3d,/data,color=4
  plots,[image_plane_origin(0),image_plane_origin(0)+zprime(0)],[image_plane_origin(1),image_plane_origin(1)+zprime(1)],$
        [image_plane_origin(2),image_plane_origin(2)+zprime(2)],/t3d,/data,color=1
;
; Plot Image plane in C-Mod space
;
  plots,[reform(xyz_image_plane(0,*)),xyz_image_plane(0,0)],[reform(xyz_image_plane(1,*)),xyz_image_plane(1,0)],$
    [reform(xyz_image_plane(2,*)),xyz_image_plane(2,0)],/t3d,/data,color=4
  stop
;  press_return,/psprompt
endif
;
; Trace rays from XYZseg_sub (originally the gaps in the tiles) to XYZ_eye, intersecting with the image plane
;
;xyz_image=XYZseg
xyz_image=XYZseg_sub
for n=0,nseg_sub-1 do begin
  xyzRay1=reform(XYZseg_sub(*,0:lseg_sub(n)-1,n))
  xyzRay2=xyzRay1
  for m=0,n_elements(xyzRay2(0,*))-1 do xyzRay2(*,m)=xyz_eye
   ray_intersect,xyzRay1,xyzRay2,xyz_image_plane,xyzPoint,/allow_negative_rays
   xyz_image(*,0:lseg_sub(n)-1,n)=xyzPoint
   if showrays then begin
;
; Optional: plot rays
;
    for p=0,n_elements(xyzRay2(0,*))-1 do begin
      plots,[xyzRay1(0,p),xyzRay2(0,p)],[xyzRay1(1,p),xyzRay2(1,p)],[xyzRay1(2,p),xyzRay2(2,p)],/t3d,/data,color=4
   endfor
    stop
;    press_return,/psprompt
  endif
endfor
if showrays then press_return,/psprompt
;
; Plot image on 3D image plane
;   
if plot then begin
  for n=0,nseg_sub-1 do begin
    color=colorseg_sub(n)
    plots,xyz_image(0,0:lseg_sub(n)-1,n),xyz_image(1,0:lseg_sub(n)-1,n),xyz_image(2,0:lseg_sub(n)-1,n),/t3d,/data,color=color
  endfor
  stop
  ;press_return,/psprompt
endif
;
; Now apply the forward transformation to map the polygons drawn on the 3D image plane to local x-y space
;
image_2D=XYZ_image
for n=0,nseg_sub-1 do begin
   XYZ_2D=rotate_XYZ_axes(XYZ_image(*,0:lseg_sub(n)-1,n),1)  
; Optionally rotate view about Z-axis
   image_2D(*,0:lseg_sub(n)-1,n)=rotate_XYZ(XYZ_2D,[0.0,0.0,0.0],zrot=zrot*!dtor)  
endfor
if plot then begin
   ;if not ps then window,0,xsize=700,ysize=700,title='field-of-view in image plane'
   ;pos=[0.1,0.1,0.95,0.95]
;   plot,[min(image_2D(0,*,*)),max(image_2D(0,*,*))],[min(image_2D(1,*,*)),max(image_2D(1,*,*))],col=1,/nodata,pos=pos
   ;plot,[min(image_2D(1,*,*)),max(image_2D(1,*,*))],[min(image_2D(1,*,*)),max(image_2D(1,*,*))],col=1,/nodata,pos=pos
   for n=0,nseg_sub-1 do plots,image_2D(0,0:lseg_sub(n)-1,n),image_2D(1,0:lseg_sub(n)-1,n),col=colorseg_sub(n)
;   for nn=0,njt-1 do plots,image_2D(0,0:lseg_sub(jt2(nn))-1,jt2(nn)),image_2D(1,0:lseg_sub(jt2(nn))-1,jt2(nn)),col=colorseg_sub(jt2(nn)),thi=2
   ;xyouts,.15,.9,/norm,'(R,Z) of aperture=('+sval(rpin,l=5)+','+sval(zpin,l=5)+') m',col=1,charsiz=1.
   ;xyouts,.15,.85,/norm,'alpha, beta angles for view center='+sval(alpha_act,l=5)+','+sval(beta_act,l=6)+' deg',col=1,charsiz=1.
   ;xyouts,.15,.8,/norm,'full angle of f-o-v='+sval(f_o_v_angle,l=3)+' deg',col=1,charsiz=1.
;   for nn=0,njt-1 do xyouts,.85,.95-colorseg_sub(jt2(nn))*.05,/norm,port_names(colorseg_sub(jt2(nn))-1)+'-port',charsiz=1.,col=colorseg_sub(jt2(nn))
   ;plots,[image_2D(0,spot_index1,spot_index2)-0.002,image_2D(0,spot_index1,spot_index2)+0.002],[image_2D(1,spot_index1,spot_index2),image_2D(1,spot_index1,spot_index2)],col=1,thi=5
   ;plots,[image_2D(0,spot_index1,spot_index2),image_2D(0,spot_index1,spot_index2)],[image_2D(1,spot_index1,spot_index2)-0.002,image_2D(1,spot_index1,spot_index2)+0.002],col=1,thi=5
   if locate_pt then begin
      pt_alpha=fltarr(10)
      pt_beta=fltarr(10)
      dist_to_pin=fltarr(10)
      npts=1
      next:
      print,'click on image point whose distances/coordinates you want [out of plot box to move on]'
      cursor,a,b,/data
      wait,0.2
;      print,a,b
      if a lt !x.crange(0) or a gt !x.crange(1) or b lt !y.crange(0) or b gt !y.crange(1) then goto,done_with_pts
; now find image_2d point closest to the click image point
      dum=min(abs(image_2D(0,*,*)-a)+abs(image_2D(1,*,*)-b),ndum)
      ind = ARRAY_INDICES(reform(image_2D(0,*,*)),ndum)
      print,image_2D(0,ind(0),ind(1)),image_2D(1,ind(0),ind(1))
      ;plots,[image_2D(0,ind(0),ind(1))-0.005,image_2D(0,ind(0),ind(1))+0.005],[image_2D(1,ind(0),ind(1)),image_2D(1,ind(0),ind(1))],col=npts+1,thi=3
      lplots,[image_2D(0,ind(0),ind(1)),image_2D(0,ind(0),ind(1))],[image_2D(1,ind(0),ind(1))-0.005,image_2D(1,ind(0),ind(1))+0.005],col=npts+1,thi=3
      v_to_pt=xyzseg_sub(*,ind(0),ind(1))-xyz_eye
      dist_to_pin(npts-1)=sqrt(total(v_to_pt*v_to_pt))
;      pt_alpha(npts-1)=asin(v_to_pt(0)/(sqrt(total(v_to_pt(0:1)*v_to_pt(0:1)))))/!dtor
      pt_alpha(npts-1)=acos(total(-xyz_eye(0:1)*v_to_pt(0:1))/sqrt(total(v_to_pt(0:1)*v_to_pt(0:1)))/sqrt(total(xyz_eye(0:1)*xyz_eye(0:1))) < 1.)/!dtor
; this is the angle that the ray from center of pinhole to the test
; point makes with the vertical plane that contains the central rayis
; defined by phi=0
      pt_beta(npts-1)=asin(v_to_pt(2)/dist_to_pin(npts-1))/!dtor
; this is the angle that the ray from center of pinhole to the test
; point makes with the horizontal plane that contains the pinhole
      ;xyouts,.3,0.1+npts*0.03,/norm,'(R,Z,phi)!d'+sval(npts,l=1)+'!N=('+sval(rzphiseg_sub(0,ind(0),ind(1)),l=5)+','+sval(rzphiseg_sub(1,ind(0),ind(1)),l=6)+','+sval(rzphiseg_sub(2,ind(0),ind(1)),l=4)+')',col=npts+1,align=0.5
      ;xyouts,.7,0.1+npts*0.03,/norm,'(alpha,beta,length)!d'+sval(npts,l=1)+'!N=('+sval(pt_alpha(npts-1),l=5)+','+sval(pt_beta(npts-1),l=5)+','+sval(dist_to_pin(npts-1),l=4)+')',col=npts+1,align=0.5
      npts=npts+1
      goto,next
   endif
   done_with_pts:
   stop
;   press_return,/psprompt
endif

;
; Simplify to x and y vector segments
;
xseg=reform(image_2d(0,*,*))/scale
yseg=reform(image_2d(1,*,*))/scale
zseg=reform(image_2d(2,*,*))/scale
;if not ps then window,0,xsize=600,ysize=600,title='specified field-of-view'
;pos=[0.1,0.1,0.95,0.1+(!d.x_vsize/!d.y_vsize)*0.85]
;plot,[min(xseg),max(xseg)],[min(yseg),max(yseg)],col=1,/nodata,pos=pos
;for n=0,nseg_sub-1 do plots,xseg(0:lseg_sub(n)-1,n),yseg(0:lseg_sub(n)-1,n),noclip=0,col=colorseg_sub(n)
;for nn=0,njt-1 do plots,xseg(0:lseg_sub(jt2(nn))-1,jt2(nn)),yseg(0:lseg_sub(jt2(nn))-1,jt2(nn)),col=colorseg_sub(jt2(nn)),thi=2
; above plots the segments in planes at phis at the centers of ports
;xyouts,.15,.9,/norm,'R,Z of aperture='+sval(rpin,l=5)+','+sval(zpin,l=5)+' m',col=1,charsiz=1.
;xyouts,.15,.85,/norm,'alpha, beta angles for view center='+sval(alpha_act,l=6)+','+sval(beta_act,l=6)+' deg',col=1,charsiz=1.
;xyouts,.15,.8,/norm,'full angle of f-o-v='+sval(f_o_v_angle,l=3)+' deg',col=1,charsiz=1.
;for nn=0,njt-1 do xyouts,.15,.05+colorseg_sub(jt2(nn))*.05,/norm,port_names(colorseg_sub(jt2(nn))-1)+'-port',charsiz=1.,col=colorseg_sub(jt2(nn))
;stop
;press_return,/psprompt
if proj_onto_pixels and show_field_line then begin
; define the seg points at the corners of the X-pt camera image
   corn_ind=where(labelseg_sub eq 'X-pt view corner at 316.5',mm)
   ll=0
   tl_corn=[xseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll)),yseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll))]
   ll=1
   tr_corn=[xseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll)),yseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll))]
   ll=2
   br_corn=[xseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll)),yseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll))]
   ll=3
   bl_corn=[xseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll)),yseg(0:lseg_sub(corn_ind(ll))-2,corn_ind(ll))]
   if plot then begin
      plots,[tl_corn(0),tr_corn(0),bl_corn(0),br_corn(0)],[tl_corn(1),tr_corn(1),bl_corn(1),br_corn(1)],psym=1,thi=3,col=2
      plots,[image_2D(0,spot_index1,spot_index2)-0.06,image_2D(0,spot_index1,spot_index2)+0.06],[image_2D(1,spot_index1,spot_index2),image_2D(1,spot_index1,spot_index2)],col=1,thi=5
      plots,[image_2D(0,spot_index1,spot_index2),image_2D(0,spot_index1,spot_index2)],[image_2D(1,spot_index1,spot_index2)-0.06,image_2D(1,spot_index1,spot_index2)+0.06],col=1,thi=5
      endif
; now find fieldline segments that project into the camera image as
; defined by the corners at 316.5 deg
   fl_seg_ind=where(strmid(labelseg_sub,0,9) eq 'fieldline',mm)
   if mm gt 0 then begin
      xfl=fltarr(max(lseg_sub(fl_seg_ind)),mm)
      yfl=xfl
      xpixfl=xfl
      ypixfl=xfl
      fl_label=strarr(mm)
      n_fl_seg=intarr(mm)
      fl_count=0
      for mmm=0,mm-1 do begin
; WARNING !!!!!!!!
; in order to do the transformation from 2D-imgae
; coordinates to X- & Y-pixels (0 to 63)) the X- & Y axes of the 2D
; image MUST be parallel to those of the X, Y pixel space. In other
; words, edges of the image difined by bl_corn,br-corn,tl_corn, and
; tr_corn MUST BE HORIZONTAL and VERTICAL in the resonstructed image. 
; Use the 'Zrot' input to force this rotation.  
; After findng the appropriate Zrot, apply transformation from [xseg,yseg] space into pixel space - make
; the bl corner the (0,0) pixel and the tr corner the (63,63) pixel
;   xpix=nint((xseg_test-bl_corn(0))/(tr_corn(0)-bl_corn(0))*63.)
;   ypix=nint((yseg_test-bl_corn(1))/(tr_corn(1)-bl_corn(1))*63.)
         xtest=(xseg(0:lseg_sub(fl_seg_ind(mmm))-1,fl_seg_ind(mmm))-bl_corn(0))/(tr_corn(0)-bl_corn(0))*63.
         ytest=(yseg(0:lseg_sub(fl_seg_ind(mmm))-1,fl_seg_ind(mmm))-bl_corn(1))/(tr_corn(1)-bl_corn(1))*63.
         lll=where((abs(xtest-32.) lt 36.) and (abs(ytest-32.) lt 36.),n_lll)
;         if (labelseg_sub(fl_seg_ind(mmm)) eq'fieldline171') or (labelseg_sub(fl_seg_ind(mmm)) eq'fieldline172') or (labelseg_sub(fl_seg_ind(mmm)) eq'fieldline173') then stop
         if n_lll ge 4 then begin
            plots,xseg(lll,fl_seg_ind(mmm)),yseg(lll,fl_seg_ind(mmm)),col=3,thi=2
            n_fl_seg(fl_count)=n_lll
            xpixfl(0:n_fl_seg(fl_count)-1,fl_count)=xtest(lll)
            ypixfl(0:n_fl_seg(fl_count)-1,fl_count)=ytest(lll)
            fl_label(fl_count)=labelseg_sub(fl_seg_ind(mmm))
            xfl(0:n_fl_seg(fl_count)-1,fl_count)=xseg(lll,fl_seg_ind(mmm))
            yfl(0:n_fl_seg(fl_count)-1,fl_count)=yseg(lll,fl_seg_ind(mmm))
            fl_count=fl_count+1
         endif
      endfor
      ;stop
   endif 
;   stop
; now create structure and write structure to saveset
   if fl_count gt 0 then begin
;      rz_ind=intarr(fl_count)
      r_ind=intarr(fl_count)
      z_ind=intarr(fl_count)
      for mmmm=0,fl_count-1 do begin
         z_ind(mmmm)=(int(strtrim(strmid(fl_label(mmmm),9,5),2))-1)/n_fl_R
         r_ind(mmmm)=(int(strtrim(strmid(fl_label(mmmm),9,5),2))-1) MOD n_fl_R
;         rz_ind(mmmm)=int(strtrim(strmid(fl_label(mmmm),9,5),2))-1
         if mmmm eq 0 then begin
            _fl_map={fl_label:fl_label(0), fl_shot:fl_shot, fl_time:fl_time,$
            view_R:Rpin,view_Z:Zpin,view_phi:phipin, view_zrot:zrot,view_alpha:alpha,view_beta:beta,$
            view_corners_R:view_corners_R,view_corners_Z:view_corners_Z,phi_cal:phi_cal,$
            n_fl_r:n_fl_r,n_fl_z:n_fl_z,fl_R:fl_R(r_ind(0)), fl_Z:fl_Z(z_ind(0)), phipin:phipin,$
            n_fl_seg:n_fl_seg(0),xpixfl:xpixfl(*,0),ypixfl:ypixfl(*,0)}
            fl_map=replicate(_fl_map,fl_count)            
         endif else begin
            fl_map(mmmm).fl_label=fl_label(mmmm)
            fl_map(mmmm).fl_Z=fl_Z(z_ind(mmmm))
            if fl_shot ne 0 and fl_time ne 0. then fl_map(mmmm).fl_R=fl_R(r_ind(mmmm)) else begin
               if z_ind(mmmm) eq 0 then fl_map(mmmm).fl_R=fl_R_bot_row(r_ind(mmmm))
               if z_ind(mmmm) eq 1 then fl_map(mmmm).fl_R=fl_R_top_row(r_ind(mmmm))
            endelse
;            stop
            fl_map(mmmm).n_fl_seg=n_fl_seg(mmmm)
            fl_map(mmmm).xpixfl=xpixfl(*,mmmm)
            fl_map(mmmm).ypixfl=ypixfl(*,mmmm)
         endelse
      endfor
      fl_filename='fl_images/Xpt_fieldlines_'+strtrim(fl_shot,2)+'_'+strtrim(nint(fl_time*1000),2)+'ms.sav'
      ;print,'wrote the save set Xpt_view_fieldline_map_'+strtrim(fl_shot,2)+'_'+strtrim(nint(fl_time*1000),2)+'ms_test'+sval(test_num,l=2)+'.sav'
   endif
;stop
endif

plotit=0
n_images=n_elements(fl_map(*).fl_shot)
fl_image=intarr(64,64,n_images)
smooth_param=7
;stop
for i=0,n_images-1 do begin
   spline_p,(fl_map(i).xpixfl)[0:fl_map(i).n_fl_seg-1],(fl_map(i).ypixfl)[0:fl_map(i).n_fl_seg-1],xr,yr,interval=1.
   n_pts=n_elements(xr)
   for j=0,n_pts-1 do begin
      for k=0,63 do begin
         for l=0,63 do begin
;            a=abs(k-(fl_map(i).xpixfl)[j]) & b=abs(l-(fl_map(i).ypixfl)[j])
            a=abs(k-xr(j)) & b=abs(l-yr(j))
;            if (a le 2. and  b le 2.) then fl_image(k,l,i)=1000./(sqrt(a^2+b^2) > 1.)
            if sqrt(a^2+b^2) le 2 then fl_image(k,l,i)=(1000./(sqrt(a^2+b^2) > 1.) < 1000.)
         endfor
      endfor
   endfor
   fl_image(*,*,i)=smooth(fl_image(*,*,i),smooth_param,/edge_trunc)
   if plotit then begin
      loadct,45,/sil
      window,1,xsize=500,ysize=500
      plot,indgen(10),xra=[0,64],yra=[0,64],/nodata,col=1,xst=1,ysty=1
      plots,(fl_map(i).xpixfl)[0:fl_map(i).n_fl_seg-1],(fl_map(i).ypixfl)[0:fl_map(i).n_fl_seg-1],col=2
      plots,xr,yr,col=4
      loadct,3,/sil
      window,0,xsize=320,ysize=320
      tvscl,rebin(fl_image(*,*,i),5*64,5*64) & xyouts,4,300,/dev,sval(fl_map(i).fl_R*100.,l=5)+','+sval(fl_map(i).fl_Z*100,l=6),charsiz=1.5,col=255
   endif
endfor
if plotit then begin
   for i=0,n_images-1 do begin
      tvscl,rebin(fl_image(*,*,i),5*64,5*64) 
      xyouts,4,300,/dev,sval(fl_map(i).fl_R*100.,l=5)+','+sval(fl_map(i).fl_Z*100,l=6),charsiz=1.5,col=255 
      wait,0.1
   endfor
endif
shot=fl_map(0).fl_shot
time=fl_map(0).fl_time
fieldline_R=fl_map(*).fl_R
fieldline_Z=fl_map(*).fl_Z
fieldline_phi_start=fl_map(0).phipin
save,file=fl_filename,shot,time,smooth_param,fieldline_R,fieldline_Z,fieldline_phi_start,fl_image,fl_map
print,'wrote save set '+fl_filename

finish:
if ps then begin
;   ps,/close
    psc
endif
return
end