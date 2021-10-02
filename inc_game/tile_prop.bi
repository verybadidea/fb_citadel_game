const as long PROP_X = 0 'none
const as long PROP_G = 1 'grass
const as long PROP_R = 2 'road
const as long PROP_C = 3 'city
const as long PROP_W = 4 'water
const as long PROP_A = 5 'abby/citadel
const as long PROP_B = 6 'blazon

const as long PROP_UP = 0
const as long PROP_RI = 1
const as long PROP_DN = 2
const as long PROP_LE = 3
const as long PROP_CT = 4

type tile_prop
	dim as long area(0 to 4) 'top/up, right, bottom/down, left, center/bonus
	dim as long occurance
	declare sub fromString(propStr as string)
	declare sub fromFileName(propStr as string)
	declare function getProp(area as long, rot as long) as long
end type

sub tile_prop.fromString(propStr as string)
	if len(propStr) <> 6 then panic("tile_prop.fromString")
	for i as long = 0 to 4
		select case mid(propStr, i + 1, 1)
		case "X": area(i) = PROP_X
		case "G": area(i) = PROP_G
		case "R": area(i) = PROP_R
		case "C": area(i) = PROP_C
		case "W": area(i) = PROP_W
		case "A": area(i) = PROP_A
		case "B": area(i) = PROP_B
		end select
	next
	occurance = val(mid(propStr, 6, 1))
end sub

sub tile_prop.fromFileName(propStr as string)
	if mid(propStr, 3, 1) <> "_" then panic("tile_prop.fromFileName")
	if mid(propStr, 10, 1) <> "." then panic("tile_prop.fromFileName")
	this.fromString(mid(propStr, 4, 6))
end sub

function tile_prop.getProp(side as long, rot as long) as long
	if side < 0 or side > 4 then panic("tile_prop.getProp")
	if rot < 0 or rot > 3 then panic("tile_prop.getProp")
	dim as long index = side - rot
	'if index >= 4 then index -= 4
	if index < 0 then index += 4
	return area(index)
end function
