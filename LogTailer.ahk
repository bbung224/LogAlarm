; LOG TAILER CLASS BY EVILC
; Pass it the filename, and a function object that gets fired when a new line is added
class LogTailer {
    seekPos := 0
    fileHandle := 0
    fileSize := 0
    checkInterval := 10

    __New(FileName, Callback, checkInterval=10){
        this.fileName := FileName
        this.callback := callback
        this.checkInterval := checkInterval
        fileHandle := FileOpen(FileName, "r `n")
        if (!IsObject(fileHandle)){
            throw "Unable to load file " . FileName
        }
        this.fileHandle := fileHandle
        this.fileSize := fileHandle.Length
        this.seekPos := fileHandle.Length
        fn := this.Read.Bind(this)
        this.ReadFn := fn
        this.Start()
    }

    Read(){
        if (this.fileHandle.Length < this.fileSize){
            ; File got smaller. Log rolled over. Reset to start
            this.seekPos := 0
        }
        ; Move to where we left off
        this.fileHandle.Seek(this.seekPos, 0)

        ; Read all new lines
        while (!this.fileHandle.AtEOF){
            line := this.fileHandle.ReadLine()
            if (line == "`r`n" || line == "`n"){
                continue
            }
            ; Fire the callback function and pass it the new line
            this.callback.call(line)
        }
        ; Store position we last processed
        this.seekPos := this.fileHandle.Pos
        ; Store length so we can detect roll over
        this.fileSize := this.fileHandle.Length
    }

    ; Starts tailing
    Start(){
        fn := this.ReadFn
        SetTimer, % fn, % this.checkInterval
    }

    ; Stops tailing
    Stop(){
        fn := this.ReadFn
        SetTimer, % fn, Off
    }

    ; Stop tailing and close file handle
    Delete(){
        this.Stop()
        this.fileHandle.Close()
    }
}
