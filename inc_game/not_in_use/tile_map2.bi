#define array_size(_a_) (ubound(_a_) - lbound(_a_) + 1)

#macro redimpreserve1d(a, d) 'a = 1d-i, d = dimension
scope
	redim as typeof(a) copy(d)
	for i as integer = d
		if i >= lbound(a) and i <= ubound(a) then
			copy(i) = a(i)
		end if
	next
	redim (a)(d)
	for i as integer = d
		a(i) = copy(i)
	next
end scope
#endmacro

'--- row_type ------------------------------------------------------------------

type row_type
	dim as tile_type tile(any)
end type

'--- list_of_rows --------------------------------------------------------------

type tile_map
	dim as row_type row(any) 'start with an 0-length list of pointers
	declare sub setTile(iRow as long, iCol as long, value as long)
	declare function getTile(iRow as long, iCol as long) as long
	declare sub printme()
end type

'set value, expands storage if needed
sub tile_map.setTile(iRow as long, iCol as long, value as long)
	dim as long lbRow = lbound(row)
	dim as long ubRow = ubound(row)
	dim as long resize = 0
	if iRow < lbRow then lbRow = iRow : resize = 1
	if iRow > ubRow then ubRow = iRow : resize = 1
	if resize = 1 then
		redimpreserve1d(row, lbRow to ubRow) 'new line needed due to macro
	end if
	dim as long lbCol = lbound(row(iRow).tile)
	dim as long ubCol = ubound(row(iRow).tile)
	if iCol < lbCol then lbCol = iCol : resize = 2
	if iCol > ubCol then ubCol = iCol : resize = 2
	if resize = 2 then
		if array_size(row(iRow).tile) <= 0 then
			redimpreserve1d(row(iRow).tile, iCol to iCol)
		else
			redimpreserve1d(row(iRow).tile, lbCol to ubCol)
		end if
	end if
	row(iRow).tile(iCol) = value
end sub

function tile_map.getTile(iRow as long, iCol as long) as long
	if (iRow < lbound(row)) or (iRow > ubound(row)) then return -1
	if (iCol < lbound(row(iRow).tile)) or (iCol > ubound(row(iRow).tile)) then return -2
	return row(iRow).tile(iCol)
end function

sub tile_map.printme()
	dim as long minTileLb = &h7FFFFFFF, maxTileUb = &h80000000
	for iRow as long = lbound(row) to ubound(row)
		if lbound(row(iRow).tile) < minTileLb then minTileLb = lbound(row(iRow).tile)
		'if ubound(row(iRow).tile) < maxTileUb then maxTileUb = ubound(row(iRow).tile)
	next
	for iRow as long = lbound(row) to ubound(row)
		print space((lbound(row(iRow).tile) - minTileLb) - 1);
		for iTile as long = lbound(row(iRow).tile) to ubound(row(iRow).tile)
			print row(iRow).tile(iTile);
		next
		print
	next
	print "-----------------"
end sub
