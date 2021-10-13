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


