sub panic(text as string)
	print "Panic: " & text
	getkey()
	end -1
end sub

sub imageKill(p_img as any ptr)
	imageDestroy(p_img)
	p_img = 0
end sub

