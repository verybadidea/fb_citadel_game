'-------------------------------------------------------------------------------

'#include "../../_code_lib_new_/logger_v01.bi"
'dim shared as logger_type logger = logger_type("gamelog.txt", 5, 1.0)
'logger.add(0, 0, 0, "Start")

'-------------------------------------------------------------------------------

#include "fbgfx.bi"
#include "vbcompat.bi"

#include "inc_lib/general.bi"
#include "inc_lib/registered_key_02.bi"
#include "inc_lib/mouse_v02.bi"
#include "inc_lib/screen_v03.bi"
#include "inc_lib/image_buffer_v03.bi"
#include "inc_lib/font_v02.bi"
#include "inc_lib/simple_logger_v01.bi"

dim shared as logger_type logger = logger_type("datalog.txt")
'var shared logger = logger_type("datalog.txt")

#include "inc_game/grid_coord.bi"
#include "inc_game/tile.bi"
#include "inc_game/score.bi"
#include "inc_game/simple_list.bi"
#include "inc_game/visited_list.bi"
#include "inc_game/tile_collection.bi"
#include "inc_game/tile_map1.bi"
#include "inc_game/buttons.bi"
#include "inc_game/stack_dll.bi"

const SW = 960, SH = 720
dim shared as screen_type scr = screen_type(SW, SH, 0) 'fb.GFX_ALPHA_PRIMITIVES
scr.activate() 'set screen

'--- load & set font -----------------------------------------------------------

dim shared as font_type f1
dim as string fontFileName = "images/Berlin_sans32b.bmp"
f1.manualTrim(0, 2, 0, 0) 'for fixed width fwprint
if f1.load(fontFileName, 16, 16) <> 0 then panic(fontFileName & " not found")
f1.autoTrim()
f1.setProp(8, -2, FDM_ALPHA) 'minSpacing, offsetSpacing, drawMode

'--- set keys ------------------------------------------------------------------

enum RKEY_ENUM
	RKEY_NONE 'invalid key
	RKEY_QUIT
	RKEY_LEFT
	RKEY_RIGHT
	RKEY_UP
	RKEY_DOWN
	RKEY_ROTATE
	RKEY_ZOOM_IN
	RKEY_ZOOM_OUT
	RKEY_ENTER 'for menu
	RKEY_TOP 'for menu
	RKEY_BOTTOM 'for menu
end enum

dim shared as registered_key rkey
rkey.add(FB.SC_ESCAPE) 'RKEY_QUIT = 1
rkey.add(FB.SC_LEFT)
rkey.add(FB.SC_RIGHT)
rkey.add(FB.SC_UP)
rkey.add(FB.SC_DOWN)
rkey.add(FB.SC_SPACE) 'RKEY_ROTATE = 6
rkey.add(FB.SC_MINUS) '-/_
rkey.add(FB.SC_EQUALS) '=/+
rkey.add(FB.SC_ENTER) 'select
rkey.add(FB.SC_PAGEUP)
rkey.add(FB.SC_PAGEDOWN)

'--- load tiles & set properties -----------------------------------------------

dim shared as tile_collection tileSet
if tileSet.load("tiles") <= 0 then panic("load tiles")

'--- other images --------------------------------------------------------------

dim shared as image_buffer_type imgBufImages
if imgBufImages.loadDir("images") <= 0 then panic("load images")

const IMG_QUESTION = 0
const IMG_CHECK = 1
const IMG_CROSS = 2
const IMG_STAR = 3
const IMG_STAR_GLOW = 4
const IMG_SPARKLE = 5

dim shared as image_type ptr pImgQu, pImgOk, pImgNok 'check & cross
pImgQu = imgBufImages.image(IMG_QUESTION).shrink
pImgOk = imgBufImages.image(IMG_CHECK).shrink
pImgNok = imgBufImages.image(IMG_CROSS).shrink

'-------------------------------------------------------------------------------

const NUM_SAVE = 5

function saveFileName(i as long) as string
	return "save/savegame" & str(i) & ".bin"
end function

'-------------------------------------------------------------------------------

#include "inc_game/game_loop.bi"
#include "inc_game/main_menu.bi"

dim as game_type game
logger.add("game started")

'print showMainMenu()
dim as long menuId = MENU_ID_MAIN, menuVal = MENU_RET_SHOW_MAIN
dim as long optVal = -1, lastSel = -1
dim as long quit = 0

enableSaveCont(menu(), false) 'update main menu list
'a big switch depending on result from menuLoop()
while quit = 0 
	menuVal = menuLoop(menu(), menuId)
	select case menuVal
		case MENU_RET_SHOW_MAIN
			menuId = MENU_ID_MAIN
		case MENU_RET_SHOW_HIGH
			menuId = MENU_ID_SHOW_HIGH
		case MENU_RET_SHOW_KEY
			menuId = MENU_ID_SHOW_KEY
		case MENU_RET_SHOW_HELP
			menuId = MENU_ID_SHOW_HELP
		case MENU_RET_CONT_GAME
			game.loop_()
			menuId = MENU_ID_MAIN 'NO, display result / enter highscore first
		case MENU_RET_NEW_GAME
			game.init()
			game.loop_()
			enableSaveCont(menu(), true)
			menuId = MENU_ID_MAIN 'CHANGE LATER!, display result / enter highscore first
			menu(menuId).lastSel = menu(menuId).findItemWithRetVal(MENU_RET_CONT_GAME) 'select <contine> when exiting a game
		case MENU_RET_SHOW_SAVE
			menuId = MENU_ID_SHOW_SAVE
			updateSaveLoad(menu(), menuId)
		case MENU_RET_SHOW_LOAD
			menuId = MENU_ID_SHOW_LOAD
			updateSaveLoad(menu(), menuId)
		case MENU_RET_SAVE_MAP
			lastSel = menu(menuId).lastSel
			optVal = menu(menuId).menuEntry(lastSel).optVal 'get selected slot id
			if optVal < 0 or optVal >= NUM_SAVE then panic("save - optVal: " & optVal)
			game.saveToDisk(saveFileName(optVal)) '0...4
			menuId = MENU_ID_MAIN
			menu(menuId).lastSel = menu(menuId).findItemWithRetVal(MENU_RET_CONT_GAME) 'select <contine> after save
		case MENU_RET_LOAD_MAP
			lastSel = menu(menuId).lastSel
			optVal = menu(menuId).menuEntry(lastSel).optVal 'get selected slot id
			if optVal < 0 or optVal >= NUM_SAVE then panic("load - optVal: " & optVal) 'select <contine> after load
			game.loadFromDisk(saveFileName(optVal))
			enableSaveCont(menu(), true)
			menuId = MENU_ID_MAIN
			menu(menuId).lastSel = menu(menuId).findItemWithRetVal(MENU_RET_CONT_GAME)
		case MENU_RET_QUIT_GAME
			menuId = MENU_ID_QUIT_CONF
		case MENU_RET_QUIT_CONF
			quit = 1
	end select
	sleep 1 'optional, menuLoop also includes sleep
wend

sleep(1000)
end
