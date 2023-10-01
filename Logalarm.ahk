#Include LogTailer.ahk
#Include Http.ahk
#Persistent

Gui, 1:Add, Edit, x10 y20 w180 h20 vFilePath
Gui, 1:Add, Button, x200 y20 w60 vOpenLogFile, 로그파일
Gui, 1:Add, Text, x10 y40, 디스코드 웹훅 URL(Optional)
Gui, 1:Add, Edit, x10 y55 w250 h20 vUrl
Gui, 1:Add, Checkbox, x10 y85 vHelper1, 원반도우미
Gui, 1:Add, Edit, x100 y80 w30 vHelper1DisplayTime, 3
Gui, 1:Add, Edit, x200 y80 vHelper1DisplayColor, FF0000
Gui, 1:Add, Text, x130 y85, 초간 표시
Gui, 1:Add, Edit, x10 y105 w130 h230 vWordList
Gui, 1:Add, Edit, x150 y105 w110 h130 vBlackWordList
Gui, 1:Add, Button, x150 y245 w110 h40 vStartButton, 시작
Gui, 1:Add, Button, x150 y295 w110 h40 vStopButton, 중지
Gui, 1:Show, w280 h345, 로그추적기

IniPath := A_ScriptFullPath . ".ini"
LastString := ""
Load()


SysGet, MonitorPrimary, MonitorPrimary
SysGet, MonitorName, MonitorName, %MonitorPrimary%
SysGet, Monitor, Monitor, %MonitorPrimary%
SysGet, MonitorWorkArea, MonitorWorkArea, %MonitorPrimary%
left := 0
width := MonitorRight
top := MonitorBottom / 2 - (MonitorBottom * 0.3)
height := MonitorBottom - top
;CustomColor = EEAA99  ; Can be any RGB color (it will be made transparent below).
CustomColor = 000000
Gui 2:+LastFound +AlwaysOnTop -Caption +ToolWindow  ; +ToolWindow avoids a taskbar button and an alt-tab menu item.
Gui, 2:Color, %CustomColor%
Gui, 2:Font, s32  ; Set a large font size (32-point).
Gui, 2:Add, Text, x%left% y%top% w%width% h%height% Center ym vOSDText cFF0000
WinSet, TransColor, %CustomColor% 150
;Gosub, UpdateOSD  ; Make the first update immediate rather than waiting for the timer.
Gui, 2:Show, x%left% y%top% w%width% h%height% NoActivate  ; NoActivate avoids deactivating the currently active window.

reg1 := " : ([a-zA-Z가-힣\-]{1,12})-[a-zA-Z가-힣\-]{1,12}이 (차원 전류 동력기|자동 전류 방사포)에게서 [0-9,]+의 대미지를 받았습니다."

UpdateOSD(str) {
    global Helper1DisplayTime
    time := Helper1DisplayTime * -1000
    SetTimer, RemoveOSD, Delete
    GuiControlGet, old, 2:, OSDText
    if (StrLen(old) > 0) {
        str := str . "`n" . old
    }
    GuiControl,2:, OSDText, %str%
    Gui, 2:Show, NoActivate
    SetTimer, RemoveOSD, %time%
}

return
GuiClose:
    Save()
    ExitApp
return
Button로그파일:
    FileSelectFile, FilePath
    GuiControl, 1:Text, FilePath, %FilePath%
    Gui, 1:Submit, NoHide
return
Button시작:
    Gui, 1:Submit, NoHide
    if (0 == StrLen(FilePath)) {
        MsgBox, 로그파일 위치를 설정해주세요
        return
    }
    words := StrSplit(WordList, "`n")
    blackwords := StrSplit(BlackWordList, "`n")
    lt := new LogTailer(FilePath, Func("OnNewLineRegex"))

    GuiControl, 1:Enable, StopButton
    GuiControl, 1:Disable, OpenLogFile
    GuiControl, 1:Disable, StartButton
    GuiControl, 1:Disable, FilePath
    GuiControl, 1:Disable, Url
    GuiControl, 1:Disable, WordList
    GuiControl, 1:Disable, BlackWordList
    GuiControl, 1:Disable, Helper1
    GuiControl, 1:Disable, Helper1DisplayTime
    GuiControl, 1:Disable, Helper1DisplayColor

    Gui, 2:Font, c%Helper1DisplayColor%
    GuiControl, 2:Font, OSDText,

return
Button중지:
    lt.Delete()
    Save()
    GuiControl, 1:Disable, StopButton
    GuiControl, 1:Enable, OpenLogFile
    GuiControl, 1:Enable, StartButton
    GuiControl, 1:Enable, FilePath
    GuiControl, 1:Enable, Url
    GuiControl, 1:Enable, WordList
    GuiControl, 1:Enable, BlackWordList
    GuiControl, 1:Enable, Helper1
    GuiControl, 1:Enable, Helper1DisplayTime
    GuiControl, 1:Enable, Helper1DisplayColor
return

Save() {
    Gui, 1:Submit, NoHide
    global IniPath
    global FilePath
    global WordList
    global BlackWordList
    global Url
    global Helper1, Helper1DisplayTime, Helper1DisplayColor

    FilePath := StrReplace(FilePath, "`n", "``n")
    IniWrite, %FilePath%, %IniPath%, default, FilePath
    WordList := StrReplace(WordList, "`n", "``n")
    IniWrite, %WordList%, %IniPath%, default, WordList
    BlackWordList := StrReplace(BlackWordList, "`n", "``n")
    IniWrite, %BlackWordList%, %IniPath%, default, BlackWordList
    IniWrite, %Url%, %IniPath%, default, Url
    IniWrite, %Helper1%, %IniPath%, default, Helper1
    IniWrite, %Helper1DisplayTime%, %IniPath%, default, Helper1DisplayTime
    IniWrite, %Helper1DisplayColor%, %IniPath%, default, Helper1DisplayColor
}
Load() {
    global IniPath
    if (FileExist(IniPath)) {
        IniRead, FilePath, %IniPath%, default, FilePath, %A_Space%
        FilePath := StrReplace(FilePath, "``n", "`n")
        GuiControl, 1:Text, FilePath, %FilePath%

        IniRead, WordList, %IniPath%, default, WordList, %A_Space%
        WordList := StrReplace(WordList, "``n", "`n")
        GuiControl, 1:Text, WordList, %WordList%

        IniRead, BlackWordList, %IniPath%, default, BlackWordList, %A_Space%
        BlackWordList := StrReplace(BlackWordList, "``n", "`n")
        GuiControl, 1:Text, BlackWordList, %BlackWordList%

        IniRead, Url, %IniPath%, default, Url, %A_Space%
        GuiControl, 1:Text, Url, %Url%

        IniRead, Helper1, %IniPath%, default, Helper1, 1
        GuiControl, , Helper1, %Helper1%

        IniRead, Helper1DisplayTime, %IniPath%, default, Helper1DisplayTime, 3
        GuiControl, , Helper1DisplayTime, %Helper1DisplayTime%

        IniRead, Helper1DisplayColor, %IniPath%, default, Helper1DisplayColor, FF0000
        GuiControl, , Helper1DisplayColor, %Helper1DisplayColor%
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
    global words, blackwords, Url, LastString, reg1, Helper1
    if (1 == Helper1 && 0 < RegExMatch(line, reg1, result)) {
        user := Trim(result1, " `t`r`n")
        UpdateOSD(user)
        return
    }
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

RemoveOSD:
;Gui 2:Hide
GuiControl,2:, OSDText
return
