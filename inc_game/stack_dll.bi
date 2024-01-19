'doubly linked list

type card_node
	dim as card_node ptr pPrev, pNext
	dim as long id 'value
end type

type card_stack
	dim as card_node ptr pFirst, pLast 'bottom & top
	dim as long numCards
	declare function size() as integer
	declare function reset_() as integer
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

function card_stack.reset_() as integer
	'erase(cardId)
	while numCards > 0
		popFirst()
	wend
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

'-------------------------------------------------------------------------------

type multi_stack
	dim as long stackMask = &b0001 'numStack = 1, 
	dim as card_stack stack(0 to 3)
	declare sub reset_()
	declare sub addRndCards(iStack as long, numCards as long, tileSet as tile_collection)
	declare function numStack() as long
	declare function saveToDisk(fileNum as integer) as long
	declare function loadFromDisk(fileNum as integer) as long
end type

sub multi_stack.reset_()
	stackMask = &b0001
	for i as long = 0 to ubound(stack)
		stack(i).reset_()
	next
end sub

sub multi_stack.addRndCards(iStack as long, numCards as long, tileSet as tile_collection)
	for i as integer = 0 to numCards - 1
		'stack.push(tileSet.getRandomId())
		stack(iStack).pushFirst(tileSet.getRandomDistId()) 'top = first
		'stack(0).pushFirst(15)
	next
end sub

function multi_stack.numStack() as long
	dim as long count = &b0001 'first one always there
	for i as long = 1 to ubound(stack)
		if bit(stackMask, i) then count += 1
	next
	return count
end function

function multi_stack.saveToDisk(fileNum as integer) as long
	put #fileNum, , stackMask
	for iStack as long = 0 to ubound(stack)
		put #fileNum, , stack(iStack).numCards
		'loop cards, do not pop
		dim as long count = 0
		dim as card_node ptr pCard = stack(iStack).pFirst
		while pCard <> 0
			put #fileNum, , pCard->id
			count += 1
			pCard = pCard->pNext
		wend 
		'logger.add(str(count) & "," & str(stack(iStack).numCards))
	next
	return 0
end function

function multi_stack.loadFromDisk(fileNum as integer) as long
	get #fileNum, , stackMask
	for iStack as long = 0 to ubound(stack)
		stack(iStack).reset_()
		dim as long numCards, id
		get #fileNum, , numCards
		for iCard as long = 0 to numCards - 1
			get #fileNum, , id
			stack(iStack).pushLast(id)
		next
		'logger.add(str(numCards) & "," & str(stack(iStack).numCards)) & "," & str(stack(iStack).size())
	next
	return 0
end function
