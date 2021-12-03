'DONE:
'draw stack, with number of cards indication
'pick card from stack, rotate with wheel
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
'tile occurance / propability
'restructure tile_type, tile_prop, tile_collection class
'add re-sizeble and re-usable array for visited tiles
'set map tile properties on placement -> Change neighbour check
'make add to rnd_tile function, using propability
'no score for imcomplete road/city/water
'detect city/road/water completion
'score display
'change x,y / row,col in tile_map 
'points for tiles placed with neighours > 2 + 1 for abbey (1,3,6,10,15)
'linked list for stack. Add to bottom added.
'zoom in/out, also via keys -> function zoom(+/-)
'multiple stackes
'abbey check
'limit other stack to 1
'change numStack to bitfield, make cross abby an exact match (no abbeys at diagonals)
'add more tiles: water
'more simple point system, 1 point per tile
'end roads at crossing
'Points: -1 for roads & -2 for cities, +1 for blazon

'TODO:
'Undo option (single)?
'Add destruction tile
'add full grass tile?
'add registered key class + vairable key configuration
'scroll map with keys
'rotate card with space also
'get tiles for score, display nicely: tile-, city-, road-, waterpoints + bonus
'animate points, large & center, fade to topleft, nome new tiles to stack
'animate scoring points with stars
'allow map view at game over
'animate getting tiles for points scored
'map draw_map/grid function
'change map offset on zoom in/out, center on mouse pos
'move grid-view with mouse & keys
'right mouse button / escape: dragging tile back to stach movement
'check for water/road/city completion
'switch to tile_map2.bi (list of rows)
'problem tile: 2 disconnected roads
'make stack empty image
'options menu with screen resolution & full screen option
'load and save game
'sounds
'high score list
'difficulty setting (each own high score)
'list of challenges:
'- each with different start + random fixed seed
'- also the basic game with random seed
'different images for incomplete cities, raods, etc. See: https://www.youtube.com/watch?v=fTj2159ShoY
'owb tile grapics

'LATERs:
'tutorial/help with screenshots and page numbers
'font library
'multiple stack
'sound & music

'DON'T:
'zoom in/out ui-buttons + q - (q = magnifier)
'more road end tiles?

'-------------------------------------------------------------------------------

'#include "../../_code_lib_new_/logger_v01.bi"
'dim shared as logger_type logger = logger_type("gamelog.txt", 5, 1.0)
'logger.add("Start")

'-------------------------------------------------------------------------------

#include "fbgfx.bi"
#include "inc_lib/general.bi"
#include "inc_lib/image_buffer_v03.bi"
#include "inc_lib/mouse_v02.bi"
#include "inc_game/buttons.bi"
#include "inc_game/stack_dll.bi"
#include "inc_game/grid_coord.bi"
#include "inc_game/tile.bi"
#include "inc_game/score.bi"
#include "inc_game/simple_list.bi"
#include "inc_game/visited_list.bi"
#include "inc_game/tile_map1.bi"
#include "inc_game/tile_collection.bi"

const SW = 960, SH = 720
screenres SW, SH, 32
width SW \ 8, SH \ 16 'larger font

'--- load tiles & set properties -----------------------------------------------

dim as tile_collection tileSet
if tileSet.load("tiles") <= 0 then panic("load tiles")

'--- define grid ---------------------------------------------------------------

dim as long tileSizeIdx = TILE_M
dim as long wGrid_ = tileSet.pImg(0, 0, tileSizeIdx)->pFbImg->width
dim as long hGrid_ = tileSet.pImg(0, 0, tileSizeIdx)->pFbImg->height
dim as grid_coord grid = type(wGrid_, hGrid_) 'grid larger than images

'--- other images --------------------------------------------------------------

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

'--- subs ----------------------------------------------------------------------

sub zoomGrid(direction as long, byref tileSizeIdx as long, byref grid as grid_coord)
	if direction > 0 then 'dir = +
		if tileSizeIdx > TILE_L then 'zoom in
			tileSizeIdx -= 1
			grid.w shl= 1
			grid.h shl= 1
		end if
	else 'dir = -
		if tileSizeIdx < TILE_S then 'zoom out
			tileSizeIdx += 1
			grid.w shr= 1
			grid.h shr= 1
		end if
	end if
end sub

'--- main ----------------------------------------------------------------------

dim as score_type score

dim as tile_map map
map.setTile(0, 0, tileSet.tile(1)) 'set first tile 1 at 0,0

dim as int2d scrnPosOnMap
scrnPosOnMap = type((grid.w - SW) \ 2, (grid.h - SH) \ 2) 'center on tile 0,0

const as double scrollSpeed = 1000 / 4 '250 pixels / second

randomize timer '1234

dim as long numStack = 1, stackMask = &b0001
dim as card_stack stack(0 to 3)
dim as long stackSize = 12
for i as integer = 0 to stackSize - 1
	'stack.push(tileSet.getRandomId())
	stack(0).pushFirst(tileSet.getRandomDistId()) 'top = first
	'stack(0).pushFirst(15)
next
dim as btn_type stackBtn(0 to 3)
for i as long = 0 to 3
	dim as image_type ptr pImg = tileSet.pImg(0, 0, TILE_S)
	dim as long w = pImg->pFbImg->width
	stackBtn(i).define((SW - 10) - (w + 20) * i, SH - 10, IHA_RIGHT, IVA_BOTTOM, pImg, 4, &hff00ff)
next

dim as long match
dim as tile_type nbTile(0 to 3)

dim as mousetype mouse
dim as integer mouseEvent
dim as integer mx, my
dim as long mouseDrag = 0
dim as tile_type sTile = type(-1, 0) 'id, rot (selected tile)
dim as double tLast = timer, dt = 0
dim as string quitStr = ""

while quitStr = ""
	mouseEvent = handleMouse(mouse)
	mx = mouse.pos.x
	my = mouse.pos.y
	dim as integer scrollDist = int(dt * scrollSpeed) + 1
	dim as int2d mouseGridPos = grid.getGridPos(scrnPosOnMap + mouse.pos)
	dim as tile_type mTile = map.getTile(mouseGridPos) 'tile at mouse pos in grid
	dim as long neigbours = 0
	dim as long allowPlacement = 0
	dim as long showPreview = 0

	'determine what to display at mouse cursor grid position
	if mouse.status = 0 and sTile.id >= 0 then 'selected tile selected from stack
		if mTile.id <= 0 then 'no tile already at mouse grid pos
			allowPlacement = 1 'maybe ok, check neighbours also...
			showPreview = 1
			match = 0 'reset all sides
			for i as long = 0 to 3
				nbTile(i) = map.getTile(mouseGridPos + map.nbDeltaPos(i))
				if nbTile(i).id > 0 then 'a valid neighbour tile
					neigbours += 1
					dim as long nbSide = (i + 2) mod 4
					if sTile.prop(i) = nbTile(i).prop(nbSide) then
						setbit(match, i)
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
			sTile.rotate(-1)
		else
			zoomGrid(+1, tileSizeIdx, grid)
		end if
	case MOUSE_WHEEL_DOWN
		if sTile.id > 0 then
			sTile.rotate(+1)
		else
			zoomGrid(-1, tileSizeIdx, grid)
		end if
	case MOUSE_RB_PRESSED
		mouseDrag = 1
	case MOUSE_RB_RELEASED
		mouseDrag = 0
	case MOUSE_LB_PRESSED
		dim as long onGrid = 1
		for i as long = 0 to numStack - 1 
			if stackBtn(i).inside(mx, my) then
				onGrid = 0
				if sTile.id >= 0 then
					'out back on stack
					'limit extra stack to one tile
					if i > 0 andalso stack(i).size = 0 then
						stack(i).pushFirst(sTile.id) 'top = first
						sTile.id = -1
					end if
				else
					'get from stack
					if stack(i).size() > 0 then
						dim as long id = stack(i).popFirst() 'top = first
						sTile = tileSet.tile(id)
					end if
				end if
			end if
		next
		if onGrid = 1 then
			'place on grid/map
			if sTile.id >= 0 then
				if allowPlacement = 1 then
					map.setTile(mouseGridPos, sTile) 'place tile
					sTile.id = -1 'set selected tile invalid
					map.checkPlacement(mouseGridPos.x, mouseGridPos.y, score)
					if map.checkAbbey(mouseGridPos.x, mouseGridPos.y, stackMask) then
						numStack = &b0001
						'count bits in mask
						for i as long = 1 to 3
							if bit(stackMask, i) then numStack += 1
						next
					end if
				end if
			end if
		end if
	end select

	if mouseDrag = 1 then
		scrnPosOnMap -= mouse.posChange
	end if

	dim as string key = inkey()
	select case key
		case "q", "Q" : quitStr = "Abort by user"
		case "-", "_" : zoomGrid(-1, tileSizeIdx, grid)
		case "=", "+" : zoomGrid(+1, tileSizeIdx, grid)
	end select

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
				tileSet.pImg(tile.id, tile.rot, tileSizeIdx)->drawxym(scrnPos.x, scrnPos.y, IHA_LEFT, IVA_TOP)
				'draw string (scrnPos.x + 4, scrnPos.y + 2), str(tile.id) 'show tile id
				'draw string (scrnPos.x + 4, scrnPos.y + 2 + 16), bin(tile.link, 6) 'show tile link info
			end if
		next
	next
	'draw stack
	for i as long = 0 to numstack - 1
		stackBtn(i).pImg = iif(stack(i).size() <= 0, 0, tileSet.pImg(stack(i).getFirst(), 0, TILE_S)) 'top = first
		stackBtn(i).drawm()
		draw string (stackBtn(i).x + 2 + 4, stackBtn(i).y + 4), str(stack(i).size()), &hffffff
	next
	'highligt mouse position on grid
	dim as int2d scrnPos = grid.getScrPos(mouseGridPos, scrnPosOnMap)
	'draw selected image at mouse position if valid
	if mouse.status = 0 and sTile.id >= 0 then
		'draw selected tile at mouse position
		tileSet.pImg(sTile.id, sTile.rot, tileSizeIdx)->drawxym(mx, my, IHA_CENTER, IVA_CENTER, IDM_ALPHA, 192)
		'show tile on grid if place ok, but without matching neighbour check
		if showPreview = 1 then
			tileSet.pImg(sTile.id, sTile.rot, tileSizeIdx)->drawxym(scrnPos.x, scrnPos.y, IHA_LEFT, IVA_TOP, IDM_ALPHA, 127)
		end if
		'show neighbour matching indicators
		if mTile.id <= 0 then 'no tile already at mouse grid pos
			for i as long = 0 to 3
				if nbTile(i).id > 0 then 'a valid neighbour
					dim as image_type ptr pImgImg = iif(bit(match, i), pImgOk, pImgNok)
					dim as long x = scrnPos.x + (grid.w + map.nbDeltaPos(i).x * grid.w) \ 2
					dim as long y = scrnPos.y + (grid.h + map.nbDeltaPos(i).y * grid.h) \ 2
					pImgImg->drawxym(x, y, IHA_CENTER, IVA_CENTER, IDM_ALPHA)
				end if
			next
		end if
	end if
	
	draw string (10, 10), "<Q> to quit, Time: " & time, &hffff00
	'draw string (10, 40), "Use mouse to:", &hffff00
	'draw string (10, 55), "* pick a tile from stack, (left button)", &hffff00
	'draw string (10, 70), "* rotate tile (if picked up) with wheel", &hffff00
	'draw string (10, 85), "* place on board if allowed (left button)", &hffff00
	'draw string (10, 100), "* zoom in/out, with no tile, with wheel", &hffff00
	'draw string (10, 115), "* drag view with right button", &hffff00

	draw string (10, 145), "Road score:  " & str(score.r), &hffff00
	draw string (10, 160), "Water score: " & str(score.w), &hffff00
	draw string (10, 175), "City score:  " & str(score.c), &hffff00
	draw string (10, 190), "Abbey score:  " & str(score.a), &hffff00
	draw string (10, 205), "Neigb score:  " & str(score.n), &hffff00
	draw string (10, 220), "Delta score: " & str(score.delta), &hffff00
	draw string (10, 235), "Total score: " & str(score.total), &hffff00

	draw string (10, SH - 25), "Mouse pos: " & mouseGridPos, &hffff00
	
	'draw string (80, 30), str(scrollDist), &hffff00
	'locate 2,1 : print scrnPosOnMap.x, scrnPosOnMap.y
	screenunlock

	'update tiles
	dim as long tileGain = score.tilesGained()
	for i as long = 1 to tileGain
		'stack(0).pushLast(tileSet.getRandomId()) 'bottom = last
		stack(0).pushLast(tileSet.getRandomDistId())
	next
	'check if any tiles left
	if sTile.id = -1 then 'no tile being dragged
		dim as boolean tilesLeft = false
		for i as long = 0 to numStack - 1
			if stack(i).size() > 0 then
				tilesLeft = true
				exit for
			end if
		next
		if tilesLeft = false then quitStr = "No tiles left"
	end if

	sleep 1, 1
	dim as double tNow = timer
	dt = tNow - tLast
	tLast = tNow
wend

dim as string endText = "GAVE OVER"
draw string ((SW - len(endText) * 8) \ 2, (SH - 32) \ 2), endText, &h00ffff
draw string ((SW - len(quitStr) * 8) \ 2, (SH - 0) \ 2), quitStr, &h00ffff
getkey()
end
