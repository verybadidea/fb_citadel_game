const as long PROP_X = 0 'none
const as long PROP_G = 1 'grass
const as long PROP_R = 2 'road
const as long PROP_C = 3 'city
const as long PROP_W = 4 'water
const as long PROP_A = 5 'abbey
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

const as long LINK_TR = &o01
const as long LINK_RB = &o02
const as long LINK_BL = &o04
const as long LINK_LT = &o10
const as long LINK_TB = &o20
const as long LINK_LR = &o40

'rotate right, rightmost 4 bits of a byte
#define rorb4(value) _
	((value and &hF0) or ((value and &h0E) shr 1) or ((value and &h01) shl 3))

'rotate left, rightmost 4 bits of a byte
#define rolb4(value) _
	((value and &hF0) or ((value and &h08) shr 3) or ((value and &h07) shl 1))

'swap bit 4 & 5 of a byte
#define swapb45(value) _
	((value and &hCF) or ((value and &h10) shl 1) or ((value and &h20) shr 1)) 'hex!

'basic tile poperties for map
type tile_type field = 4 '--> 16 bytes
	dim as long id
	dim as long rot 'rotation: 0...3
	dim as ubyte prop(0 to 4) 'top, right, bottom, left, center/bonus
	dim as ubyte link
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
		link = swapb45(rolb4(link))
	elseif direction < 0 then
		rot -= 1
		if rot < 0 then rot = 3
		dim as long temp = prop(0)
		prop(0) = prop(1)
		prop(1) = prop(2)
		prop(2) = prop(3)
		prop(3) = temp
		link = swapb45(rorb4(link))
	end if
end sub

dim shared as ubyte linkBitmask(0 to 3, 0 to 3) = {_
	{&o00, &o01, &o20, &o10},_
	{&o01, &o00, &o02, &o40},_
	{&o20, &o02, &o00, &o04},_
	{&o10, &o40, &o04, &o00}}

