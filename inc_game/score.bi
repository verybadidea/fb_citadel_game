type score_type
	dim as long r, c, w, a 'road, city, water, abby
	dim as long t 'temporary score for cities 
	dim as long n 'neigbour & abby score   
	dim as long delta, total
	declare sub clr()
	declare sub updateTotal()
end type

sub score_type.clr()
	r = 0 : c = 0 : w = 0 : a = 0
end sub

sub score_type.updateTotal()
	delta = (r + c + w + a + n)
	total += delta
end sub
