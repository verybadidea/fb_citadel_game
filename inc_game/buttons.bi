'~ type area_type
	'~ dim as integer x, y, w, h
	'~ declare function inside(x as integer, y as integer) as boolean
'~ end type

'~ function area_type.inside(tx as integer, ty as integer) as boolean
	'~ if tx <= x then return false
	'~ if ty <= y then return false
	'~ if tx >= (x + w) then return false
	'~ if ty >= (y + h) then return false
	'~ return true
'~ end function

'#include "../../_code_lib_new_/image_buffer_v03.bi"

type btn_type 'button
	dim as long x, y, w, h
	dim as long border = 0
	dim as ulong cBorder = &hff77ff
	dim as image_type ptr pImg
	declare function inside(x as long, y as long) as boolean
	declare sub drawm(idm as image_draw_mode = IDM_PSET, alphaval as long = -1)
	declare sub define(xImg as long, yImg as long, _
		iha as image_horz_align = IHA_LEFT, _
		iva as image_vert_align = IVA_TOP, _
		pImg as image_type ptr, _
		border as long, cBorder as ulong)
end type

function btn_type.inside(tx as long, ty as long) as boolean
	if tx <= x then return false
	if ty <= y then return false
	if tx >= (x + w) then return false
	if ty >= (y + h) then return false
	return true
end function

sub btn_type.drawm(idm as image_draw_mode = IDM_PSET, alphaval as long = -1)
	if border > 0 then
		if border = 1 then
			line(x, y)-step(w - 1, h - 1), cBorder, b
		else
			line(x, y)-step(w - 1, h - 1), cBorder, bf
		end if
	end if
	if pImg = 0 then exit sub
	if pImg->pFbImg = 0 then exit sub
	dim as long xImg = x + border
	dim as long yImg = y + border
	select case idm
		case IDM_PSET : put (xImg , yImg), pImg->pFbImg, pset
		case IDM_TRANS : put (xImg , yImg), pImg->pFbImg, trans
		case IDM_ALPHA
		if alphaval = -1 then
			 put (xImg, yImg), pImg->pFbImg, alpha
		else
			put (xImg, yImg), pImg->pFbImg, alpha, alphaval
		end if
	end select
end sub

'button size is define once, does not update after image change
sub btn_type.define(x as long, y as long, _
	iha as image_horz_align = IHA_LEFT, _
	iva as image_vert_align = IVA_TOP, _
	pImg as image_type ptr, _
	border as long, cBorder as ulong)
	'
	this.x = x : this.y = y
	this.border = border
	this.cBorder = cBorder
	this.pImg = pImg
	w = pImg->pFbImg->width + border * 2
	h = pImg->pFbImg->height + border * 2
	select case iha
		case IHA_CENTER : this.x -= w \ 2
		case IHA_RIGHT : this.x -= w
	end select
	select case iva
		case IVA_CENTER : this.y -= h \ 2
		case IVA_BOTTOM : this.y -= h
	end select
end sub
