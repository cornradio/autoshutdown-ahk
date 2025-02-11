#Persistent
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; ��ʼ������
global shutdownTime := "23:00"
global isShutdownScheduled := false
global countdownSeconds := 60  ; �ػ�ǰ����ʱʱ�䣨�룩

; ���ر��������
IniRead, savedTime, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime, 23:00
IniRead, savedStatus, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled, 0
shutdownTime := savedTime
isShutdownScheduled := (savedStatus = 1)

; ��������ͼ��
Menu, Tray, NoStandard
Menu, Tray, Icon, shell32.dll, 290  ; ʹ�ø��õĹػ�ͼ��
Menu, Tray, Tip, �Զ��ػ�����

; ����ʱ���Ӳ˵�
Menu, TimeMenu, Add, 21:00, SetPredefinedTime
Menu, TimeMenu, Add, 22:00, SetPredefinedTime
Menu, TimeMenu, Add, 23:00, SetPredefinedTime
Menu, TimeMenu, Add, 23:30, SetPredefinedTime
Menu, TimeMenu, Add, 00:00, SetPredefinedTime
Menu, TimeMenu, Add
Menu, TimeMenu, Add, �Զ���ʱ��..., SetShutdownTime

; �������̲˵�
Menu, Tray, Add, ���ùػ�ʱ��(&T), :TimeMenu
Menu, Tray, Add, δ���ùػ�ʱ��, DummyLabel  ; ��ӳ�ʼ״̬��ʱ����ʾ
Menu, Tray, Disable, δ���ùػ�ʱ��  ; ��������˵��ʹ��ֻ��Ϊ��ʾ��
Menu, Tray, Add
Menu, Tray, Add, ȡ���ػ�(&C), CancelShutdown
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
if (currentTime = shutdownTime) {
    StartCountdown()
}
return

; ��ʼ����ʱ
StartCountdown() {
    global countdownSeconds
    remainingSeconds := countdownSeconds
    
    while (remainingSeconds > 0) {
        if (!isShutdownScheduled)
            return
        
        if (Mod(remainingSeconds, 10) = 0 || remainingSeconds <= 5) {
            SoundBeep, 750, 500  ; ������ʾ��
            TrayTip, �Զ��ػ�����, ϵͳ���� %remainingSeconds% ���ػ�`n�Ҽ��������ͼ���ȡ��, 30, 1
        }
        
        Sleep, 1000
        remainingSeconds--
    }
    
    if (isShutdownScheduled)
        Shutdown, 1
}

; ����ʱ�����ӣ�
GetTimeDifference(currentTime, targetTime) {
    currentHour := SubStr(currentTime, 1, 2)
    currentMinute := SubStr(currentTime, 4, 2) 
    targetHour := SubStr(targetTime, 1, 2)
    targetMinute := SubStr(targetTime, 4, 2)
    
    currentTotalMinutes := currentHour * 60 + currentMinute
    targetTotalMinutes := targetHour * 60 + targetMinute
    
    if (targetTotalMinutes <= currentTotalMinutes)
        targetTotalMinutes += 1440  ; ��24Сʱ
        
    return targetTotalMinutes - currentTotalMinutes
}

; ��������
SaveConfig() {
    IniWrite, %shutdownTime%, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime
    IniWrite, % isShutdownScheduled ? 1 : 0, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled
}

ExitApp:
ExitApp
return
