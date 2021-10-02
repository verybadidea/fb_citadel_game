type bitmap_header field = 1
	bfType          as ushort '0
	bfsize          as ulong  '2
	bfReserved1     as ushort '6
	bfReserved2     as ushort '8
	bfOffBits       as ulong  '10
	biSize          as ulong  '14
	biWidth         as ulong  '18
	biHeight        as ulong  '22
	biPlanes        as ushort
	biBitCount      as ushort
	biCompression   as ulong
	biSizeImage     as ulong
	biXPelsPerMeter as ulong
	biYPelsPerMeter as ulong
	biClrUsed       as ulong
	biClrImportant  as ulong
end type
