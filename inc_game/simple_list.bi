type simple_tile
	dim as long x, y
end type

type simple_list
	dim as simple_tile sTile(any)
	declare sub clr()
	declare function size() as long
	declare function addTile(x as long, y as long) as long
	declare function hasTile(x as long, y as long) as long
	declare sub addTileIfNew(x as long, y as long)
end type

sub simple_list.clr()
	erase sTile
end sub

function simple_list.size() as long
	return ubound(sTile) + 1
end function

function simple_list.addTile(x as long, y as long) as long
	dim as long ubNew = ubound(sTile) + 1
	redim preserve sTile(0 to ubNew)
	sTile(ubNew).x = x
	sTile(ubNew).y = y
	return ubNew
end function

'check if tile x,y in list, return tile index
function simple_list.hasTile(x as long, y as long) as long
	for i as long = 0 to ubound(sTile)
		if sTile(i).x = x and sTile(i).y = y then return i
	next
	return -1
end function

sub simple_list.addTileIfNew(x as long, y as long)
	if hasTile(x, y) < 0 then addTile(x, y)
end sub

'--- Test ----------------------------------------------------------------------

'~ dim as simple_list vList

'~ vList.addTile(1, 1)
'~ print vList.hasTile(1, 1)

'~ dim as visited_tile sTile
'~ sTile.x = 1
'~ sTile.y = 1
'~ print sTile.pos
'~ sTile.area(0) = 1
'~ print sTile.area(1)
