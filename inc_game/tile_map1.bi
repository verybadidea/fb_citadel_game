'redimpreserve by dodicat (with some renaming & reformatting)

#macro redimpreserve(a, d1, d2) 'a = 2d-array, dimension 1 & 2
scope
	dim as integer row, col
	redim as typeof(a) copy(d1, d2)
	for row = d1
		for col = d2
			if row >= lbound(a, 1) and row <= ubound(a, 1) then
				if col >= lbound(a, 2) and col <= ubound(a, 2) then   
					copy(row, col) = a(row, col)
				end if
			end if
		next
	next
	redim a(d1, d2)
	for row = d1
		for col = d2
			a(row, col) = copy(row, col)
		next
	next
end scope
#endmacro

#macro printout(d) 'd = 2d-array
print
for row as long = lbound(d, 1) to ubound(d, 1)
	for col as long = lbound(d, 2) to ubound(d, 2)
		print d(row, col);
	next
	print
next
print       
#endmacro

'class wrapper for game

type tile_map
	dim as int2d nbDeltaPos(0 to 3) = {int2d(0, -1), int2d(+1, 0), int2d(0, +1), int2d(-1, 0)}
	dim as tile_type tile(any, any) 'row, col
	dim as visited_list vList
	dim as score_type score
	declare sub clean()
	declare function validPos(row as long, col as long) as boolean
	declare function getTile(row as long, col as long) as tile_type
	declare sub setTile(row as long, col as long, tile_ as tile_type)
	declare function getTile overload(pos_ as int2d) as tile_type
	declare sub setTile overload(pos_ as int2d, tile_ as tile_type)
	declare function checkPlacement(x as long, y as long) as long
	declare function tryWalk(x as long, y as long, area as long, prop as long) as long
end type

sub tile_map.clean()
	'''free...
end sub

function tile_map.validPos(row as long, col as long) as boolean
	if (row < lbound(tile, 1)) or (row > ubound(tile, 1)) then return FALSE
	if (col < lbound(tile, 2)) or (col > ubound(tile, 2)) then return FALSE
	return TRUE
end function

function tile_map.getTile(row as long, col as long) as tile_type
	if (row < lbound(tile, 1)) or (row > ubound(tile, 1)) then return NO_TILE
	if (col < lbound(tile, 2)) or (col > ubound(tile, 2)) then return NO_TILE
	return tile(row, col)
end function

sub tile_map.setTile(row as long, col as long, tile_ as tile_type)
	dim as integer lbRow = lbound(tile, 1)
	dim as integer ubRow = ubound(tile, 1)
	dim as integer lbCol = lbound(tile, 2)
	dim as integer ubCol = ubound(tile, 2)
	dim as long resize = 0
	if row < lbRow then lbRow = row : resize = 1
	if row > ubRow then ubRow = row : resize = 1
	if col < lbCol then lbCol = col : resize = 1
	if col > ubCol then ubCol = col : resize = 1
	if resize = 1 then
		redimpreserve(tile, lbRow to ubRow, lbCol to ubCol)
	end if
	tile(row, col) = tile_
end sub

function tile_map.getTile(pos_ as int2d) as tile_type
	return getTile(pos_.x, pos_.y)
end function

sub tile_map.setTile(pos_ as int2d, tile_ as tile_type)
	setTile(pos_.x, pos_.y, tile_)
end sub

'check on new tile placement
function tile_map.checkPlacement(x as long, y as long) as long
	score.clr()
	for iArea as long = 0 to 3
		dim as long prop = tile(x, y).prop(iArea)
		tryWalk(x, y, iArea, prop)
	next
	vList.clr()
	return 0
end function

function tile_map.tryWalk(x as long, y as long, area as long, prop as long) as long
	'check valid map position
	if validPos(x, y) = FALSE then return -1
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
						score.r += 1
					elseif prop = PROP_W then
						score.w += 1
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
			score.c += iif(center = PROP_B, 2, 1) 'bonus point for blazon tile
			'loop edge tiles (and self) and try neighbours
			for iArea as long = 0 to 3
				if tile(x, y).prop(iArea) = prop then
					if vList.vTile(tileIdx).area(iArea) = 0 then 'not visited yet?
						vList.vTile(tileIdx).area(iArea) = 1 'set visited
						score.c += 1
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
			score.c += 1
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
