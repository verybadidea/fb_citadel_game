type log_entry_type
	dim as string time_, text
	declare operator cast () as string
end type

operator log_entry_type.cast () as string
   return time_ & " " & text
end operator

type logger_type
	dim as string mFileName
	declare constructor(fileName as string)
	declare destructor
	declare function add(text as string) as integer
	declare function pop() as log_entry_type
end type

constructor logger_type(fileName as string)
	mFileName = fileName
end constructor

destructor logger_type
	mFileName = ""
end destructor

'write text to log file
function logger_type.add(text as string) as integer
	if mFileName = "" then
		return -1
	else
		dim as integer fileNum
		fileNum = freefile
		if open(mFileName, for append, as fileNum) = 0 then 
			print #fileNum, time & " - " & text
			close fileNum
		else
			return -2
		end if
	end if
	return 0
end function

'test code

'~ var logger = logger_type("datalog.txt", 5)

'~ print logger.numEntries
'~ logger.add("bla1")
'~ logger.add("bla2")
'~ logger.add("bla3")
'~ print logger.numEntries

'~ for i as integer = 0 to logger.numEntries - 1
	'~ print logger.entry(i)
'~ next

