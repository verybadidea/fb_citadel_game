'triangular number sesies: 1,3,6,10,15,21,...
function triangular(n as integer) as integer
	return (n * (n + 1)) shr 1 '\2
end function

'~ function score(rawCount as integer)
	'~ return rawCount + triangular(rawCount \ 10) as integer
'~ end function

'-------------------------------------------------------------------------------

type score_type
	dim as long r, c, w, a 'road, city, water, abbey
	dim as long br, bc, bw 'bunus for road, city, water
	dim as long t 'temporary score for cities 
	dim as long n 'neigbour & abbey score   
	dim as long delta, total, old
	declare sub clr()
	declare sub updateTotal()
	declare function tilesGained() as long
end type

sub score_type.clr()
	r = 0 : c = 0 : w = 0 : a = 0
	br = 0 : bc = 0 : bw = 0
end sub

sub score_type.updateTotal()
	'old = total
	'bonus points for larger structures with limiter / cap
	bc = iif(c < 290, triangular(c \ 10), cint(c * 0.5)) 'city bonus
	br = iif(r < 170, triangular(r \ 5), cint(r * 2.5)) 'road network bonus
	bw = iif(w < 170, triangular(w \ 5), cint(w * 2.5)) 'waterway bonus
	'add all
	c += bc : r += br : w += bw
	delta = (r + c + w + a + n)
	total += delta
end sub

'note: resets after call
function score_type.tilesGained() as long
	'tiles = nowpoints\10 - prevpoints\10 
	'8\10 = 0, (8+9=17)\10 = 1 -> +1 tile
	'12\10 = 1, (12+9=21)\10 = 2 -> +1 tile
	dim as long retVal = (total \ 10) - (old \ 10)
	old = total
	return retVal
end function
