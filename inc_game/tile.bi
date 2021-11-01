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

const as long AREA_UP = 0
const as long AREA_RI = 1
const as long AREA_DN = 2
const as long AREA_LE = 3
const as long AREA_CT = 4

'basic tile poperties for map
type tile_type
	dim as long id
	dim as long rot 'rotation: 0...3
	dim as ubyte prop(0 to 4) 'top, right, bottom, left, center/bonus
	'declare sub fromString(propStr as string)
	'declare sub fromFileName(propStr as string)
	'declare function getProp(prop as long, rot as long) as long
	declare sub rotate(direction as long)
end type

#define NO_TILE type<tile_type>(-1, -1)

sub tile_type.rotate(direction as long)
	if direction > 0 then
		rot += 1
		if rot >= 4 then rot = 0
		dim as long temp = prop(3)
		prop(3) = prop(2)
		prop(2) = prop(1)
		prop(1) = prop(0)
		prop(0) = temp
	elseif direction < 0 then
		rot -= 1
		if rot < 0 then rot = 3
		dim as long temp = prop(0)
		prop(0) = prop(1)
		prop(1) = prop(2)
		prop(2) = prop(3)
		prop(3) = temp
	end if
end sub


