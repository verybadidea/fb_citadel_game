sub panic(text as string)
	screen 0
	print "Panic: " & text
	getkey()
	end -1
end sub

sub imageKill(p_img as any ptr)
	imageDestroy(p_img)
	p_img = 0
end sub

#macro setbit(value, bitnum)
	value or= (1 shl bitnum)
#endmacro

#define max(a, b)_
	(iif((a) > (b), (a), (b)))

#define min(a, b)_
	(iif((a) < (b), (a), (b)))
