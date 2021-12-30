;additions.ahk

; up to 6 parameters -> cascommands.ahk

showHintColored(s, n, fg, bg){
	global font
	global fontsize
	Gui, hintColored:Font, s%fontsize%, %font%
	Gui, hintColored:Font, %fg%
	Gui, hintColored:Color, %bg%
	Gui, hintColored:Add, Text,, %s%
	Gui, hintColored:-Caption
	Gui, hintColored:+ToolWindow
	Gui, hintColored:+AlwaysOnTop
	Gui, hintColored:Show
	Sleep, n
	Gui, hintColored:Destroy
	
	return ""
}

showTextFile(f,n){
	theSourceCode := ""
	if (FileExist(f) != ""){
		f := FileOpen(f,"r")
		theSourceCode := f.Read()
		f.Close()
	}
	Gui, showTextFile:Add, Edit, w0 h0 ; focus dummy
	Gui, showTextFile:Add, Edit, x22 y30 w440 h270 t8 t16 t24 t32 t40 t48 WantTab readonly, %theSourceCode%
	Gui, showTextFile:Show, xCenter yCenter h379 w479, showTextFile(%f%)
	sleep, n
	Gui, showTextFile:Destroy
	return
}



