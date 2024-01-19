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
	dim as simple_list sList
	dim as boolean walkSuccess
	declare sub reset_()
	declare sub prepare(tileSet as tile_collection, mapId as long)
	declare function validPos(x as long, y as long) as boolean
	declare function getTile(x as long, y as long) as tile_type
	declare sub setTile(x as long, y as long, tile_ as tile_type)
	declare function getTile overload(pos_ as int2d) as tile_type
	declare sub setTile overload(pos_ as int2d, tile_ as tile_type)
	declare function checkAbbeyAny(x as long, y as long) as boolean
	declare function checkAbbeyCross(x as long, y as long) as boolean
	declare function checkAbbeyBlock(x as long, y as long) as boolean
	declare function checkAbbey(x as long, y as long, byref abbeyMask as long) as boolean
	declare function check4Neighbours(x as long, y as long) as boolean
	declare function checkPlacement(x as long, y as long, byref score as score_type) as long
	declare function tryWalk(x as long, y as long, area as long, prop as long) as boolean
	declare function xMin() as long
	declare function xMax() as long
	declare function yMin() as long
	declare function yMax() as long
	declare function size() as long 'x*y
	'declare function saveToDisk(fileName as string) as long
	'declare function loadFromDisk(fileName as string) as long
	declare function saveToDisk(fileNum as integer) as long
	declare function loadFromDisk(fileNum as integer) as long
end type

sub tile_map.reset_()
	'''free...
	erase(tile)
end sub

sub tile_map.prepare(tileSet as tile_collection, mapId as long) 'id = 0 clean only
	reset_()
	select case mapId
		case 1
			setTile(0, 0, tileSet.tile(1)) 'set first tile 1 at 0,0
	end select
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

'.....................
'...TTT...TAT...AAA...
'...TAT...AAA...AAA...
'...TTT...TAT...AAA...
'.....................

function tile_map.checkAbbeyAny(x as long, y as long) as boolean
	for yi as long = -1 to +1
		for xi as long = -1 to +1
			if getTile(x + xi, y + yi).id <= 0 then return false
		next
	next
	return true 'abbey surrounded by valid tiles
end function

function tile_map.checkAbbeyCross(x as long, y as long) as boolean
	for yi as long = -1 to +1
		for xi as long = -1 to +1
			if getTile(x + xi, y + yi).id <= 0 then return false
			if (abs(xi) + abs(yi)) > 1 then
				'must not be abbey
				if tile(x + xi, y + yi).prop(AREA_CT) = PROP_A then return false
			else
				'has to be abbey
				if tile(x + xi, y + yi).prop(AREA_CT) <> PROP_A then return false
			end if
		next
	next
	return true 'abbey surrounded by valid tiles & 4 abbeys
end function

function tile_map.checkAbbeyBlock(x as long, y as long) as boolean
	for yi as long = -1 to +1
		for xi as long = -1 to +1
			if getTile(x + xi, y + yi).id <= 0 then return false
			if tile(x + xi, y + yi).prop(AREA_CT) <> PROP_A then return false
		next
	next
	return true 'abbey surrounded by 8 abbyes
end function

'prefect abbey check (neibours: any, abbey cross, abbey full)
function tile_map.checkAbbey(x as long, y as long, byref abbeyMask as long) as boolean
	dim as boolean retVal = false
	dim as long xc, yc
	for yi as long = -1 to +1
		yc = y + yi
		for xi as long = -1 to +1
			xc = x + xi
			'also check self, could be abbey just placed
			if getTile(xc, yc).id > 0 then
				if tile(xc, yc).prop(AREA_CT) = PROP_A then 'is abbey
					if (abbeyMask and &b0010) = 0 then
						if checkAbbeyAny(xc, yc) then abbeyMask or= &b0010
						retVal = true 'bitmask changed
					end if
					if (abbeyMask and &b0100) = 0 then
						if checkAbbeyCross(xc, yc) then abbeyMask or= &b0100
						retVal = true 'bitmask changed
					end if
					if (abbeyMask and &b1000) = 0 then
						if checkAbbeyBlock(xc, yc) then abbeyMask or= &b1000
						retVal = true 'bitmask changed
					end if
				end if
			end if
		next
	next
	return retVal
end function

'check 4 neighbours present / perfect tile
function tile_map.check4Neighbours(x as long, y as long) as boolean
	if getTile(x + 1, y + 0).id <= 0 then return false
	if getTile(x - 1, y + 0).id <= 0 then return false
	if getTile(x + 0, y + 1).id <= 0 then return false
	if getTile(x + 0, y - 1).id <= 0 then return false
	return true
end function

'check on new tile placement
function tile_map.checkPlacement(x as long, y as long, byref score as score_type) as long
	score.clr()
	vList.clr()
	for iArea as long = 0 to 3
		sList.clr()
		dim as long prop = tile(x, y).prop(iArea)
		walkSuccess = true
		tryWalk(x, y, iArea, prop)
		if walkSuccess then
			select case prop
				case PROP_R
					if sList.size() >= 1 then score.r += (sList.size() - 1)
				case PROP_W
					if sList.size() >= 0 then score.w += (sList.size())
				case PROP_C
					if sList.size() >= 2 then score.c += (sList.size() - 2)
					for iTile as long = 0 to slist.size() - 1
						dim as simple_tile sTile = sList.sTile(iTile)
						if tile(sTile.x, sTile.y).prop(AREA_CT) = PROP_B then
							score.c += 1
						end if
					next
				case else
					'nothing
			end select
		end if
	next
	score.n = iif(check4Neighbours(x, y), 1, 0)
	score.updateTotal()
	return 0
end function

function tile_map.tryWalk(x as long, y as long, area as long, prop as long) as boolean 'RETURN HAS NO PURPOSE!
	'check valid map position
	if getTile(x, y).id <= 0 then
		walkSuccess = false
		return false 'incomplete construction
	end if
	'check correct type
	if tile(x, y).prop(area) <> prop then panic("tryWalk") 'obsolete check?
	'check not yet visited
	dim as long tileIdx = vList.getTile(x, y) 'find tile id
	if vList.vTile(tileIdx).area(area) = 1 then return false 'already visited

	sList.addTileIfNew(x, y) 'add to simple list for score count

	'loop edge tiles if linked (and self) and try neighbours
	'double check if same type else panic
	for iArea as long = 0 to 3
		'check if areas linked or self
		if (linkBitmask(area, iArea) and tile(x, y).link) or (iArea = area) then
			if tile(x, y).prop(iArea) <> prop then
				print tile(x, y).id, area, iArea, prop, tile(x, y).prop(iArea), bin(tile(x, y).link), bin(linkBitmask(area, iArea))
				panic("tryWalk: Prop not equal, but linked")
			end if
			if vList.vTile(tileIdx).area(iArea) = 0 then 'not visited yet?
				vList.vTile(tileIdx).area(iArea) = 1 'set visited
				'check neighbour tile
				select case iArea
					case AREA_UP : tryWalk(x, y - 1, AREA_DN, prop) 'down area of upper tile
					case AREA_RI : tryWalk(x + 1, y, AREA_LE, prop)
					case AREA_DN : tryWalk(x, y + 1, AREA_UP, prop)
					case AREA_LE : tryWalk(x - 1, y, AREA_RI, prop)
				end select
			end if
		end if
	next
	return true
end function

function tile_map.xMin() as long
	return lbound(tile, 1)
end function

function tile_map.xMax() as long
	return ubound(tile, 1)
end function

function tile_map.yMin() as long
	return lbound(tile, 2)
end function

function tile_map.yMax() as long
	return ubound(tile, 2)
end function

function tile_map.size() as long 'x*y
	return (xMax() - xMin() + 1) * (yMax() - yMin() + 1)
end function
	
'~ function tile_map.saveToDisk(fileName as string) as long
	'~ dim as integer fileNum = freefile()
	'~ if open(fileName, for binary, access write, as fileNum) = 0 then
		'~ 'write map dimensions
		'~ put #fileNum, , xMin()
		'~ put #fileNum, , xMax()
		'~ put #fileNum, , yMin()
		'~ put #fileNum, , yMax()
		'~ 'write tile data
		'~ for x as integer = xMin() to xMax
			'~ for y as integer = yMin() to yMax
				'~ put #fileNum, , tile(x, y)
			'~ next 
		'~ next
		'~ close #fileNum
	'~ else
		'~ panic("tile_map.saveToDisk()")
	'~ end if
	'~ return 0
'~ end function

'~ function tile_map.loadFromDisk(fileName as string) as long
	'~ reset_() 'erase current map in memory
	'~ dim as integer fileNum = freefile()
	'~ if open(fileName, for binary, access read, as fileNum) = 0 then
		'~ 'read map dimensions
		'~ dim as long lbx, ubx, lby, uby 'lower/upper boundary x/y
		'~ get #fileNum, , lbx
		'~ get #fileNum, , ubx
		'~ get #fileNum, , lby
		'~ get #fileNum, , uby
		'~ redimpreserve(tile, lbx to ubx, lby to uby)
		'~ 'read tile data
		'~ for x as integer = xMin() to xMax
			'~ for y as integer = yMin() to yMax
				'~ get #fileNum, , tile(x, y)
			'~ next 
		'~ next
		'~ close #fileNum
	'~ else
		'~ panic("tile_map.loadFromDisk()")
	'~ end if
	'~ return 0
'~ end function

function tile_map.saveToDisk(fileNum as integer) as long
	'write map dimensions
	put #fileNum, , xMin()
	put #fileNum, , xMax()
	put #fileNum, , yMin()
	put #fileNum, , yMax()
	'write tile data
	for x as integer = xMin() to xMax
		for y as integer = yMin() to yMax
			put #fileNum, , tile(x, y)
		next 
	next
	return 0
end function

function tile_map.loadFromDisk(fileNum as integer) as long
	reset_() 'erase current map in memory
	'read map dimensions
	dim as long lbx, ubx, lby, uby 'lower/upper boundary x/y
	get #fileNum, , lbx
	get #fileNum, , ubx
	get #fileNum, , lby
	get #fileNum, , uby
	redim tile (lbx to ubx, lby to uby)
	'read tile data
	for x as integer = xMin() to xMax
		for y as integer = yMin() to yMax
			get #fileNum, , tile(x, y)
		next 
	next
	return 0
end function

'--- test ----------------------------------------------------------------------

'~ dim as tile_map tGrid

'~ tGrid.setTile(0, 0, -1) ' start tile
'~ tGrid.setTile(-5, 2, 3)
'~ print tGrid.tile(0,0)
'~ print "col bounds: " & lbound(tGrid.tile, 1) & " to " & ubound(tGrid.tile, 1)
'~ print "row bounds: " & lbound(tGrid.tile, 2) & " to " & ubound(tGrid.tile, 2)
