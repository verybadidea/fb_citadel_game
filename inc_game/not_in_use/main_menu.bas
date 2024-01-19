'--- menu subs -----------------------------------------------------------------

sub showHighScores()
	'bgImg.draw(bgImg.BG_DARK)
	scr.clearScreen(0)
	f1.printTextAk(SW \ 2, 60, "High scores (top 10)", FHA_CENTER)
	for i as integer = 0 to 9'NUM_HIGH_SCORES-1
		'f1.printTextAk(150, 140 + i * 40, scoreList.names(i), FHA_LEFT)
		'f1.printTextAk(550, 140 + i * 40, str(scoreList.high(i)), FHA_RIGHT)
	next
	do
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_QUIT) then exit do
		if rkey.isReleased(RKEY_ENTER) then exit do
		if rkey.isReleased(RKEY_SPACE) then exit do
		sleep 1
	loop
end sub

'-------------------------------------------------------------------------------

function inputHighScore() as string
	dim as string labelText = "Enter your name:  "
	dim as string inputText, fullText, key
	dim as double t = timer
	dim as integer cursorState = 0
	do
		key = inkey
		f1.inputText(inputText, key, 12)
		fullText = labelText + inputText
		if cursorState = 1 then fullText += "_" 
		screenlock
		'bgImg.draw(bgImg.BG_NORMAL)
		scr.clearScreen(0)
		f1.printTextAk(100, 100, "New high score (top 10)", FHA_LEFT)
		f1.printTextAk(100, 140, fullText, FHA_LEFT)
		screenunlock
		if timer > t then
			cursorState xor= 1
			t = timer + 0.5
		end if
		sleep 1, 1
	loop until key = chr(13) and len(inputText) > 0
	return inputText
end function

'-------------------------------------------------------------------------------

sub showLoad()
	'bgImg.draw(bgImg.BG_DARK)
	scr.clearScreen(0)
	f1.printTextAk(SW \ 2, 100, "To be implemented...", FHA_CENTER)
	do
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_QUIT) then exit do
		if rkey.isReleased(RKEY_ENTER) then exit do
		if rkey.isReleased(RKEY_SPACE) then exit do
		sleep 1
	loop
end sub

'-------------------------------------------------------------------------------
sub showSave()
	'bgImg.draw(bgImg.BG_DARK)
	scr.clearScreen(0)
	f1.printTextAk(SW \ 2, 100, "To be implemented...", FHA_CENTER)
	do
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_QUIT) then exit do
		if rkey.isReleased(RKEY_ENTER) then exit do
		if rkey.isReleased(RKEY_SPACE) then exit do
		sleep 1
	loop
end sub

'-------------------------------------------------------------------------------

sub showKeyConfig()
	'bgImg.draw(bgImg.BG_DARK)
	scr.clearScreen(0)
	f1.printTextAk(SW \ 2, 100, "To be implemented...", FHA_CENTER)
	f1.printTextAk(SW \ 2, 130, "For now, check the README.md", FHA_CENTER)
	do
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_QUIT) then exit do
		if rkey.isReleased(RKEY_ENTER) then exit do
		if rkey.isReleased(RKEY_SPACE) then exit do
		sleep 1
	loop
end sub

'-------------------------------------------------------------------------------

sub showHowToPlay()
	'bgImg.draw(bgImg.BG_DARK)
	scr.clearScreen(0)
	f1.printTextAk(SW \ 2, 100, "To be implemented...", FHA_CENTER)
	f1.printTextAk(SW \ 2, 130, "For now, check the README.md", FHA_CENTER)
	do
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_QUIT) then exit do
		if rkey.isReleased(RKEY_ENTER) then exit do
		if rkey.isReleased(RKEY_SPACE) then exit do
		sleep 1
	loop
end sub

'-------------------------------------------------------------------------------

function showMainMenu() as long
	dim as long quit = 0, selection = 0
	dim as string menuItem(...) = {_
		"HIGH SCORES", _
		"KEY CONFIG", _
		"HOW TO PLAY", _
		"-", _
		"NEW GAME", _
		"LOAD GAME", _
		"SAVE GAME", _
		"-", _
		"QUIT"}
	dim as string currentText
	do
		'handle input
		rkey.updateState() 'very important
		if rkey.isReleased(RKEY_UP) then
			if selection > 0 then
				selection -= 1
				if menuItem(selection) = "-" then selection -= 1
			end if
		end if
		if rkey.isReleased(RKEY_DOWN) then
			if selection < ubound(menuItem) then
				selection += 1
				if menuItem(selection) = "-" then selection += 1
			end if
		end if
		if rkey.isReleased(RKEY_ENTER) then
			select case selection
			case 0: showHighScores()
			case 1: showKeyConfig() 
			case 2: showHowToPlay()
			case 3
			case 4:
				'map.clean()
				gameLoop()
			case 5:
				showLoad()
				gameLoop()
			case 6: showSave()
			case 7
			case 8: quit = 1 'quit game
			end select
		end if
		if rkey.isReleased(RKEY_QUIT) then
			'selection = 4 : quit = 1
		end if
		screenlock
		scr.clearScreen(0)
		'bgImg.draw(bgImg.BG_NORMAL)
		f1.printTextAk(SW \ 2, 100, "A game without a name", FHA_CENTER)
		f1.printTextAk(SW \ 2, 130, "by badidea 2021", FHA_CENTER)
		for i as long = 0 to ubound(menuItem)
			if i = selection then
				currentText = "-> " + menuItem(i) + " <-"
			else
				currentText = menuItem(i)
			end if
			f1.printTextAk(SW \ 2, 270 + i * 30, currentText, FHA_CENTER)
		next
		screenunlock
		'sleep a bit
		sleep 1
	loop while quit = 0
	return 0
end function
