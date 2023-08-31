#Include LogTailer.ahk
#Include Http.ahk
#Persistent


Gui, Add, Edit, x10 y20 w180 h20 vFilePath
Gui, Add, Button, x200 y20 w60, 로그파일
Gui, Add, Text, x10 y40, 디스코드 웹훅 URL(Optional)
Gui, Add, Edit, x10 y55 w250 h20 vUrl
Gui, Add, Edit, x10 y85 w130 h230 vWordList
Gui, Add, Edit, x150 y85 w110 h130 vBlackWordList
Gui, Add, Button, x150 y225 w110 h40 , 시작
Gui, Add, Button, x150 y275 w110 h40 , 중지
Gui, Show, w280 h325, 로그추적기

IniPath := A_ScriptFullPath . ".ini"
LastString := ""
Load()
return
GuiClose:
    Save()
    ExitApp
return
Button로그파일:
    FileSelectFile, FilePath
    GuiControl, Text, FilePath, %FilePath%
    Gui, Submit, NoHide
return
Button시작:
    Gui, Submit, NoHide
    if (0 == StrLen(FilePath)) {
        MsgBox, 로그파일 위치를 설정해주세요
        return
    }
    words := StrSplit(WordList, "`n")
    blackwords := StrSplit(BlackWordList, "`n")
    lt := new LogTailer(FilePath, Func("OnNewLineRegex"))

    GuiControl, Enable, Button3
    GuiControl, Disable, Button1
    GuiControl, Disable, Button2
    GuiControl, Disable, FilePath
    GuiControl, Disable, Url
    GuiControl, Disable, WordList
    GuiControl, Disable, BlackWordList

return
Button중지:
    lt.Delete()
    Save()
    GuiControl, Disable, Button3
    GuiControl, Enable, Button1
    GuiControl, Enable, Button2
    GuiControl, Enable, FilePath
    GuiControl, Enable, Url
    GuiControl, Enable, WordList
    GuiControl, Enable, BlackWordList
return

Save() {
    Gui, Submit, NoHide
    global IniPath
    global UseRegex
    global FilePath
    global WordList
    global BlackWordList
    global Url

    UseRegex := StrReplace(UseRegex, "`n", "``n")
    IniWrite, %UseRegex%, %IniPath%, default, UseRegex
    FilePath := StrReplace(FilePath, "`n", "``n")
    IniWrite, %FilePath%, %IniPath%, default, FilePath
    WordList := StrReplace(WordList, "`n", "``n")
    IniWrite, %WordList%, %IniPath%, default, WordList
    BlackWordList := StrReplace(BlackWordList, "`n", "``n")
    IniWrite, %BlackWordList%, %IniPath%, default, BlackWordList
    IniWrite, %Url%, %IniPath%, default, Url
}
Load() {
    global IniPath
    if (FileExist(IniPath)) {
        IniRead, UseRegex, %IniPath%, default, UseRegex, 1
        UseRegex := StrReplace(UseRegex, "``n", "`n")
        GuiControl, , UseRegex, %UseRegex%

        IniRead, FilePath, %IniPath%, default, FilePath, %A_Space%
        FilePath := StrReplace(FilePath, "``n", "`n")
        GuiControl, Text, FilePath, %FilePath%

        IniRead, WordList, %IniPath%, default, WordList, %A_Space%
        WordList := StrReplace(WordList, "``n", "`n")
        GuiControl, Text, WordList, %WordList%

        IniRead, BlackWordList, %IniPath%, default, BlackWordList, %A_Space%
        BlackWordList := StrReplace(BlackWordList, "``n", "`n")
        GuiControl, Text, BlackWordList, %BlackWordList%

        IniRead, Url, %IniPath%, default, Url, %A_Space%
        GuiControl, Text, Url, %Url%
    }
}

; This function gets called each time there is a new line
OnNewLineNormal(line){
    global words
    global blackwords
    Loop % blackwords.MaxIndex() {
        word := blackwords[A_Index]
        IfInString, line, %word%
        {
            return
        }
    }
    Loop % words.MaxIndex() {
        word := words[A_Index]
        IfInString, line, %word%
        {
            ToolTip %line%
            PostWork()
            break
        }
    }
}
OnNewLineRegex(line){
    global words, blackwords, Url, LastString
    Loop % blackwords.MaxIndex() {
        word := blackwords[A_Index]
        if (0 < RegExMatch(line, word)) {
            return
        }
    }
    Loop % words.MaxIndex() {
        word := words[A_Index]
        if (0 < RegExMatch(line, word)) {
            if (StrLen(Url) > 0) {
                if (line != LastString) {
                    LastString := line
                    PostDiscordString(Url, StrReplace(line, "`n", ""))
                }
            }
            else {
                ToolTip %line%
                PostWork()
            }
            break
        }
    }
}

PostWork() {
    SetTimer, RemoveToolTip, -5000
}

RemoveToolTip:
ToolTip
return
