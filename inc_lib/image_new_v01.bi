#include once "fbgfx.bi"
#include once "file.bi"
#include once "file_func_v02.bi"
#include once "bmp_v01.bi"
#include once "int2d_v02.bi"
#include once "colors_v01.bi"

'===============================================================================

enum image_horz_align
	IHA_LEFT
	IHA_CENTER
	IHA_RIGHT
end enum

enum image_vert_align
	IVA_TOP
	IVA_CENTER
	IVA_BOTTOM
end enum

enum image_draw_mode
	IDM_PSET
	IDM_TRANS
	IDM_ALPHA
end enum

dim shared as long image_horz_align_default = IHA_LEFT
dim shared as long image_vert_align_default = IVA_TOP
dim shared as long image_draw_mode_default = IDM_PSET

type trim_type
	dim as long l, r, t, b 'left, right, top, bottom
end type

type image_type
	dim as FB.IMAGE ptr pFbImg
	dim as long hAlign, vAlign, drawMode
	declare sub create(w as long, h as long, colorInit as ulong)
	declare function createFromBmp(fileName as string) as long
	declare function copyTo(byref newImg as image_type) as long
	declare function copy() as image_type ptr
	declare function hFlipTo(byref newImg as image_type) as long
	declare function hFlip() as image_type ptr
	declare function rotateRightTo(byref newImg as image_type) as long
	declare function rotateRight() as image_type ptr
	declare function shrinkTo(byref newImg as image_type) as long
	declare function shrink() as image_type ptr
	declare function btrimTo(byref newImg as image_type, border as trim_type) as long
	declare function btrim(border as trim_type) as image_type ptr
	declare sub setProp(hAlign as long, hAlign as long, drawMode as long)
	declare sub drawxy(x as long, y as long)
	declare sub drawxym(x as long, y as long, _
		iha as image_horz_align = IHA_LEFT, iva as image_vert_align = IVA_TOP, _
		idm as image_draw_mode = IDM_PSET, alphaval as long = -1)
	declare sub destroy()
	declare destructor()
end type

sub image_type.create(w as long, h as long, colorInit as ulong)
	pFbImg = imagecreate(w, h, colorInit)
	setProp(image_horz_align_default, image_vert_align_default, image_draw_mode_default)
end sub

function image_type.createFromBmp(fileName as string) as long
	dim as bitmap_header bmp_header
	dim as int2d bmpSize
	if fileExists(filename) then
		if ucase(getFileExt(filename)) = "BMP" then
			open fileName for binary as #1
				get #1, , bmp_header
			close #1
			bmpSize.x = bmp_header.biWidth
			bmpSize.y = bmp_header.biHeight
			create(bmpSize.x, bmpSize.y, &hff000000)
			bload fileName, pFbImg
			'print "Bitmap loaded: " & filename
			return 0
		else
		'print "Wrong file type: " & filename
		end if
		return -2
	end if
	'print "File not found: " & filename
	return -1
end function

'deep copy, call srcImg.copyTo(newImg), also set draw properties
function image_type.copyTo(byref newImg as image_type) as long
	if newImg.pFbImg <> 0 then return -1
	newImg.create(pFbImg->width, pFbImg->height, &hff000000)
	put newImg.pFbImg, (0, 0), pFbImg, pset
	return 0
end function

function image_type.copy() as image_type ptr
	dim as image_type ptr newImg = new image_type
	this.copyTo(*newImg) 'dereference, byref passing
	return newImg
end function

function image_type.hFlipTo(byref newImg as image_type) as long
	dim as long w, h, bypp, pitch
	dim as ulong ptr pPixSrc, pPixDst
	'get source image info and check things
	if imageinfo(this.pFbImg, w, h, bypp, pitch, pPixSrc) <> 0 then return -1
	if bypp <> 4 then return -2 'only 32-bit images
	if pPixSrc = 0 then return -3
	'create dest image, get info and check things
	if newImg.pFbImg <> 0 then return -4
	newImg.create(w, h, &hff000000)
	if newImg.pFbImg = 0 then return -5
	if imageinfo(newImg.pFbImg, w, h, bypp, pitch, pPixDst) <> 0 then return -6
	if pPixDst = 0 then return -7
	'do the flip source to destination
	dim as long xiDst
	pitch shr= 2 'stepping 4 bytes at a time
	for yi as long = 0 to h - 1
		xiDst = w
		for xi as long = 0 to w - 1
			xiDst -= 1
			pPixDst[xiDst] = pPixSrc[xi]
		next
		pPixSrc += pitch
		pPixDst += pitch
	next
	return 0
end function

function image_type.hFlip() as image_type ptr
	dim as image_type ptr newImg = new image_type
	this.hFlipTo(*newImg) 'dereference, byref passing
	return newImg
end function

function image_type.rotateRightTo(byref newImg as image_type) as long
	dim as long wSrc, hSrc, pitchSrc
	dim as long wDst, hDst, pitchDst
	dim as ulong ptr pPixSrc, pPixDst
	'get source image info and check things
	if imageinfo(this.pFbImg, wSrc, hSrc,, pitchSrc, pPixSrc) <> 0 then return -1
	if pPixSrc = 0 then return -3
	pitchSrc shr= 2 'stepping 4 bytes at a time
	'create dest image, get info and check things
	if newImg.pFbImg <> 0 then return -4
	newImg.create(hSrc, wSrc, &hff000000) 'note W & H swapped !!!
	if newImg.pFbImg = 0 then return -5
	if imageinfo(newImg.pFbImg, wDst, hDst,, pitchDst, pPixDst) <> 0 then return -6
	if pPixDst = 0 then return -7
	pitchDst shr= 2 'stepping 4 bytes at a time
	'go through source pixels in normal sequence
	for y as long = 0 to hSrc - 1
		for x as long = 0 to wSrc - 1
			pPixDst[((wDst - 1) - y) + x * pitchDst] = pPixSrc[x]
		next
		pPixSrc += pitchSrc
	next
	return 0
end function

function image_type.rotateRight() as image_type ptr
	dim as image_type ptr newImg = new image_type
	this.rotateRightTo(*newImg) 'dereference, byref passing
	return newImg
end function

'create image half the size
function image_type.shrinkTo(byref newImg as image_type) as long
	dim as long wSrc, hSrc, pitchSrc
	dim as long wDst, hDst, pitchDst
	dim as ulong ptr pPixSrc, pPixDst
	dim as long rSum, gSum, bSum, aSum 'red, green, blue, alpha
	'get source image info and check things
	if imageinfo(this.pFbImg, wSrc, hSrc,, pitchSrc, pPixSrc) <> 0 then return -1
	if (wSrc and 1) or (hSrc and 1) then return -2 'dimensions must be even
	if pPixSrc = 0 then return -3
	pitchSrc shr= 2 'stepping 4 bytes at a time
	'create dest image, get info and check things
	if newImg.pFbImg <> 0 then return -4
	newImg.create(wSrc \ 2, hSrc \ 2, &hff000000)
	if newImg.pFbImg = 0 then return -5
	if imageinfo(newImg.pFbImg, wDst, hDst,, pitchDst, pPixDst) <> 0 then return -6
	if pPixDst = 0 then return -7
	pitchDst shr= 2 'stepping 4 bytes at a time
	'go through destination pixels in normal sequence
	for y as long = 0 to hDst - 1
		for x as long = 0 to wDst - 1
			rSum = 0 : gSum = 0 : bSum = 0 : aSum = 0
			var pSrcRgba = cast(rgba_union ptr, pPixSrc + (x shl 1))
			rSum += pSrcRgba->r : gSum += pSrcRgba->g : bSum += pSrcRgba->b
			aSum += pSrcRgba->a
			pSrcRgba += 1 '1 pixel right
			rSum += pSrcRgba->r : gSum += pSrcRgba->g : bSum += pSrcRgba->b
			aSum += pSrcRgba->a
			pSrcRgba += pitchSrc '1 pixel down
			rSum += pSrcRgba->r : gSum += pSrcRgba->g : bSum += pSrcRgba->b
			aSum += pSrcRgba->a
			pSrcRgba -= 1 '1 pixel left
			rSum += pSrcRgba->r : gSum += pSrcRgba->g : bSum += pSrcRgba->b
			aSum += pSrcRgba->a
			pPixDst[x] = rgba(rSum shr 2, gSum shr 2, bSum shr 2, aSum shr 2)
		next
		pPixDst += pitchDst
		pPixSrc += (pitchSrc shl 1) 'skip a line
	next
	return 0
end function

function image_type.shrink() as image_type ptr
	dim as image_type ptr newImg = new image_type
	this.shrinkTo(*newImg) 'dereference, byref passing
	return newImg
end function

function image_type.btrimTo(byref newImg as image_type, border as trim_type) as long
	if newImg.pFbImg <> 0 then return -1
	dim as long wDst = pFbImg->width - (border.l + border.r)
	dim as long hDst = pFbImg->height - (border.t + border.b)
	newImg.create(wDst, hDst, &hff000000)
	put newImg.pFbImg, (0, 0), pFbImg,(border.l, border.t)-step(wDst - 1, hDst - 1), pset
	return 0
end function

function image_type.btrim(border as trim_type) as image_type ptr
	dim as image_type ptr newImg = new image_type
	this.btrimTo(*newImg, border) 'dereference, byref passing
	return newImg
end function

sub image_type.setProp(hAlign as long, vAlign as long, drawMode as long)
	this.hAlign = hAlign
	this.vAlign = vAlign
	this.drawMode = drawMode
end sub

sub image_type.drawxy(x as long, y as long)
	if pFbImg = 0 then exit sub
	select case hAlign
		case IHA_CENTER : x -= pFbImg->width \ 2
		case IHA_RIGHT : x -= pFbImg->width
	end select
	select case vAlign
		case IVA_CENTER : y -= pFbImg->height \ 2
		case IVA_BOTTOM : y -= pFbImg->height
	end select
	select case drawMode
		case IDM_PSET : put (x, y), pFbImg, pset
		case IDM_TRANS : put (x, y), pFbImg, trans
		case IDM_ALPHA : put (x, y), pFbImg, alpha ', alphaval
	end select
end sub

sub image_type.drawxym(x as long, y as long, _
	iha as image_horz_align = IHA_LEFT, iva as image_vert_align = IVA_TOP, _
	idm as image_draw_mode = IDM_PSET, alphaval as long = -1)
	'
	if pFbImg = 0 then exit sub
	select case iha
		case IHA_CENTER : x -= pFbImg->width \ 2
		case IHA_RIGHT : x -= pFbImg->width
	end select
	select case iva
		case IVA_CENTER : y -= pFbImg->height \ 2
		case IVA_BOTTOM : y -= pFbImg->height
	end select
	select case idm
		case IDM_PSET : put (x, y), pFbImg, pset
		case IDM_TRANS : put (x, y), pFbImg, trans
		case IDM_ALPHA
		if alphaval = -1 then
			 put (x, y), pFbImg, alpha
		else
			put (x, y), pFbImg, alpha, alphaval
		end if
	end select
end sub

sub image_type.destroy()
	if (pFbImg <> 0) then
		imagedestroy(pFbImg)
		pFbImg = 0
	end if
end sub

destructor image_type()
	destroy()
end destructor

'===============================================================================




'~ function loadImages(pImg as image_type ptr, fileNameTemplate as string, numImg as long) as long
	'~ dim as long i, result
	'~ dim as string fileName
	'~ for i = 0 to numImg-1
		'~ fileName = findAndReplace(fileNameTemplate, str(i + 1))
		'~ result = pImg[i].createFromBmp(fileName)
		'~ logToFile(fileName & " - " & iif(result = 0, "OK", "FAIL"))
		'~ if result <> 0 then return -1
	'~ next
	'~ return 0
'~ end function

'~ function flipImages(pImgSrc as image_type ptr, pImgDst as image_type ptr, numImg as long) as long
	'~ for i as long = 0 to numImg-1
		'~ if pImgSrc[i].hFlipTo(pImgDst[i]) <> 0 then return -1
	'~ next
	'~ return 0
'~ end function

'===============================================================================

'~ type area_type
	'~ dim as long x1, y1
	'~ dim as long x2, y2
'~ end type

'~ function imageGrayInt(pFbImg as any ptr, area as area_type, intOffs as long) as long
	'~ dim as long w, h, bypp, pitch
	'~ dim as long xi, yi, intensity
	'~ dim as any ptr pPixels
	'~ dim as rgba_union ptr pRow
	'~ if imageinfo(pFbImg, w, h, bypp, pitch, pPixels) <> 0 then return -1
	'~ if bypp <> 4 then return -2 'only 32-bit images
	'~ if pPixels = 0 then return -3
	'~ if area.x1 < 0 or area.x1 >= w then return -4
	'~ if area.y1 < 0 or area.y1 >= h then return -5
	'~ if area.x2 < 0 or area.x2 >= w then return -6
	'~ if area.y2 < 0 or area.y2 >= h then return -7
	'~ for yi = area.y1 to area.y2
		'~ pRow = pPixels + yi * pitch
		'~ for xi = area.x1 to area.x2
			'~ intensity = cint(0.3 * pRow[xi].r + 0.5 * pRow[xi].g + 0.2 * pRow[xi].b) + intOffs
			'~ if intensity < 0 then intensity = 0
			'~ if intensity > 255 then intensity = 255
			'~ pRow[xi].r = intensity
			'~ pRow[xi].g = intensity
			'~ pRow[xi].b = intensity
		'~ next
	'~ next
	'~ return 0
'~ end function

'~ sub dimScreen(dimFactor as single)
	'~ dim as long w, h, pitch, xi, yi
	'~ dim as rgba_union ptr pRow
	'~ ScreenInfo w, h, , , pitch
	'~ dim as any ptr pPixels = ScreenPtr()
	'~ if pPixels = 0 then exit sub
	'~ for yi = 0 to h-1
		'~ pRow = pPixels + yi * pitch
		'~ for xi = 0 to w-1
			'~ pRow[xi].r *= dimFactor
			'~ pRow[xi].g *= dimFactor
			'~ pRow[xi].b *= dimFactor
			'~ 'pRow[xi].r shr= 1
			'~ 'pRow[xi].g shr= 1
			'~ 'pRow[xi].b shr= 1
			'~ 'if pRow[xi].r > 0 then pRow[xi].r -= 1
			'~ 'if pRow[xi].g > 0 then pRow[xi].g -= 1
			'~ 'if pRow[xi].b > 0 then pRow[xi].b -= 1
		'~ next
	'~ next
'~ end sub

'~ sub clearScreen()
	'~ dim as long w, h, pitch, xi, yi
	'~ ScreenInfo w, h, , , pitch
	'~ line(0, 0) - (w-1, h-1), C_BLACK, bf
'~ end sub
