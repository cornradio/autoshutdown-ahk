#Persistent
#SingleInstance
SetWorkingDir %A_ScriptDir% 

; ��ʼ������
global shutdownTime := "23:00"
global isShutdownScheduled := false
global countdownSeconds := 20  ; �޸�Ϊ20�뵹��ʱ


; ���ر��������
IniRead, savedTime, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime, 23:00
IniRead, savedStatus, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled, 0
shutdownTime := savedTime
isShutdownScheduled := (savedStatus = 1)

; ��������ͼ��
Menu, Tray, NoStandard
Menu, Tray, Icon, pifmgr.dll, 5  ; ��ƻ��ͼ��
Menu, Tray, Tip, �Զ��ػ�����

; ����ʱ���Ӳ˵�
Menu, TimeMenu, Add, 13:00, SetPredefinedTime
Menu, TimeMenu, Add, 21:00, SetPredefinedTime
Menu, TimeMenu, Add, 22:00, SetPredefinedTime
Menu, TimeMenu, Add, 23:00, SetPredefinedTime
Menu, TimeMenu, Add, 00:00, SetPredefinedTime
Menu, TimeMenu, Add, �Զ���ʱ��..., SetShutdownTime

; �������̲˵�
Menu, Tray, Add, ���ùػ�ʱ��(&T), :TimeMenu
Menu, Tray, Add, δ���ùػ�ʱ��, DummyLabel  ; ��ӳ�ʼ״̬��ʱ����ʾ
Menu, Tray, Disable, δ���ùػ�ʱ��  ; ��������˵��ʹ��ֻ��Ϊ��ʾ��
Menu, Tray, Add
Menu, Tray, Add, �����ػ�(&S), ShutdownNow  ; ��������ػ�ѡ��
Menu, Tray, Add, ȡ���ػ�(&C), CancelShutdown
Menu, Tray, Add
Menu, Tray, Add, �鿴����(&U), CheckForUpdates
Menu, Tray, Add
Menu, Tray, Add, �˳�(&X), ExitApp

; ���ö�ʱ�����ʱ��
SetTimer, CheckTime, 60000  ; ÿ���Ӽ��һ��
SetTimer, UpdateRemainingTime, 1000  ; ÿ�����ʣ��ʱ����ʾ

return

; �ձ�ǩ������ʱ����ʾ�˵��
DummyLabel:
return

; ����ʣ��ʱ����ʾ
UpdateRemainingTime:
if (!isShutdownScheduled) {
    Menu, Tray, Rename, 2&, δ���ùػ�ʱ��
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

; ��ʽ��ʱ����ʾ
FormatTimeDisplay(minutes) {
    if (minutes <= 0)
        return "�ѹ�����Ĺػ�ʱ�䣬�������� " . shutdownTime . " �ػ�"
    
    if (minutes < 1)
        return "�����ػ�"
    else if (minutes < 60)
        return "ʣ�� " . minutes . " ����"
    else {
        hours := Floor(minutes / 60)
        mins := Mod(minutes, 60)
        if (mins = 0)
            return "ʣ�� " . hours . " Сʱ"
        else
            return "ʣ�� " . hours . " Сʱ " . mins . " ����"
    }
}

; ����Ԥ����ʱ��
SetPredefinedTime:
shutdownTime := A_ThisMenuItem
isShutdownScheduled := true
SaveConfig()
Gosub, UpdateRemainingTime
return

; �����Զ���ػ�ʱ��
SetShutdownTime:
InputBox, newTime, ���ùػ�ʱ��, ������ػ�ʱ�� (��: 23:00),,,,,,,, %shutdownTime%
if (!ErrorLevel) {
    if (RegExMatch(newTime, "^([01]?[0-9]|2[0-3]):[0-5][0-9]$")) {
        shutdownTime := newTime
        isShutdownScheduled := true
        SaveConfig()
        Gosub, UpdateRemainingTime
        MsgBox, �ػ�ʱ��������Ϊ %shutdownTime%
    } else {
        MsgBox, ʱ���ʽ��Ч����ʹ��24Сʱ�� (��: 23:00)
    }
}
return

; ȡ���ػ�
CancelShutdown:
isShutdownScheduled := false
SaveConfig()
Run, shutdown.exe -a
MsgBox, ��ȡ���ػ��ƻ�
return

; ���ʱ�䲢ִ�йػ�
CheckTime:
if (!isShutdownScheduled)
    return

FormatTime, currentTime, %A_Now%, HH:mm
remainingMinutes := GetTimeDifference(currentTime, shutdownTime)

; �����־
FileAppend, ��ǰʱ��: %currentTime%, Ŀ��ʱ��: %shutdownTime%, ʣ�����: %remainingMinutes%`n, %A_ScriptDir%\shutdown_log.txt

; ���ʣ��ʱ��С�ڵ���0���ӣ���ʼ�ػ�����
if (remainingMinutes <= 1) {
    StartCountdown()
}
return


; ��ʼ����ʱ
StartCountdown() {
    global countdownSeconds
    remainingSeconds := countdownSeconds
    
    while (remainingSeconds > 0) {
        if (!isShutdownScheduled) {
            FileAppend, �ػ���ȡ��`n, %A_ScriptDir%\shutdown_log.txt
            return
        }
        if (remainingSeconds == 20) {
            TrayTip, �Զ��ػ�����, ϵͳ���� %remainingSeconds% ���ػ�`n�Ҽ��������ͼ�� -C ��ȡ��, 30, 1
        }
        
        if (Mod(remainingSeconds, 2) = 0 ) {  ; �޸���ʾƵ��
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
    
    ; �޸Ĺػ�����
    if (isShutdownScheduled) {
        Shutdown, 1
    }
}

; ����ʱ�����ӣ�
GetTimeDifference(currentTime, targetTime) {
    currentHour := SubStr(currentTime, 1, 2)
    currentMinute := SubStr(currentTime, 4, 2) 
    targetHour := SubStr(targetTime, 1, 2)
    targetMinute := SubStr(targetTime, 4, 2)
    
    currentTotalMinutes := currentHour * 60 + currentMinute
    targetTotalMinutes := targetHour * 60 + targetMinute
    
    timeDiff := targetTotalMinutes - currentTotalMinutes
    
    ; ���Ŀ��ʱ��С�ڵ�ǰʱ�䣬˵���������ʱ��
    if (timeDiff < 0)
        timeDiff += 1440  ; ��24Сʱ�ķ�����
        
    return timeDiff
}

; ��������
SaveConfig() {
    IniWrite, %shutdownTime%, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime
    IniWrite, % isShutdownScheduled ? 1 : 0, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled
}

; �����ػ�
ShutdownNow:
isShutdownScheduled := true
StartCountdown()
return

ExitApp:
ExitApp
return
