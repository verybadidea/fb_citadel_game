type visited_tile
	'union
		'dim as longint pos
		'type
			dim as long x, y
		'end type
	'end union
	dim as ubyte area(0 to 5) '<-- TODO: change to bitfield
end type

type visited_list
	dim as visited_tile vTile(any)
	declare sub clr()
	declare function addTile(x as long, y as long) as long
	declare function hasTile(x as long, y as long) as long
	declare function getTile(x as long, y as long) as long
	declare sub setVisit(x as long, y as long, iArea as long)
	'declare sub setVisitIdx(tileIdx as long, iArea as long)
	declare function isVisited(x as long, y as long, iArea as long) as long
end type

sub visited_list.clr()
	erase vTile
end sub

function visited_list.addTile(x as long, y as long) as long
	dim as long ubNew = ubound(vTile) + 1
	redim preserve vTile(0 to ubNew)
	vTile(ubNew).x = x
	vTile(ubNew).y = y
	return ubNew
end function

'check if tile x,y in list
'return tile index
function visited_list.hasTile(x as long, y as long) as long
	'dim as longint checkPos = (clngint(y) shl 32) or x
	for i as long = 0 to ubound(vTile)
		'if checkPos = vTile(i).pos then return i
		if vTile(i).x = x and vTile(i).y = y then return i
	next
	return -1
end function

'like touch. Get index, add tile if needed.
function visited_list.getTile(x as long, y as long) as long
	dim as long tileIdx = hasTile(x, y)
	if tileIdx < 0 then tileIdx = addTile(x, y)
	return tileIdx
end function

'return -1 = noTile, 0 = not visited, 1 = visited
function visited_list.isVisited(x as long, y as long, iArea as long) as long
	dim as long iTile = hasTile(x, y)
	if iTile < 0 then
		return -1
	else
		return vTile(iTile).area(iArea)
	end if
end function

sub visited_list.setVisit(x as long, y as long, iArea as long)
	dim as long tileIdx = getTile(x, y)
	vTile(tileIdx).area(iArea) = 1
end sub

'sub visited_list.setVisitIdx(tileIdx as long, iArea as long)
	'vTile(tileIdx).area(iArea) = 1
'end sub

'--- Test ----------------------------------------------------------------------

'~ dim as visited_list vList

'~ vList.addTile(1, 1)
'~ print vList.hasTile(1, 1)

'~ dim as visited_tile vTile
'~ vTile.x = 1
'~ vTile.y = 1
'~ print vTile.pos
'~ vTile.area(0) = 1
'~ print vTile.area(1)
