type menu_entry
	dim as long selectable
	dim as long retVal, optVal
	dim as string text
end type

type menu_type
	dim as long lastSel 'previously selected entry
	dim as menu_entry menuEntry(any)
	declare sub add(selectable as long, retVal as long, optVal as long, text as string)
	declare function firstSelectable() as long
	declare function lastItem() as long
	declare function findItemWithRetVal(matchVal as long) as long
end type

sub menu_type.add(selectable as long, retVal as long, optVal as long, text as string)
	dim as menu_entry newEntry '= type(text, selectable, retVal, optVal) 'compiler bug, does not work
	with newEntry
		.text = text
		.selectable = selectable
		.retVal = retVal
		.optVal = optVal
	end with
	dim as integer ub = ubound(menuEntry)
	redim preserve menuEntry(ub + 1)
	menuEntry(ub + 1) = newEntry
end sub

function menu_type.firstSelectable() as long
	for i as long = 0 to ubound(menuEntry)
		if menuEntry(i).selectable <> 0 then return i
	next
	return -1 'nothing
end function

'must always be selectable, else a lastSelectable() implementation is also needed
function menu_type.lastItem() as long
	return ubound(menuEntry)
end function

'purposure: for selecting an entry, e.g. select 'continue' after exiting 'new game'
function menu_type.findItemWithRetVal(matchVal as long) as long
	dim as long menuIdx = lastItem() 'return last if no match
	for i as long = firstSelectable() to lastItem()
		if matchVal = menuEntry(i).retVal then return i
	next
	return menuIdx
end function

'-------------------------------------------------------------------------------

'menus
enum MENU_ID
	MENU_ID_MAIN
	MENU_ID_QUIT_CONF
	MENU_ID_SHOW_HIGH
	MENU_ID_SHOW_KEY
	MENU_ID_SHOW_HELP
	MENU_ID_SHOW_SAVE
	MENU_ID_SHOW_LOAD
	MENU_ID_LIST_TERM 'list terminator
end enum

'return values
enum MENU_RET
	MENU_RET_INVALID
	MENU_RET_SHOW_MAIN
	MENU_RET_SHOW_HIGH
	MENU_RET_SHOW_KEY
	MENU_RET_SHOW_HELP
	MENU_RET_NEW_GAME
	MENU_RET_SHOW_LOAD
	MENU_RET_SHOW_SAVE
	MENU_RET_CONT_GAME
	MENU_RET_QUIT_GAME
	MENU_RET_QUIT_CONF
	MENU_RET_LOAD_MAP
	MENU_RET_SAVE_MAP
	'MENU_RET_QUIT_CONF
end enum

'-------------------------------------------------------------------------------

dim as menu_type menu(MENU_ID_LIST_TERM - 1) 'selectable, retVal, optVal, text

'menu: main entries
menu(MENU_ID_MAIN).add(0, 0, 0, "A game without a name")
menu(MENU_ID_MAIN).add(0, 0, 0, "by badidea 2022")
menu(MENU_ID_MAIN).add(0, 0, 0, "")
menu(MENU_ID_MAIN).add(0, 0, 0, "")
menu(MENU_ID_MAIN).add(0, 0, 0, "")
menu(MENU_ID_MAIN).add(1, MENU_RET_SHOW_HIGH, 0, "HIGH SCORES")
menu(MENU_ID_MAIN).add(1, MENU_RET_SHOW_KEY, 0, "KEY CONFIG")
menu(MENU_ID_MAIN).add(1, MENU_RET_SHOW_HELP, 0, "HOW TO PLAY")
menu(MENU_ID_MAIN).add(0, 0, 0, "")
menu(MENU_ID_MAIN).add(1, MENU_RET_CONT_GAME, 0, "CONTINUE GAME")
menu(MENU_ID_MAIN).add(1, MENU_RET_SHOW_SAVE, 0, "SAVE GAME")
menu(MENU_ID_MAIN).add(1, MENU_RET_NEW_GAME, 0, "NEW GAME")
menu(MENU_ID_MAIN).add(1, MENU_RET_SHOW_LOAD, 0, "LOAD GAME")
menu(MENU_ID_MAIN).add(0, 0, 0, "")
menu(MENU_ID_MAIN).add(1, MENU_RET_QUIT_GAME, 0, "QUIT")

'menu: quit confirmation
menu(MENU_ID_QUIT_CONF).add(0, 0, 0, "Sure quit?")
menu(MENU_ID_QUIT_CONF).add(0, 0, 0, "")
menu(MENU_ID_QUIT_CONF).add(1, MENU_RET_QUIT_CONF, 0, "Yes")
menu(MENU_ID_QUIT_CONF).add(1, MENU_RET_SHOW_MAIN, 0, "No")

'menu: high score entries (back + 10 * score)
menu(MENU_ID_SHOW_HIGH).add(0, 0, 0, "High scores (top 10)")
menu(MENU_ID_SHOW_HIGH).add(0, 0, 0, "")
for i as integer = 0 to 9
	menu(MENU_ID_SHOW_HIGH).add(0, 0, 0, "---")
next
menu(MENU_ID_SHOW_HIGH).add(0, 0, 0, "")
menu(MENU_ID_SHOW_HIGH).add(1, MENU_RET_SHOW_MAIN, 0, "BACK")

'menu: key configuration
menu(MENU_ID_SHOW_KEY).add(0, 0, 0, "Key configuration")
menu(MENU_ID_SHOW_KEY).add(0, 0, 0, "")
for i as integer = 0 to ubound(rkey.scancode)
	menu(MENU_ID_SHOW_KEY).add(0, 0, 0, str(rkey.scancode(i)))
next
menu(MENU_ID_SHOW_KEY).add(0, 0, 0, "")
menu(MENU_ID_SHOW_KEY).add(1, MENU_RET_SHOW_MAIN, 0, "BACK")

'menu: how to play
menu(MENU_ID_SHOW_HELP).add(0, 0, 0, "To be implemented...")
menu(MENU_ID_SHOW_HELP).add(0, 0, 0, "For now, check the README.md")
menu(MENU_ID_SHOW_HELP).add(0, 0, 0, "")
menu(MENU_ID_SHOW_HELP).add(1, MENU_RET_SHOW_MAIN, 0, "BACK")

'menu: save selection
menu(MENU_ID_SHOW_SAVE).add(0, 0, 0, "SAVE GAME")
menu(MENU_ID_SHOW_SAVE).add(0, 0, 0, "Select slot")
menu(MENU_ID_SHOW_SAVE).add(0, 0, 0, "")
for i as integer = 0 to NUM_SAVE-1 '5 slots is enough
	menu(MENU_ID_SHOW_SAVE).add(1, MENU_RET_SAVE_MAP, i, "<empty>")
next
menu(MENU_ID_SHOW_SAVE).add(0, 0, 0, "")
menu(MENU_ID_SHOW_SAVE).add(1, MENU_RET_SHOW_MAIN, 0, "BACK")

'menu: load selection
menu(MENU_ID_SHOW_LOAD).add(0, 0, 0, "LOAD GAME")
menu(MENU_ID_SHOW_LOAD).add(0, 0, 0, "Select slot")
menu(MENU_ID_SHOW_LOAD).add(0, 0, 0, "")
for i as integer = 0 to NUM_SAVE-1 '5 slots is enough
	menu(MENU_ID_SHOW_LOAD).add(1, MENU_RET_LOAD_MAP, i, "<empty>")
next
menu(MENU_ID_SHOW_LOAD).add(0, 0, 0, "")
menu(MENU_ID_SHOW_LOAD).add(1, MENU_RET_SHOW_MAIN, 0, "BACK")

'-------------------------------------------------------------------------------

'enable/disable save & continue in main menu
sub enableSaveCont(menu() as menu_type, flag as boolean)
	dim as long menuId = MENU_ID_MAIN
	dim as long menuIdx, value = iif(flag, 0, -1)
	menuIdx = menu(menuId).findItemWithRetVal(MENU_RET_SHOW_SAVE)
	menu(menuId).menuEntry(menuIdx).optVal = value
	menuIdx = menu(menuId).findItemWithRetVal(MENU_RET_CONT_GAME)
	menu(menuId).menuEntry(menuIdx).optVal = value
end sub

'populate save game fields
sub updateSaveLoad(menu() as menu_type, menuId as long)
	for i as long = 0 to NUM_SAVE-1
		dim as string fileName = saveFileName(i)
		with menu(menuId).menuEntry(i + 3)
			if fileExists(fileName) then
				.text = "#" & str(i) & "  " & _
					Format(FileDateTime(fileName), "yyyy-mm-dd / hh:mm:ss") & "  "  & _
					Format(fileLen(filename) / 1024, "0.0 kB")
				if menuId = MENU_ID_SHOW_LOAD then .optVal = i
			else
				.text = "<empty>"
				if menuId = MENU_ID_SHOW_LOAD then .optVal = -1 'disable load
			end if
		end with
	next
end sub

function menuLoop(menu() as menu_type, menuId as long) as long
	dim as long selection = menu(menuId).lastSel
	selection = MAX(menu(menuId).firstSelectable, selection)
	selection = MIN(menu(menuId).lastItem, selection)
	'selection = menu(menuId).firstSelectable
	dim as long retVal = 0
	while retVal = 0
		'handle input
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_TOP) then
			selection = menu(menuId).firstSelectable
		end if
		if rkey.isReleased(RKEY_BOTTOM) then
			selection = menu(menuId).lastItem() 'last item must always be selectable
		end if
		if rkey.isReleased(RKEY_UP) then
			if selection > menu(menuId).firstSelectable then
				selection -= 1
				if menu(menuId).menuEntry(selection).selectable = 0 then selection -= 1
			end if
		end if
		if rkey.isReleased(RKEY_DOWN) then
			if selection < menu(menuId).lastItem() then
				selection += 1
				if menu(menuId).menuEntry(selection).selectable = 0 then selection += 1
			end if
		end if
		if rkey.isReleased(RKEY_ENTER) then
			if menu(menuId).menuEntry(selection).optVal >= 0 then '-1 is disabled
				retVal = menu(menuId).menuEntry(selection).retVal
			end if
		end if
		if rkey.isReleased(RKEY_QUIT) then 'perform last menu action on 'escape' key  
			dim as integer last = menu(menuId).lastItem()
			retVal = menu(menuId).menuEntry(last).retVal
		end if
		screenlock
		scr.clearScreen(0)
		'bgImg.draw(bgImg.BG_NORMAL)
		for i as long = 0 to menu(menuId).lastItem()
			dim as string currentText = menu(menuId).menuEntry(i).text
			if i = selection then currentText = "-> " + currentText + " <-"
			f1.printTextAk(SW \ 2, 100 + i * 30, currentText, FHA_CENTER)
		next
		screenunlock
		sleep 1
	wend
	menu(menuId).lastSel = selection
	return retVal
end function
