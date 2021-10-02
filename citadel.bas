'DONE:
'draw stash, with number of cards indication
'pick card from stash, rotate with wheel
'place card on grid
'set rotation on map
'read tile properties from filename
'make lookup table tileId <-> properties
'show invalid neighbours indication
'check valid position (neighbours)
'separate check valid pos & drawing
'do not allow placement when ...
'use bitfield or union for match neighours
'remove scroll buttons, move map by mouse drag
'zoom with mouse
'show semi transparent selected/dragged tile on map
'watermark images

'TODO:
'set map tile properties on placement
'add more tiles
'tile occurance / propability
'make add to rnd_tile function, using propability
'change stash to contain tile_type (with property)
'total score:
' road: xxxx + xx
' city: xxxx + xx
' river: xxxx + xx
'multiple stashes
'change map offset on zoom in/out, center on mouse pos
'move grid-view with mouse & keys
'zoom in/out with =/- key and ui-buttons + q - (q = magnifier)
'right mouse button / escape: dragging tile back to stach movement
'score display
'check for water/road/city completion
'switch to tile_map2.bi (list of rows)
'problem tile: 2 disconnected roads
'how to detect city completion? Use Wall vs City property? No, not needed! 'Use H (H20) for water?
'A city side, must always be connected to another tile (with a city side).
'make stash empty image

'LATERs:
'rotate card with space also
'font library
'multiple stash
'sound & music

#include "fbgfx.bi"
#include "inc_lib/general.bi"
#include "inc_lib/image_buffer_v03.bi"
#include "inc_lib/mouse_v02.bi"
#include "inc_game/buttons.bi"
#include "inc_game/stash.bi"
#include "inc_game/grid_coord.bi"
#include "inc_game/tile_map1.bi"
#include "inc_game/tile_prop.bi"

const SW = 960, SH = 730
screenres SW, SH, 32
width SW \ 8, SH \ 16 'larger font

'--- load tiles ----------------------------------------------------------------

dim as image_buffer_type imgBufTiles
if imgBufTiles.loadDir("tiles") <= 0 then panic("load tiles")

const as long TILE_L = 0 'large
const as long TILE_M = 1 'medium
const as long TILE_S = 2 'small

dim as integer numTiles = imgBufTiles.numImages
dim as image_type ptr pTilesImg(0 to numTiles - 1, 0 to 3, 0 to 2) 'id, rotation, zoom out 
'copy buffer & crop to array's first image
dim as trim_type border = type(6, 6, 6, 6)
for iImg as integer = 0 to numTiles - 1
	pTilesImg(iImg, 0, 0) = imgBufTiles.image(iImg).btrim(border)
next
'create rotated versions of each image
for iImg as integer = 0 to numTiles - 1
	for iRot as integer = 1 to 3
		pTilesImg(iImg, iRot, 0) = pTilesImg(iImg, iRot - 1, 0)->rotateRight
	next
next
'create small & tiny versions, for each image & rotation
for iImg as integer = 0 to numTiles - 1
	for iRot as integer = 0 to 3
		pTilesImg(iImg, iRot, 1) = pTilesImg(iImg, iRot, 0)->shrink
		pTilesImg(iImg, iRot, 2) = pTilesImg(iImg, iRot, 1)->shrink
	next
next

'--- tile properties -----------------------------------------------------------

dim as tile_prop tileProp(0 to numTiles - 1)
for i as long = 0 to ubound(tileProp)
	dim as string shortName = getFileName(imgBufTiles.imageFileName(i))
	tileProp(i).fromFileName(shortName)
next

'--- define grid ---------------------------------------------------------------

dim as long tileSizeIdx = TILE_M
dim as long wGrid_ = pTilesImg(0, 0, tileSizeIdx)->pFbImg->width
dim as long hGrid_ = pTilesImg(0, 0, tileSizeIdx)->pFbImg->height
dim as grid_coord grid = type(wGrid_, hGrid_) 'grid larger than images

'--- stash area ----------------------------------------------------------------

dim as btn_type stashBtn
stashBtn.define(SW - 10, SH - 10, IHA_RIGHT, IVA_BOTTOM, pTilesImg(0, 0, TILE_S), 4, &hff00ff)

'--- scroll buttons ------------------------------------------------------------

dim as image_buffer_type imgBufImages
if imgBufImages.loadDir("images") <= 0 then panic("load images")

const IMG_QUESTION = 0
const IMG_CHECK = 1
const IMG_CROSS = 2
const IMG_STAR = 3
const IMG_STAR_GLOW = 4
const IMG_SPARKLE = 5

dim as image_type ptr pImgQu, pImgOk, pImgNok 'check & cross
pImgQu = imgBufImages.image(IMG_QUESTION).shrink
pImgOk = imgBufImages.image(IMG_CHECK).shrink
pImgNok = imgBufImages.image(IMG_CROSS).shrink

'-------------------------------------------------------------------------------

union match_type
	all as ulong
	type
		side(0 to 3) as ubyte
	end type
end union

'-------------------------------------------------------------------------------

'triangular number sesies: 1,3,6,10,15,21,...
function triangular(n as integer) as integer
	return (n * (n + 1)) shr 1
end function

'~ function score(rawCount as integer)
	'~ return rawCount + triangular(rawCount \ 10) as integer
'~ end function

'check on new tile placement:
'loop each 4 side:
' if road & not visited:
'  set visited
'  check connected road sections (including this tile)
'  mark visited
'  count ++
'  display * at each road section (* = 1 point) for 1 second
'  get new tiles = f(score)
'when done, removed visited flags. how?
'visited is path of map or separate list?

'make part of tile_map class?
'return gained score
'~ function tileScore(map as tile_map, tilePos as int2d) as integer
	'~ for i as long = 0 to 
'~ end function

'--- main ----------------------------------------------------------------------

dim as tile_map map
map.setTile(0, 0, type<tile_type>(1, 0)) 'set first tile 1 at 0,0

dim as int2d scrnPosOnMap
scrnPosOnMap = type((grid.w - SW) \ 2, (grid.h - SH) \ 2) 'center on tile 0,0

const as double scrollSpeed = 1000 / 4 '250 pixels / second

randomize timer
dim as stash_type stash
dim as long stashSize = 50
for i as integer = 0 to stashSize - 1
	stash.push(int(rnd() * (numTiles - 1)) + 1)
next

dim as match_type match
'neighbour positions (up, ri, dn, le)
dim as int2d nbDeltaPos(0 to 3) = {int2d(0, -1), int2d(+1, 0), int2d(0, +1), int2d(-1, 0)}
dim as tile_type nbTile(0 to 3)

dim as mousetype mouse
dim as integer mouseEvent
dim as integer mx, my
dim as long mouseDrag = 0
dim as tile_type sTile = type(-1, 0) 'id, rot (selected tile)
dim as double tLast = timer, dt = 0

while not multikey(FB.SC_Q)
	mouseEvent = handleMouse(mouse)
	mx = mouse.pos.x
	my = mouse.pos.y
	dim as integer scrollDist = int(dt * scrollSpeed) + 1
	dim as int2d mouseGridPos = grid.getGridPos(scrnPosOnMap + mouse.pos)
	dim as tile_type mTile = map.getTile(mouseGridPos) 'tile at mouse pos in grid
	dim as long neigbours = 0
	dim as long allowPlacement = 0
	dim as long showPreview = 0

	if mouse.status = 0 and sTile.id >= 0 then 'selected tile selected from stash
		if mTile.id <= 0 then 'no tile already at mouse grid pos
			allowPlacement = 1 'maybe ok, check neighbours also...
			showPreview = 1
			match.all = 0
			for i as long = 0 to 3
				nbTile(i) = map.getTile(mouseGridPos + nbDeltaPos(i))
				if nbTile(i).id > 0 then 'a valid neighbour tile
					neigbours += 1
					dim as long nbSide = (i + 2) mod 4
					dim as long selTileProp = tileProp(sTile.id).getProp(i, sTile.rot)
					dim as long nbTileProp = tileProp(nbTile(i).id).getProp(nbSide, nbTile(i).rot)
					if selTileProp = nbTileProp then
						match.side(i) = 1
					else
						allowPlacement = 0
					end if
				end if
			next
			if neigbours = 0 then allowPlacement = 0 : showPreview = 0
		end if
	end if
	
	select case mouseEvent
	case MOUSE_WHEEL_UP
		if sTile.id > 0 then
			sTile.rot -= 1 : if sTile.rot < 0 then sTile.rot = 3
		else
			if tileSizeIdx > TILE_L then
				tileSizeIdx -= 1
				grid.w shl= 1
				grid.h shl= 1
			end if
		end if
	case MOUSE_WHEEL_DOWN
		if sTile.id > 0 then
			sTile.rot += 1 : if sTile.rot >= 4 then sTile.rot = 0
		else
			if tileSizeIdx < TILE_S then
				tileSizeIdx += 1
				grid.w shr= 1
				grid.h shr= 1
			end if
		end if
	case MOUSE_RB_PRESSED
		mouseDrag = 1
	case MOUSE_RB_RELEASED
		mouseDrag = 0
	case MOUSE_LB_PRESSED
		'if stashArea.inside(mx, my) then
		if stashBtn.inside(mx, my) then
			if sTile.id >= 0 then
				'out back on stash
				stash.push(sTile.id)
				sTile.id = -1
			else
				'get from stash
				sTile.id = stash.pop()
				sTile.rot = 0
			end if
		else
			'place on grid/map
			if sTile.id >= 0 then
				'if map.getTile(mouseGridPos).id <= 0 then
				if allowPlacement = 1 then
					map.setTile(mouseGridPos, sTile)
					sTile.id = -1
				end if
			end if
		end if
	end select

	if mouseDrag = 1 then
		scrnPosOnMap -= mouse.posChange
	end if

	screenlock
	line(0, 0)-(SW - 1, SH - 1), &h000000, bf 'clear
	'draw grid
	dim as int2d gridPosTL = grid.getGridPos(scrnPosOnMap) 'top/left
	dim as int2d gridPosBR = grid.getGridPos(scrnPosOnMap + type(SW - 1, SH - 1)) 'bottom/right
	for y as integer = gridPosTL.y to gridPosBR.y
		for x as integer = gridPosTL.x to gridPosBR.x
			dim as int2d scrnPos = grid.getScrPos(type(x, y), scrnPosOnMap)
			line(scrnPos.x, scrnPos.y)-step(grid.w - 1, grid.h - 1), &h777777, b
			dim as tile_type tile = map.getTile(x, y)
			if tile.Id >= 0 then
				pTilesImg(tile.id, tile.rot, tileSizeIdx)->drawxym(scrnPos.x, scrnPos.y, IHA_LEFT, IVA_TOP)
				'draw string (scrnPos.x + 10, scrnPos.y + 10), str(tileProp(tile.id).occurance), 
			end if
		next
	next
	'draw stash
	stashBtn.pImg = iif(stash.size() <= 0, 0, pTilesImg(stash.top(), 0, TILE_S))
	stashBtn.drawm()
	draw string (stashBtn.x + 2 + 4, stashBtn.y + 4), str(stash.size()), &hffffff
	'highligt mouse position on grid
	dim as int2d scrnPos = grid.getScrPos(mouseGridPos, scrnPosOnMap)
	'draw selected image at mouse position if valid
	if mouse.status = 0 and sTile.id >= 0 then
		'draw selected tile at mouse position
		pTilesImg(sTile.id, sTile.rot, tileSizeIdx)->drawxym(mx, my, IHA_CENTER, IVA_CENTER, IDM_ALPHA, 192)
		'show tile on grid if place ok, but without matching neighbour check
		if showPreview = 1 then
			pTilesImg(sTile.id, sTile.rot, tileSizeIdx)->drawxym(scrnPos.x, scrnPos.y, IHA_LEFT, IVA_TOP, IDM_ALPHA, 127)
		end if
		'show neighbour matching indicators
		if mTile.id <= 0 then 'no tile already at mouse grid pos
			for i as long = 0 to 3
				if nbTile(i).id > 0 then 'a valid neighbour
					dim as image_type ptr pImgImg = iif(match.side(i) = 1, pImgOk, pImgNok)
					dim as long x = scrnPos.x + (grid.w + nbDeltaPos(i).x * grid.w) \ 2
					dim as long y = scrnPos.y + (grid.h + nbDeltaPos(i).y * grid.h) \ 2
					pImgImg->drawxym(x, y, IHA_CENTER, IVA_CENTER, IDM_ALPHA)
				end if
			next
		end if
	end if
	
	draw string (10, 10), "<Q> to quit, Time: " & time, &hffff00
	draw string (10, 40), "Use mouse to:", &hffff00
	draw string (10, 55), "* pick a tile from stash, (left button)", &hffff00
	draw string (10, 70), "* rotate tile (if picked up) with wheel", &hffff00
	draw string (10, 85), "* place on board if allowed (left button)", &hffff00
	draw string (10, 100), "* zoom in/out, with no tile, with wheel", &hffff00
	draw string (10, 115), "* drag view with right button", &hffff00
	'draw string (80, 30), str(scrollDist), &hffff00
	'locate 2,1 : print scrnPosOnMap.x, scrnPosOnMap.y
	'locate 3,1 : print mouseGridPos.x, mouseGridPos.y
	screenunlock

	sleep 1, 1
	dim as double tNow = timer
	dt = tNow - tLast
	tLast = tNow
wend


getkey()
end

'ramdom code dump:

'dim as image_type ptr pTrimImg = imgBuf.image(4).btrim(border)
'~ for i as integer = 0 to imgBuf.numImages-1
	'~ imgBuf.image(i).drawxy(i*100+10, i*100+10)
	'~ draw string(i*100+15, i*100+15), getFileName(imgBuf.imageFileName(i)), &hFFFFFF
'~ next
'imgBuf.image(0).drawxy(10, 10)
'pNewImg(0)->drawxy(200, 200)
'~ dim as image_type ptr pNewImg(0 to 3)
'~ pNewImg(0) = pTrimImg->copy()
'~ for i as integer = 1 to 3
	'~ pNewImg(i) = pNewImg(i-1)->rotateRight
'~ next
'pTrimImg->drawxy(420, 200)
'~ print imgBuf.image(0).pFbImg->width
'~ print pTrimImg->pFbImg->width
'~ for i as integer = 0 to 3
	'~ pNewImg(i)->drawxy(40 + 200 * (i mod 2), 10 + 200 * (i \ 2))
'~ next
'~ dim as image_type ptr pSmallImg(0 to 3)
'~ for i as integer = 0 to 3
	'~ pSmallImg(i) = pNewImg(i)->shrink
	'~ pSmallImg(i)->drawxy(510 + 100 * (i mod 2), 10 + 100 * (i \ 2))
'~ next
'~ print pSmallImg(0)->pFbImg->width

'~ dim as image_type ptr pTinyImg(0 to 3)
'~ for i as integer = 0 to 3
	'~ pTinyImg(i) = pSmallImg(i)->shrink
	'~ pTinyImg(i)->drawxy(510 + 50 * (i mod 2), 210 + 50 * (i \ 2))
'~ next
'~ print pTinyImg(0)->pFbImg->width

'dim as image_type rotatedImage = imgBuf.image(0).rotateRight()
'print imgBuf.image(0).rotateRightTo(rotatedImage)
'rotatedImage.drawxy(120, 120)
'dim as image_type rotatedImage2
'print rotatedImage.rotateRightTo(rotatedImage2)
'rotatedImage2.drawxy(230, 230)

'show all images of size medium
'~ for iImg as integer = 0 to numImg - 1
	'~ for iRot as integer = 0 to 3
		'~ pTilesImg(iImg, iRot, 1)->drawxy(iImg * 100 + 10, iRot * 100 + 10)
	'~ next
'~ next

'~ for i as integer = 0 to imgBufButtons.numImages - 1
	'~ print imgBufButtons.imageFileName(i)
'~ next

'~ mogrify -verbose -resize 40x40 -format bmp *.png

'pImgNok->drawxym(scrnPos.x + wGrid \ 2, scrnPos.y, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'top
'pImgOk->drawxym(scrnPos.x, scrnPos.y + hGrid \ 2, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'left
'pImgNok->drawxym(scrnPos.x + wGrid \ 2, scrnPos.y + hGrid, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'bottom
'pImgOk->drawxym(scrnPos.x + wGrid, scrnPos.y + hGrid \ 2, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'right

'dim as int2d lvmp 'lastValidMousePos
'~ if mouse.status = 0 then
	'~ lvmp = mouse.pos
	'~ dim as integer scrollBorder = 40
	'~ if lvmp.x < scrollBorder then scrnPosOnMap.x -= 1 'change to roundup(scrollSpeed * dt)
	'~ if lvmp.x > SW - scrollBorder then scrnPosOnMap.x += 1
	'~ if lvmp.y < scrollBorder then scrnPosOnMap.y -= 1
	'~ if lvmp.y > SH - scrollBorder then scrnPosOnMap.y += 1
'~ end if

'~ 'check current grid position
'~ dim as tile_type tile = map.getTile(mouseGridPos)
'~ if tile.id <= 0 then 'no tile place here yet
	'~ dim as tile_type tileUp = map.getTile(mouseGridPos.x, mouseGridPos.y - 1)
	'~ dim as tile_type tileDn = map.getTile(mouseGridPos.x, mouseGridPos.y + 1)
	'~ dim as tile_type tileLe = map.getTile(mouseGridPos.x - 1, mouseGridPos.y)
	'~ dim as tile_type tileRi = map.getTile(mouseGridPos.x + 1, mouseGridPos.y)
	'~ 'check if any tile adjacent
	'~ if (tileUp.id <= 0) and (tileDn.id <= 0) and (tileLe.id <= 0) and (tileRi.id <= 0) then
		'~ 'no neighbours
	'~ else
		'~ 'preview tile
		'~ pTilesImg(sTile.id, sTile.rot, TILE_S)->drawxym(scrnPos.x, scrnPos.y, IHA_LEFT, IVA_TOP, IDM_ALPHA, 127)
		'~ dim as image_type ptr pImgImg
		'~ 'check top
		'~ if tileUp.id > 0 then 
			'~ if tileProp(sTile.id).getProp(PROP_UP, sTile.rot) = tileProp(tileUp.id).getProp(PROP_DN, tileUp.rot) then
				'~ pImgImg = pImgOk
			'~ else
				'~ pImgImg = pImgNok
			'~ end if
			'~ pImgImg->drawxym(scrnPos.x + wGrid \ 2, scrnPos.y, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'top
		'~ end if
		'~ 'check left
		'~ if tileLe.id > 0 then 
			'~ if tileProp(sTile.id).getProp(PROP_LE, sTile.rot) = tileProp(tileLe.id).getProp(PROP_RI, tileLe.rot) then
				'~ pImgImg = pImgOk
			'~ else
				'~ pImgImg = pImgNok
			'~ end if
			'~ pImgImg->drawxym(scrnPos.x, scrnPos.y + hGrid \ 2, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'left
		'~ end if
		'~ 'check bottom
		'~ if tileDn.id > 0 then 
			'~ if tileProp(sTile.id).getProp(PROP_DN, sTile.rot) = tileProp(tileDn.id).getProp(PROP_UP, tileDn.rot) then
				'~ pImgImg = pImgOk
			'~ else
				'~ pImgImg = pImgNok
			'~ end if
			'~ pImgImg->drawxym(scrnPos.x + wGrid \ 2, scrnPos.y + hGrid, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'bottom
		'~ end if
		'~ 'check right
		'~ if tileRi.id > 0 then 
			'~ if tileProp(sTile.id).getProp(PROP_RI, sTile.rot) = tileProp(tileRi.id).getProp(PROP_LE, tileRi.rot) then
				'~ pImgImg = pImgOk
			'~ else
				'~ pImgImg = pImgNok
			'~ end if
			'~ pImgImg->drawxym(scrnPos.x + wGrid, scrnPos.y + hGrid \ 2, IHA_CENTER, IVA_CENTER, IDM_ALPHA) 'right
		'~ end if
	'~ end if
'~ end if

'line(scrnPos.x, scrnPos.y)-step(grid.w - 1, grid.h - 1), &h00ffff, b
