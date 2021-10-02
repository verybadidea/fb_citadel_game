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

type tile_type
	dim as long id
	dim as long rot 'rotation: 0...3
	'dim as ubyte visited(0 to 4) 'sides + center
	'dim as ubyte property(0 to 4) 'sides + center
end type

#define NO_TILE type<tile_type>(-1, -1)

'class wrapper for game

type tile_map
	dim as tile_type tile(any, any) 'row, col
	declare sub clean()
	declare function getTile(row as long, col as long) as tile_type
	declare sub setTile(row as long, col as long, tile_ as tile_type)
	declare function getTile overload(pos_ as int2d) as tile_type
	declare sub setTile overload(pos_ as int2d, tile_ as tile_type)
end type

sub tile_map.clean()
	'''free...
end sub

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

'test

'~ dim as tile_map tGrid

'~ tGrid.setTile(0, 0, -1) ' start tile
'~ tGrid.setTile(-5, 2, 3)
'~ print tGrid.tile(0,0)
'~ print "col bounds: " & lbound(tGrid.tile, 1) & " to " & ubound(tGrid.tile, 1)
'~ print "row bounds: " & lbound(tGrid.tile, 2) & " to " & ubound(tGrid.tile, 2)
