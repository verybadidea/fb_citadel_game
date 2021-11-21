'doubly linked list

type card_node
	dim as card_node ptr pPrev, pNext
	dim as long id 'value
end type

type card_stack
	dim as card_node ptr pFirst, pLast 'bottom & top
	dim as long numCards
	declare function size() as integer
	declare function empty() as integer
	declare function pushFirst(newId as long) as integer
	declare function pushLast(newId as long) as integer
	declare function popFirst() as long
	declare function popLast() as long
	declare function getFirst() as long
	declare function getLast() as long
	declare sub printAll(direction as long) 
end type

function card_stack.size() as integer
	return numCards
	'~ return ubound(cardId) + 1
end function

function card_stack.empty() as integer
	'~ erase(cardId)
	return 0
end function

'add to begin of list
function card_stack.pushFirst(newId as long) as integer
	dim as card_node ptr pNew = allocate(sizeof(card_node))
	pNew->id = newId
	'if pFirst = 0 then 'list is empty, also: pLast = 0
	if numCards = 0 then
		pNew->pNext = 0
		pNew->pPrev = 0
		pLast = pNew
		pFirst = pNew
	else
		pNew->pPrev = 0
		pNew->pNext = pFirst 'point to old 'first'
		pFirst->pPrev = pNew 'doubly linked list!
		pFirst = pNew 'update 'first'
	end if
	numCards += 1
	return numCards
end function

'add to end of list
function card_stack.pushLast(newId as long) as integer
	dim as card_node ptr pNew = allocate(sizeof(card_node))
	pNew->id = newId
	'if pLast = 0 then 'list is empty, also: pFirst = 0
	if numCards = 0 then
		pNew->pNext = 0
		pNew->pPrev = 0
		pLast = pNew
		pFirst = pNew
	else
		pNew->pNext = 0
		pNew->pPrev = pLast
		pLast->pNext = pNew
		pLast = pNew
	end if
	numCards += 1
	return numCards
end function

'remove + return first of list
function card_stack.popFirst() as long
	dim as long retId = -1 'list is empty
	if numCards > 0 then
		dim as card_node ptr pCard = pFirst
		retId = pCard->id
		if numCards = 1 then
			pFirst = 0
			pLast = 0
		else
			pFirst = pCard->pNext
			pFirst->pPrev = 0
		end if
		deallocate(pCard) : pCard = 0
		numCards -= 1
	end if
	return retId
end function

'remove + return last of list
function card_stack.popLast() as long
	dim as long retId = -1 'list is empty
	if numCards > 0 then
		dim as card_node ptr pCard = pLast
		retId = pCard->id
		if numCards = 1 then
			pFirst = 0
			pLast = 0
		else
			pLast = pCard->pPrev
			pLast->pNext = 0
		end if
		deallocate(pCard) : pCard = 0
		numCards -= 1
	end if
	return retId
end function

function card_stack.getFirst() as long
	dim as long retId = -1 'list is empty
	if pFirst <> 0 then retId = pFirst->id
	return retId
end function

function card_stack.getLast() as long
	dim as long retId = -1 'list is empty
	if pLast <> 0 then retId = pLast->id
	return retId
end function

'+1 = first to last
sub card_stack.printAll(direction as long)
	dim as card_node ptr pCard
	if direction >= 0 then 'first to last
		pCard = pFirst
		while pCard
			print pCard->id
			pCard = pCard->pNext
		wend
	else
		pCard = pLast
		while pCard
			print pCard->id
			pCard = pCard->pPrev
		wend
	end if
end sub

'--- testcode ---

'~ dim as card_stack stash

'~ stash.pushLast(20)
'~ stash.pushLast(21)
'~ stash.pushLast(22)

'~ print stash.popFirst()
'~ print stash.popLast()
'~ stash.pushFirst(8)
'~ stash.pushLast(88)

'~ print
'~ print stash.size()
'~ print
'~ stash.printAll(0)
'~ print
'~ stash.printAll(-1)
