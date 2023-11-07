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
Gui, 1:Add, Checkbox, x10 y105 vHelper2, 비탄도우미
Gui, 1:Add, Edit, x100 y100 w30 vHelper2DisplayTime, 15
Gui, 1:Add, Text, x130 y105, 초간 표시
Gui, 1:Add, Edit, x10 y125 w130 h230 vWordList
Gui, 1:Add, Edit, x150 y125 w110 h130 vBlackWordList
Gui, 1:Add, Button, x150 y265 w110 h40 vStartButton, 시작
Gui, 1:Add, Button, x150 y315 w110 h40 vStopButton, 중지
Gui, 1:Show, w280 h365, 로그추적기

IniPath := A_ScriptFullPath . ".ini"
LastString := ""
Load()


SysGet, MonitorPrimary, MonitorPrimary
SysGet, MonitorName, MonitorName, %MonitorPrimary%
SysGet, Monitor, Monitor, %MonitorPrimary%
SysGet, MonitorWorkArea, MonitorWorkArea, %MonitorPrimary%
left := 0
osdWidth := MonitorRight
osdTop := MonitorBottom / 2 - (MonitorBottom * 0.3)
osdHeight := MonitorBottom - (osdTop * 2)
;CustomColor = EEAA99  ; Can be any RGB color (it will be made transparent below).
CustomColor = 000000
Gui 2:+LastFound +AlwaysOnTop -Caption +ToolWindow +E0x08000000 +E0x00000020  ; +ToolWindow avoids a taskbar button and an alt-tab menu item.
Gui, 2:Color, %CustomColor%
Gui, 2:Font, s32  ; Set a large font size (32-point).
Gui, 2:Add, Text, x%left% y%osdTop% w%osdWidth% h%osdHeight% Center ym vOSDText cFF0000
WinSet, TransColor, %CustomColor% 150
;Gosub, UpdateOSD  ; Make the first update immediate rather than waiting for the timer.
Gui, 2:Show, x%left% y%osdTop% w%osdWidth% h%osdHeight% NoActivate  ; NoActivate avoids deactivating the currently active window.

Helper1RegexMsg1 := "(차원 전류 동력기|자동 전류 방사포)에게서 [0-9,]+의 대미지를 받았습니다."
Helper1RegexMsg2 := " : ([a-zA-Z가-힣\-]{1,12})-[a-zA-Z가-힣\-]{1,12}이 (차원 전류 동력기|자동 전류 방사포)에게서 [0-9,]+의 대미지를 받았습니다."
Helper2RegexMsg1 := "비운의 사마엘: 간악한 데바들! 또 내 눈앞에 나타난 것이냐?"
Helper2RegexMsg2 := "비운의 사마엘: 모두 쓸어버려주마!"
Helper2RegexMsg3 := "비운의 사마엘: 아무것도 아닌 데바들에게... 아아..."
Helper2Data1 := Object(1, "9시 흡수1/2", 20, "9시 흡수/1/2", 50, "12시 흡수/1/2", 80, "11시 1/2/1", 110, "11시 1/흡수/1 외부구체", 140, "11시 1/흡수/2 외부구체", 170, "강제전송/1/2", 200, "3시 흡수/1/2", 230, "6시 흡수/2/1", 260, "6시 흡수/1/2 전체구체", 290, "9시 흡수/1/2", 320, "흡수/2/1 내부구체", 350, "6시 1/2/1", 380, "6시 1/흡수/2", 400, "")
Helper2Data2 := {}
Helper2Data2[1] := "피뢰침 준비"
Helper2Data2[25] := "5초뒤 쫄"
Helper2Data2[55] := "5초뒤 1/2"
Helper2Data2[70] := "12시 흡수/2"
Helper2Data2[85] := "강제전송/1/2"
Helper2Data2[100] := "9시 흡수/1/2"
Helper2Data2[115] := "9시 기류"
Helper2Data2[140] := "3시 기류1"
Helper2Data2[165] := "3시 기류2"
Helper2Data2[190] := "3시 기류3"
Helper2Data2[215] := "12시 기류"
Helper2Data2[240] := "9시 기류"
Helper2Data2[265] := "6시 기류"
Helper2Data2[290] := "3시 마지막기류"
Helper2Phase := 0

UpdateOSD(str, displayTime) {
    time := displayTime * -1000
    GuiControlGet, old, 2:, OSDText
    if (StrLen(old) > 0) {
        str := str . "`n" . old
    }
    GuiControl,2:, OSDText, %str%
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
    try {
        lt := new LogTailer(FilePath, Func("OnNewLineRegex"), 50)
    } catch e {
        MsgBox % e.Message
        return
    }

    Helper2Phase := 0
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
    GuiControl, 1:Disable, Helper2
    GuiControl, 1:Disable, Helper2DisplayTime

    Gui, 2:Font, c%Helper1DisplayColor%
    GuiControl, 2:Font, OSDText,

return
Button중지:
    Helper2Phase := 0
    SetTimer, Helper2Lable1, Off
    SetTimer, Helper2Lable2, Off
    UpdateOSD("", 1)
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
    GuiControl, 1:Enable, Helper2
    GuiControl, 1:Enable, Helper2DisplayTime
return

Save() {
    Gui, 1:Submit, NoHide
    global IniPath
    global FilePath
    global WordList
    global BlackWordList
    global Url
    global Helper1, Helper1DisplayTime, Helper1DisplayColor
    global Helper2, Helper2DisplayTime

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
    IniWrite, %Helper2%, %IniPath%, default, Helper2
    IniWrite, %Helper2DisplayTime%, %IniPath%, default, Helper2DisplayTime
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

        IniRead, Helper2, %IniPath%, default, Helper2, 1
        GuiControl, , Helper2, %Helper2%

        IniRead, Helper2DisplayTime, %IniPath%, default, Helper2DisplayTime, 15
        GuiControl, , Helper2DisplayTime, %Helper2DisplayTime%

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
    global Helper1RegexMsg1, Helper1RegexMsg2, Helper1, Helper1DisplayTime
    global Helper2, Helper2RegexMsg1, Helper2RegexMsg2, Helper2RegexMsg3, Helper2DisplayTime, Helper2Phase
    if (1 == Helper1 && 0 < RegExMatch(line, Helper1RegexMsg1, result)) {
        user := "나"
        if (0 < RegExMatch(line, Helper1RegexMsg2, result)) {
            user := Trim(result1, " `t`r`n")
        }
        UpdateOSD(user, Helper1DisplayTime)
        return
    }

    if (1 == Helper2) {
        if (0 < RegExMatch(line, Helper2RegexMsg1, result)) {
            Helper2Phase := 1
            SetTimer, Helper2Lable1, -1
        } else if (0 < RegExMatch(line, Helper2RegexMsg2, result)) {
            Helper2Phase := 2
            SetTimer, Helper2Lable2, -1
        }

        if (2 == Helper2Phase) {
            if (0 < RegExMatch(line, Helper2RegexMsg3, result)) {
                Helper2Phase := 0
            }
        }
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
GuiControl,2:, OSDText
return

;RemoveOSD:
;    GuiControlGet, old, 2:, OSDText
;    lines := StrSplit(old, "`n")
;    if (lines.MaxIndex() > 0) {
;        lines.Delete(lines.MaxIndex())
;    }
;    newStr := StrJoin(lines, "`n")
;    GuiControl,2:, OSDText, %newStr%
;return

StrJoin(obj, delimeter := "") {
    result := obj[1]
    Loop % obj.MaxIndex() - 1
        result .= delimiter obj[A_Index+1]
    return result
}

Helper2Lable1:
    while (true) {
        lastTime := 0
        for time, msg in Helper2Data1 {
            if (Helper2Phase == 1) {
                sleepTime := (time - lastTime) * 1000
                sleep, %sleepTime%
                if (Helper2Phase != 1) {
                    return
                }
                UpdateOSD(msg, Helper2DisplayTime)
                lastTime := time
            }
        }
    }
return
Helper2Lable2:
    lastTime1 := 0
    for time1, msg1 in Helper2Data2 {
        if (Helper2Phase == 2) {
            sleepTime1 := (time1 - lastTime1) * 1000
            sleep, %sleepTime1%
            if (Helper2Phase != 2) {
                return
            }
            UpdateOSD(msg1, Helper2DisplayTime)
            lastTime1 := time1
        }
    }
return
