'triangular number sesies: 1,3,6,10,15,21,...
function triangular(n as integer) as integer
	return (n * (n + 1)) shr 1 '\2
end function

'-------------------------------------------------------------------------------

type score_type
	dim as long r, c, w, a 'road, city, water, abbey
	'dim as long br, bc, bw 'bunus for road, city, water
	'dim as long t 'temporary score for cities 
	dim as long n 'neigbour & abbey score   
	dim as long delta, total, old
	declare sub clr()
	declare sub updateTotal()
	declare function tilesGained() as long
	declare sub reset_()
end type

sub score_type.clr()
	r = 0 : c = 0 : w = 0 : a = 0
	'br = 0 : bc = 0 : bw = 0
end sub

sub score_type.updateTotal()
	delta = (r + c + w + a + n)
	total += delta
end sub

'note: resets after call
function score_type.tilesGained() as long
	dim as long retVal = total - old
	old = total
	return retVal
end function

sub score_type.reset_()
	clr()
	delta = 0
	total = 0
	old = 0
end sub
