const as long TILE_L = 0 'large
const as long TILE_M = 1 'medium
const as long TILE_S = 2 'small

type tile_collection
	dim as long numTiles 'unique tiles
	dim as image_buffer_type imgBuf
	dim as tile_type tile(any)
	dim as image_type ptr pImg(any, any, any) 'id, rotation, size
	dim as long occurance(any)
	dim as long fullSetCount 'includes doubles, for propability
	dim as long fullSet(any) 'array of id's
	declare function load(imagePath as string) as long
	declare function getRandomId() as long
	declare function getRandomDistId() as long
end type

'image filename format: nn_tldrc_ll_o.bmp
'                       12345678901234
function tile_collection.load(imagePath as string) as long
	numTiles = imgBuf.loadDir(imagePath)
	if numTiles <= 0 then return -1
	redim pImg(0 to numTiles - 1, 0 to 3, 0 to 2) 'id, rotation, size
	'copy buffer & crop to array's first image
	dim as trim_type border = type(6, 6, 6, 6)
	for iImg as integer = 0 to numTiles - 1
		pImg(iImg, 0, 0) = imgBuf.image(iImg).btrim(border)
	next
	'create rotated versions of each image
	for iImg as integer = 0 to numTiles - 1
		for iRot as integer = 1 to 3
			pImg(iImg, iRot, 0) = pImg(iImg, iRot - 1, 0)->rotateRight
		next
	next
	'create small & tiny versions, for each image & rotation
	for iImg as integer = 0 to numTiles - 1
		for iRot as integer = 0 to 3
			pImg(iImg, iRot, 1) = pImg(iImg, iRot, 0)->shrink
			pImg(iImg, iRot, 2) = pImg(iImg, iRot, 1)->shrink
		next
	next
	'allocate memory for tile & occurance array
	redim tile(0 to numTiles - 1)
	redim occurance(0 to numTiles - 1)
	'get tile properties from file name
	for iTile as long = 0 to ubound(tile)
		tile(iTile).id = iTile
		dim as string shortName = getFileName(imgBuf.imageFileName(iTile))
		if mid(shortName, 3, 1) <> "_" then panic("tile_collection.load, invalid file name")
		if mid(shortName, 9, 1) <> "_" then panic("tile_collection.load, invalid file name")
		if mid(shortName, 12, 1) <> "_" then panic("tile_collection.load, invalid file name")
		if mid(shortName, 14, 1) <> "." then panic("tile_collection.load, invalid file name")
		for iProp as long = 0 to 4
			select case mid(shortName, iProp + 4, 1)
			case "X": tile(iTile).prop(iProp) = PROP_X
			case "G": tile(iTile).prop(iProp) = PROP_G
			case "R": tile(iTile).prop(iProp) = PROP_R
			case "C": tile(iTile).prop(iProp) = PROP_C
			case "W": tile(iTile).prop(iProp) = PROP_W
			case "A": tile(iTile).prop(iProp) = PROP_A
			case "B": tile(iTile).prop(iProp) = PROP_B
			end select
			'print tile(iTile).prop(iProp) 'DEBUG
		next
		tile(iTile).link = val("&O" & mid(shortName, 10, 2))
		occurance(iTile) = val(mid(shortName, 13, 1))
		fullSetCount += occurance(iTile)
	next
	'fill occurance array
	dim as long iSet = 0
	redim fullSet(0 to fullSetCount - 1)
	for iTile as long = 0 to ubound(tile) 'loop unique tiles
		for iOcc as long = 0 to occurance(iTile) - 1
			fullSet(iSet) = iTile
			iSet += 1
		next
	next
	return numTiles
end function

function tile_collection.getRandomId() as long
	return int(rnd() * (numTiles - 1)) + 1 'skip first tile
end function

'using tile occurance in set
function tile_collection.getRandomDistId() as long
	return fullSet(int(rnd() * fullSetCount))
end function
