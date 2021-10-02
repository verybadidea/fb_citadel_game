#include once "dir.bi"

'dim as string text = "copyright Klaus-Jürgen Wrede, see: https://en.wikipedia.org/wiki/Carcassonne_(board_game)"
dim as string txt1 = "Copyright:"
dim as string txt2 = "Klaus-Jürgen Wrede"
dim as string txt3 = "See: en.wikipedia.org/wiki/"
dim as string txt4 = "Carcassonne_(board_game)"
'dim as string cmd = "convert 01_RCRGX4.bmp -background transparent -fill black -font Ubuntu -size 140x80 -pointsize 14 -gravity southeast -annotate +10+10 'copyright text' 01_RCRGX4.bmp"

dim as string path = "./"
dim as string fileName = dir(path + "*.bmp", fbArchive)
if fileName = "" then end -1 'No files found in path
while (len(filename) > 0)
	shell "convert " + filename + " -background transparent -fill black -font Ubuntu -size 140x80 -pointsize 14 -gravity southwest -annotate +10+70 '" + txt1 + "' " + fileName
	shell "convert " + filename + " -background transparent -fill black -font Ubuntu -size 140x80 -pointsize 14 -gravity southwest -annotate +10+50 '" + txt2 + "' " + fileName
	shell "convert " + filename + " -background transparent -fill black -font Ubuntu -size 140x80 -pointsize 14 -gravity southwest -annotate +10+30 '" + txt3 + "' " + fileName
	shell "convert " + filename + " -background transparent -fill black -font Ubuntu -size 140x80 -pointsize 14 -gravity southwest -annotate +10+10 '" + txt4 + "' " + fileName
	fileName = dir()
wend



