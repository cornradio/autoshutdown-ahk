#Persistent
#SingleInstance
SetWorkingDir %A_ScriptDir% 

; Initialize variables
global shutdownTime := "23:00"
global isShutdownScheduled := false
global countdownSeconds := 20  ; Countdown duration in seconds
global soundEnabled := true


; Load saved configuration
IniRead, savedTime, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime, 23:00
IniRead, savedStatus, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled, 0
IniRead, savedSound, %A_ScriptDir%\shutdown_config.ini, Settings, SoundEnabled, 1
shutdownTime := savedTime
isShutdownScheduled := (savedStatus = 1)
soundEnabled := (savedSound = 1)

; Create tray icon and tooltip
Menu, Tray, NoStandard
Menu, Tray, Icon, pifmgr.dll, 5  ; Rotten apple icon
Menu, Tray, Tip, Auto Shutdown Helper

; Create time submenu
Menu, TimeMenu, Add, 13:00, SetPredefinedTime
Menu, TimeMenu, Add, 21:00, SetPredefinedTime
Menu, TimeMenu, Add, 22:00, SetPredefinedTime
Menu, TimeMenu, Add, 23:00, SetPredefinedTime
Menu, TimeMenu, Add, 00:00, SetPredefinedTime
Menu, TimeMenu, Add, Custom Time..., SetShutdownTime

; Build tray menu
Menu, Tray, Add, Set Shutdown Time(&T), :TimeMenu
Menu, Tray, Add, No Shutdown Scheduled, DummyLabel  ; Display current schedule status
Menu, Tray, Disable, No Shutdown Scheduled  ; Display-only menu item
Menu, Tray, Add
Menu, Tray, Add, Shutdown Now(&S), ShutdownNow  ; Immediate shutdown option
Menu, Tray, Add, Sound Alerts(&B), ToggleSound
if (soundEnabled) {
    Menu, Tray, Check, Sound Alerts(&B)
} else {
    Menu, Tray, UnCheck, Sound Alerts(&B)
}
Menu, Tray, Add
Menu, Tray, Add, Check for Updates(&U), CheckForUpdates
Menu, Tray, Add
Menu, Tray, Add, Exit(&X), ExitApp

; Schedule timers
SetTimer, CheckTime, 60000  ; Check every minute
SetTimer, UpdateRemainingTime, 1000  ; Update remaining time every second

return

; Label placeholder for status display
DummyLabel:
return

; Update remaining time display
UpdateRemainingTime:
if (!isShutdownScheduled) {
    Menu, Tray, Rename, 2&, No Shutdown Scheduled
    return
}

CheckForUpdates() {
    run, https://github.com/cornradio/autoshutdown-ahk
}

FormatTime, currentTime, %A_Now%, HH:mm
remainingMinutes := GetTimeDifference(currentTime, shutdownTime)
timeDisplay := FormatTimeDisplay(remainingMinutes)
Menu, Tray, Rename, 2&, %timeDisplay%
return

; Format the time display
FormatTimeDisplay(minutes) {
    if (minutes <= 0)
        return "The scheduled time has passed. Shutdown will trigger tomorrow at " . shutdownTime
    
    if (minutes < 1)
        return "Shutdown imminent"
    else if (minutes < 60)
        return "Remaining " . minutes . " minutes"
    else {
        hours := Floor(minutes / 60)
        mins := Mod(minutes, 60)
        if (mins = 0)
            return "Remaining " . hours . " hours"
        else
            return "Remaining " . hours . " hours " . mins . " minutes"
    }
}

; Handle predefined time selection
SetPredefinedTime:
shutdownTime := A_ThisMenuItem
isShutdownScheduled := true
SaveConfig()
Gosub, UpdateRemainingTime
return

; Prompt for a custom shutdown time
SetShutdownTime:
InputBox, newTime, Set Shutdown Time, Enter shutdown time (e.g. 23:00),,,,,,,, %shutdownTime%
if (!ErrorLevel) {
    if (RegExMatch(newTime, "^([01]?[0-9]|2[0-3]):[0-5][0-9]$")) {
        shutdownTime := newTime
        isShutdownScheduled := true
        SaveConfig()
        Gosub, UpdateRemainingTime
        MsgBox, Shutdown time set to %shutdownTime%
    } else {
        MsgBox, Invalid time format! Use 24-hour format (e.g. 23:00)
    }
}
return

; Cancel scheduled shutdown (currently unused)
CancelShutdown:
isShutdownScheduled := false
SaveConfig()
Run, shutdown.exe -a
MsgBox, Shutdown schedule canceled
return

; Check current time against schedule
CheckTime:
if (!isShutdownScheduled)
    return

FormatTime, currentTime, %A_Now%, HH:mm
remainingMinutes := GetTimeDifference(currentTime, shutdownTime)

; Append log entry
FileAppend, Current time: %currentTime%, Target time: %shutdownTime%, Remaining minutes: %remainingMinutes%`n, %A_ScriptDir%\shutdown_log.txt

; If one minute or less remains, start countdown
if (remainingMinutes <= 1) {
    StartCountdown()
}
return


; Begin countdown before shutdown
StartCountdown() {
    global countdownSeconds, soundEnabled
    remainingSeconds := countdownSeconds
    
    while (remainingSeconds > 0) {
        if (!isShutdownScheduled) {
            FileAppend, Shutdown canceled`n, %A_ScriptDir%\shutdown_log.txt
            return
        }
        if (remainingSeconds == 20) {
            TrayTip, Auto Shutdown Reminder, System will shut down in %remainingSeconds% seconds, 30, 1
        }
        
        if (soundEnabled && Mod(remainingSeconds, 2) = 0 ) {  ; Beep every two seconds when enabled
            SoundBeep, 200, 120
            SoundBeep, 1200, 120
            SoundBeep, 400, 120
            SoundBeep, 600, 180
            SoundBeep, 800, 120
            SoundBeep, 1000, 180
        }
        
        Sleep, 1000
        remainingSeconds--
    }
    
    ; Execute shutdown
    if (isShutdownScheduled) {
        Shutdown, 1
    }
}

; Calculate difference between two HH:mm times
GetTimeDifference(currentTime, targetTime) {
    currentHour := SubStr(currentTime, 1, 2)
    currentMinute := SubStr(currentTime, 4, 2) 
    targetHour := SubStr(targetTime, 1, 2)
    targetMinute := SubStr(targetTime, 4, 2)
    
    currentTotalMinutes := currentHour * 60 + currentMinute
    targetTotalMinutes := targetHour * 60 + targetMinute
    
    timeDiff := targetTotalMinutes - currentTotalMinutes
    
    ; If target time is earlier than current time, schedule for next day
    if (timeDiff < 0)
        timeDiff += 1440  ; Minutes in 24 hours
        
    return timeDiff
}

; Persist configuration to disk
SaveConfig() {
    global shutdownTime, isShutdownScheduled, soundEnabled
    IniWrite, %shutdownTime%, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime
    IniWrite, % isShutdownScheduled ? 1 : 0, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled
    IniWrite, % soundEnabled ? 1 : 0, %A_ScriptDir%\shutdown_config.ini, Settings, SoundEnabled
}

; Immediately trigger countdown
ShutdownNow:
isShutdownScheduled := true
StartCountdown()
return

ToggleSound:
soundEnabled := !soundEnabled
if (soundEnabled) {
    Menu, Tray, Check, Sound Alerts(&B)
} else {
    Menu, Tray, UnCheck, Sound Alerts(&B)
}
SaveConfig()
return

ExitApp:
ExitApp
return
