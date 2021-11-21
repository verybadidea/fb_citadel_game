'redimpreserve by dodicat (with some renaming & reformatting)

#macro redimpreserve(a, d1, d2) 'a = 2d-array, dimension 1 & 2
scope
	dim as integer x, y
	redim as typeof(a) copy(d1, d2)
	for x = d1
		for y = d2
			if x >= lbound(a, 1) and x <= ubound(a, 1) then
				if y >= lbound(a, 2) and y <= ubound(a, 2) then   
					copy(x, y) = a(x, y)
				end if
			end if
		next
	next
	redim a(d1, d2)
	for x = d1
		for y = d2
			a(x, y) = copy(x, y)
		next
	next
end scope
#endmacro

#macro printout(d) 'd = 2d-array
print
for x as long = lbound(d, 1) to ubound(d, 1)
	for y as long = lbound(d, 2) to ubound(d, 2)
		print d(x, y);
	next
	print
next
print       
#endmacro

'class wrapper for game

type tile_map
	dim as int2d nbDeltaPos(0 to 3) = {int2d(0, -1), int2d(+1, 0), int2d(0, +1), int2d(-1, 0)}
	dim as tile_type tile(any, any) 'x, y
	dim as visited_list vList
	dim as score_type ptr pScore
	declare constructor(byref score as score_type)
	declare sub clean()
	declare function validPos(x as long, y as long) as boolean
	declare function getTile(x as long, y as long) as tile_type
	declare sub setTile(x as long, y as long, tile_ as tile_type)
	declare function getTile overload(pos_ as int2d) as tile_type
	declare sub setTile overload(pos_ as int2d, tile_ as tile_type)
	declare function check4Neighbours(x as long, y as long) as long
	declare function check8Neighbours(x as long, y as long) as long
	declare function checkAbbey(x as long, y as long, byref  abbeyProgress as long) as long
	declare function checkPlacement(x as long, y as long) as long
	declare function tryWalk(x as long, y as long, area as long, prop as long) as long
end type

constructor tile_map(byref score as score_type)
	pScore = @score
	if pScore = 0 then panic("tile_map: pScore = 0")
end constructor

sub tile_map.clean()
	'''free...
end sub

function tile_map.validPos(x as long, y as long) as boolean
	if (x < lbound(tile, 1)) or (x > ubound(tile, 1)) then return FALSE
	if (y < lbound(tile, 2)) or (y > ubound(tile, 2)) then return FALSE
	if tile(x, y).id <= 0 then return FALSE 'valid pos, no tile
	return TRUE
end function

function tile_map.getTile(x as long, y as long) as tile_type
	if (x < lbound(tile, 1)) or (x > ubound(tile, 1)) then return NO_TILE
	if (y < lbound(tile, 2)) or (y > ubound(tile, 2)) then return NO_TILE
	return tile(x, y)
end function

sub tile_map.setTile(x as long, y as long, tile_ as tile_type)
	dim as integer lbx = lbound(tile, 1)
	dim as integer ubx = ubound(tile, 1)
	dim as integer lby = lbound(tile, 2)
	dim as integer uby = ubound(tile, 2)
	dim as long resize = 0
	if x < lbx then lbx = x : resize = 1
	if x > ubx then ubx = x : resize = 1
	if y < lby then lby = y : resize = 1
	if y > uby then uby = y : resize = 1
	if resize = 1 then
		redimpreserve(tile, lbx to ubx, lby to uby)
	end if
	tile(x, y) = tile_
end sub

function tile_map.getTile(pos_ as int2d) as tile_type
	return getTile(pos_.x, pos_.y)
end function

sub tile_map.setTile(pos_ as int2d, tile_ as tile_type)
	setTile(pos_.x, pos_.y, tile_)
end sub

'check 4 neighbours, extra points for abbey, return score
function tile_map.check4Neighbours(x as long, y as long) as long
	dim as long count = 0
	if getTile(x + 1, y + 0).id > 0 then count += 1
	if getTile(x - 1, y + 0).id > 0 then count += 1
	if getTile(x + 0, y + 1).id > 0 then count += 1
	if getTile(x + 0, y - 1).id > 0 then count += 1
	if tile(x, y).prop(AREA_CT) = PROP_A then count += 1
	return triangular(count - 1)
end function

'check 8 neighbours if valid and abbey cross or full
'.....................
'...TTT...TAT...AAA...
'...TAT...AAA...AAA...
'...TTT...TAT...AAA...
'.....................
function tile_map.check8Neighbours(x as long, y as long) as long
	dim as boolean fullAbbey = true
	dim as boolean crossAbbey = true
	dim as long xc, yc
	for yi as long = -1 to +1
		yc = y + yi
		for xi as long = -1 to +1
			xc = x + xi
			if xi = 0 and yi = 0 then continue for 'skip self
			if getTile(xc, yc).id <= 0 then return 0
			if abs(xi) + abs(yi) = 1 then
				if tile(xc, yc).prop(AREA_CT) <> PROP_A then crossAbbey = false
			end if
			if tile(xc, yc).prop(AREA_CT) <> PROP_A then fullAbbey = false
		next
	next
	if fullAbbey = true then return 3
	if crossAbbey = true then return 2
	return 1 'abbey surrounded by valid tiles
end function

'check abbey, after tile placement
'..............
'.....TT.......
'.....AT.......
'.....N........
'..............
'for 1st extra stack:
'1 abbey fully surrounded by any tile
'check all 8 neibours of placed tile:
'for each neighbour:
'  if abbey:
'    count abbey neibours
'    if count = 8 then add stack
'..............
'.....TT.......
'....TAAT......
'....TA.A......
'....TTAT......
'for 2nd extra stack:
'1 abbey surrounded by any tile + abbey on left,right,north,south
'for 3nd extra stack:
'1 abbey surrounded by all abbeys/monastries/cloisters
'only check if corresponding stack not yet obtained.
'possible to gain the 3 extra stacks at once
'does not result in extra point
'when all stacks obtaind, nothing else happens 

'prefect abbey check, abbeyProgress = numStack
function tile_map.checkAbbey(x as long, y as long, byref abbeyProgress as long) as long
	dim as long xc, yc
	for yi as long = -1 to +1
		yc = y + yi
		for xi as long = -1 to +1
			xc = x + xi
			'also check self, could be abbey just placed
			if getTile(xc, yc).id > 0 then
				if tile(xc, yc).prop(AREA_CT) = PROP_A then 'is abbey
					dim as long abbeyLevel = check8Neighbours(xc, yc)
					if abbeyLevel + 1 > abbeyProgress then
						abbeyProgress = abbeyLevel + 1
					end if
				end if
			end if
		next
	next
	return 0
end function

'check on new tile placement
function tile_map.checkPlacement(x as long, y as long) as long
	pScore->clr()
	for iArea as long = 0 to 3
		dim as long prop = tile(x, y).prop(iArea)
		pScore->t = 0
		tryWalk(x, y, iArea, prop)
		if pScore->t > 0 then pScore->c += pScore->t
	next
	if pScore->r < 0 then pScore->r = 0
	if pScore->w < 0 then pScore->w = 0
	pScore->n = check4Neighbours(x, y)
	pScore->updateTotal()
	vList.clr()
	return 0
end function

function tile_map.tryWalk(x as long, y as long, area as long, prop as long) as long
	'check valid map position
	'if validTile(x, y) = FALSE then
	if getTile(x, y).id <= 0 then
		 'This means end of road/city/water
		 if prop = PROP_R then pScore->r = -1
		 if prop = PROP_W then pScore->w = -1
		 if prop = PROP_C then pScore->t = -1 'cannot be blazon on the edge
		 'Bug: A tile with 2 city parts always results in -1 !!!
		return -1
	end if
	'check correct type
	if tile(x, y).prop(area) <> prop then return -1
	'check not yet visited
	dim as long tileIdx = vList.getTile(x, y)
	if vList.vTile(tileIdx).area(area) = 1 then return -1
	if prop = PROP_R or prop = PROP_W then 'road or water
		'loop all adjacent tiles (and self) and try neighbours
		for iArea as long = 0 to 3
			if tile(x, y).prop(iArea) = prop then
				if vList.vTile(tileIdx).area(iArea) = 0 then 'not visited yet?
					vList.vTile(tileIdx).area(iArea) = 1 'set visited
					if prop = PROP_R then
						if pScore->r >= 0 then pScore->r += 1
					elseif prop = PROP_W then
						if pScore->w >= 0 then pScore->w += 1
					end if
					'check neighbour tile
					select case iArea
						case AREA_UP : tryWalk(x, y - 1, AREA_DN, prop)
						case AREA_RI : tryWalk(x + 1, y, AREA_LE, prop)
						case AREA_DN : tryWalk(x, y + 1, AREA_UP, prop)
						case AREA_LE : tryWalk(x - 1, y, AREA_RI, prop)
					end select
					'dim as long nbArea = (iArea + 2) mod 4
					'dim as int2d newPos = int2d(x, y) + nbDeltaPos(iArea)
					'tryWalk(newPos.x, newPos.y, nbArea, prop)
				end if
			end if
		next
	elseif prop = PROP_C then 'city
		'check if center is city (note: only center can be B for blazon, not edges)
		dim as ulong center = tile(x, y).prop(AREA_CT)
		if center = PROP_C or center = PROP_B then
			vList.vTile(tileIdx).area(AREA_CT) = 1 'set visited (although not needed)
			if pScore->t >= 0 then
				pScore->t += iif(center = PROP_B, 2, 1) 'bonus point for blazon tile
			end if
			'loop edge tiles (and self) and try neighbours
			for iArea as long = 0 to 3
				if tile(x, y).prop(iArea) = prop then
					if vList.vTile(tileIdx).area(iArea) = 0 then 'not visited yet?
						vList.vTile(tileIdx).area(iArea) = 1 'set visited
						if pScore->t >= 0 then pScore->t += 1
						'check neighbour tile
						select case iArea
							case AREA_UP : tryWalk(x, y - 1, AREA_DN, prop)
							case AREA_RI : tryWalk(x + 1, y, AREA_LE, prop)
							case AREA_DN : tryWalk(x, y + 1, AREA_UP, prop)
							case AREA_LE : tryWalk(x - 1, y, AREA_RI, prop)
						end select
					end if
				end if
			next
		else 'city end on this edge, 1 point only
			vList.vTile(tileIdx).area(area) = 1 'set visited
			if pScore->t >= 0 then pScore->t += 1
			select case area
				case AREA_UP : tryWalk(x, y - 1, AREA_DN, prop)
				case AREA_RI : tryWalk(x + 1, y, AREA_LE, prop)
				case AREA_DN : tryWalk(x, y + 1, AREA_UP, prop)
				case AREA_LE : tryWalk(x - 1, y, AREA_RI, prop)
			end select
		end if
	end if
	return 0
end function

'--- test ----------------------------------------------------------------------

'~ dim as tile_map tGrid

'~ tGrid.setTile(0, 0, -1) ' start tile
'~ tGrid.setTile(-5, 2, 3)
'~ print tGrid.tile(0,0)
'~ print "col bounds: " & lbound(tGrid.tile, 1) & " to " & ubound(tGrid.tile, 1)
'~ print "row bounds: " & lbound(tGrid.tile, 2) & " to " & ubound(tGrid.tile, 2)
