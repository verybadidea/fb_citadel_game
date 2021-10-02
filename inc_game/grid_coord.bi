type grid_coord
	dim as integer w, h 'width, height
	declare function getGridPos(mapPos as int2d) as int2d
	'declare function getGridPosXY(xMap as integer, yMap as integer) as int2d
	declare function getScrPos(gridPos as int2d, scrMapDist as int2d) as int2d
end type

'map -> grid, get grid / tile id for a position on map
function grid_coord.getGridPos(mapPos as int2d) as int2d
	dim as int2d gridPos
	gridPos.x = int(mapPos.x / w)
	gridPos.y = int(mapPos.y / h)
	return gridPos
end function

'grid -> screen, get screen postion center? of a grid position 
function grid_coord.getScrPos(gridPos as int2d, scrMapDist as int2d) as int2d
	dim as int2d scrPos
	scrPos.x = gridPos.x * w - scrMapDist.x
	scrPos.y = gridPos.y * h - scrMapDist.y
	return scrPos
end function


