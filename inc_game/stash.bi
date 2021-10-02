type stash_type
	dim as long cardId(any)
	declare function size() as integer
	declare function empty() as integer
	declare function push(newId as long) as integer
	declare function pop() as long
	declare function top() as long
	declare sub printAll() 
end type

function stash_type.size() as integer
	return ubound(cardId) + 1
end function

function stash_type.empty() as integer
	erase(cardId)
	return 0
end function

function stash_type.push(newId as long) as integer
	dim as integer ub = ubound(cardId)
	redim preserve cardId(ub + 1)
	cardId(ub + 1) = newId
	return ub + 1
end function

function stash_type.pop() as long
	dim as integer ub = ubound(cardId)
	dim as long retVal = -1 'list is empty
	if ub >= 0 then
		retVal = cardId(ub)
		if ub > 0 then
			redim preserve cardId(ub - 1)
		else
			erase cardId
		end if
	end if
	return retVal
end function

function stash_type.top() as long
	dim as integer ub = ubound(cardId)
	return cardId(ub)
end function

sub stash_type.printAll()
	for i as integer = 0 to ubound(cardId)
		print i & " - " & cardId(i)
	next
end sub
