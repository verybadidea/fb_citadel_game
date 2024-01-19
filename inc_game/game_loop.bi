'--- zoomGrid ------------------------------------------------------------------

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

'--- limitView -----------------------------------------------------------------

sub limitView(scrnPosOnMap as int2d, map as tile_map, grid as grid_coord)
	dim as long xLimit, yLimit
	yLimit = (map.yMin + 1) * grid.h - SH
	if scrnPosOnMap.y < yLimit then scrnPosOnMap.y = yLimit
	yLimit = map.yMax * grid.h
	if scrnPosOnMap.y > yLimit then scrnPosOnMap.y = yLimit
	xLimit = (map.xMin + 1) * grid.w - SW
	if scrnPosOnMap.x < xLimit then scrnPosOnMap.x = xLimit
	xLimit = map.xMax * grid.w
	if scrnPosOnMap.x > xLimit then scrnPosOnMap.x = xLimit
end sub

'-------------------------------------------------------------------------------

type game_type
	dim as tile_map map
	dim as score_type score
	dim as multi_stack mStack
	declare sub init()
	declare function saveToDisk(fileName as string) as long
	declare function loadFromDisk(fileName as string) as long
	declare function loop_() as long
end type

sub game_type.init() 'for new game only
	score.reset_()
	mStack.reset_()
	map.prepare(tileSet, 1)
	mStack.addRndCards(0, 12, tileSet) 'start with ... cards
end sub

function game_type.saveToDisk(fileName as string) as long
	dim as long fileVersion = 2
	dim as integer fileNum = freefile()
	if open(fileName, for binary, access write, as fileNum) = 0 then
		put #fileNum, , fileVersion
		map.saveToDisk(fileNum) 'write map dimensions & tiles
		mStack.saveToDisk(fileNum)
		put #fileNum, , score.total
		close #fileNum
	else
		panic("tile_map.saveToDisk(): file error")
	end if
	return 0
end function

'reset & load: map, stacks, score
function game_type.loadFromDisk(fileName as string) as long
	dim as long fileVersion
	dim as integer fileNum = freefile()
	if open(fileName, for binary, access read, as fileNum) = 0 then
		get #fileNum, , fileVersion
		if fileVersion <> 2 then panic("tile_map.loadFromDisk(): version error")
		map.loadFromDisk(fileNum) 'read map dimensions & tiles
		mStack.loadFromDisk(fileNum)
		'
		score.reset_()
		get #fileNum, , score.total
		score.old = score.total
		'
		close #fileNum
	else
		panic("tile_map.loadFromDisk(): file error")
	end if
	return 0
end function


function game_type.loop_() as long '(map as tile_map, score as score_type, mStack as multi_stack) as long

	'--- define grid -----------------------------------------------------------

	dim as long tileSizeIdx = TILE_M
	dim as long wGrid_ = tileSet.pImg(0, 0, tileSizeIdx)->pFbImg->width
	dim as long hGrid_ = tileSet.pImg(0, 0, tileSizeIdx)->pFbImg->height
	dim as grid_coord grid = type(wGrid_, hGrid_) 'grid larger than images

	dim as int2d scrnPosOnMap
	scrnPosOnMap = type((grid.w - SW) \ 2, (grid.h - SH) \ 2) 'center on tile 0,0

	const as double scrollSpeed = 1000 / 4 '250 pixels / second

	randomize timer '1234

	'~ dim as long numStack = 1, stackMask = &b0001
	'~ dim as card_stack stack(0 to 3)
	'~ dim as long stackSize = 12
	'~ for i as integer = 0 to stackSize - 1
		'~ 'stack.push(tileSet.getRandomId())
		'~ stack(0).pushFirst(tileSet.getRandomDistId()) 'top = first
		'~ 'stack(0).pushFirst(15)
	'~ next
	
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
	dim as long quit = 0
	dim as string quitStr = ""

	while quit = 0
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
		
		'------------------------- USER INPUT : MOUSE ------------------------------
		
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
			'for iStack as long = 0 to numStack - 1
			for iStack as long = 0 to mStack.numStack()
				if stackBtn(iStack).inside(mx, my) then
					onGrid = 0 'mouse not above grid but above button
					if sTile.id >= 0 then
						'put back on stack
						'limit extra stack to one tile
						'if iStack > 0 andalso stack(iStack).size = 0 then
						if iStack = 0 or mStack.stack(iStack).size = 0 then
							mStack.stack(iStack).pushFirst(sTile.id) 'top = first
							sTile.id = -1
						end if
					else
						'get from stack
						if mStack.stack(iStack).size() > 0 then
							dim as long id = mStack.stack(iStack).popFirst() 'top = first
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
						map.checkAbbey(mouseGridPos.x, mouseGridPos.y, mStack.stackMask)
						'~ if map.checkAbbey(mouseGridPos.x, mouseGridPos.y, mStack.stackMask) then
							'~ numStack = &b0001
							'~ 'count bits in mask
							'~ for i as long = 1 to 3
								'~ if bit(stackMask, i) then numStack += 1
							'~ next
						'~ end if
					end if
				end if
			end if
		end select

		if mouseDrag = 1 then
			scrnPosOnMap -= mouse.posChange
		end if

		'----------------------- USER INPUT : KEYBOARD -----------------------------

		if rkey.isReleased(RKEY_QUIT) then
			quit = 1 : quitStr = "Abort by user"
		end if
		if rkey.isReleased(RKEY_ZOOM_IN) then
			zoomGrid(-1, tileSizeIdx, grid)
		end if
		if rkey.isReleased(RKEY_ZOOM_OUT) then
			zoomGrid(+1, tileSizeIdx, grid)
		end if
		if rkey.isDown(RKEY_UP) then
			scrnPosOnMap.y -= scrollDist
		end if
		if rkey.isDown(RKEY_DOWN) then
			scrnPosOnMap.y += scrollDist
		end if
		if rkey.isDown(RKEY_LEFT) then
			scrnPosOnMap.x -= scrollDist
		end if
		if rkey.isDown(RKEY_RIGHT) then
			scrnPosOnMap.x += scrollDist
		end if
		if rkey.isReleased(RKEY_ROTATE) then
			if sTile.id > 0 then sTile.rotate(+1)
		end if
		rkey.updateState() 'very important

		'limit view area, call after zoom & scroll
		limitView(scrnPosOnMap, map, grid)

		'---------------------- DRAWING SECTION : START ----------------------------

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
				if tile.Id > 0 then '>=0 to show grey tiles
					tileSet.pImg(tile.id, tile.rot, tileSizeIdx)->drawxym(scrnPos.x, scrnPos.y, IHA_LEFT, IVA_TOP)
					'draw string (scrnPos.x + 4, scrnPos.y + 2), str(tile.id) 'show tile id
					'draw string (scrnPos.x + 4, scrnPos.y + 2 + 16), bin(tile.link, 6) 'show tile link info
				end if
			next
		next
		'draw stack
		for i as long = 0 to mStack.numstack - 1
			stackBtn(i).pImg = iif(mStack.stack(i).size() <= 0, 0, tileSet.pImg(mStack.stack(i).getFirst(), 0, TILE_S)) 'top = first
			stackBtn(i).drawm()
			draw string (stackBtn(i).x + 2 + 4, stackBtn(i).y + 4), str(mStack.stack(i).size()), &hffffff 'show size
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
		
		'draw string (10, 10), "<Esc> to quit, Time: " & time, &hffff00
		'f1.printTextAk(10, 10, "<Esc> to quit", FHA_LEFT)
		'draw string (10, 40), "Use mouse to:", &hffff00
		'draw string (10, 55), "* pick a tile from stack, (left button)", &hffff00
		'draw string (10, 70), "* rotate tile (if picked up) with wheel", &hffff00
		'draw string (10, 85), "* place on board if allowed (left button)", &hffff00
		'draw string (10, 100), "* zoom in/out, with no tile, with wheel", &hffff00
		'draw string (10, 115), "* drag view with right button", &hffff00
		f1.printTextAk(10, 10, "Score: " & str(score.total), FHA_LEFT)

		draw string (10, 145), "Road score:  " & str(score.r), &hffff00
		draw string (10, 160), "Water score: " & str(score.w), &hffff00
		draw string (10, 175), "City score:  " & str(score.c), &hffff00
		draw string (10, 190), "Abbey score:  " & str(score.a), &hffff00
		draw string (10, 205), "Neigb score:  " & str(score.n), &hffff00
		draw string (10, 220), "Delta score: " & str(score.delta), &hffff00
		draw string (10, 235), "Total score: " & str(score.total), &hffff00

		draw string (10, SH - 25), "Mouse pos: " & mouseGridPos, &hffff00
		draw string (10, SH - 40), "scrnPosOnMap: " & scrnPosOnMap, &hffff00
		draw string (10, SH - 70), str(map.yMin()) & " " & str(map.yMax()), &hffff00
		draw string (10, SH - 85), str(map.xMin()) & " " & str(map.xMax()), &hffff00

		if quitStr <> "" then
			dim as string endText = "GAVE OVER"
			draw string ((SW - len(endText) * 8) \ 2, (SH - 32) \ 2), endText, &h00ffff
			draw string ((SW - len(quitStr) * 8) \ 2, (SH - 0) \ 2), quitStr, &h00ffff
		end if
		
		screenunlock

		'----------------------- DRAWING SECTION : END -----------------------------

		'update tiles
		dim as long tileGain = score.tilesGained()
		for i as long = 1 to tileGain
			'stack(0).pushLast(tileSet.getRandomId()) 'bottom = last
			mStack.stack(0).pushLast(tileSet.getRandomDistId())
		next
		'check if any tiles left
		if sTile.id = -1 then 'no tile being dragged
			dim as boolean tilesLeft = false
			for i as long = 0 to mStack.numStack - 1
				if mStack.stack(i).size() > 0 then
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
	return 0
end function

