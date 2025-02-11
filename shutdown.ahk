#Persistent
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; 初始化变量
global shutdownTime := "23:00"
global isShutdownScheduled := false
global countdownSeconds := 60  ; 关机前倒计时时间（秒）

; 加载保存的配置
IniRead, savedTime, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime, 23:00
IniRead, savedStatus, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled, 0
shutdownTime := savedTime
isShutdownScheduled := (savedStatus = 1)

; 创建托盘图标
Menu, Tray, NoStandard
Menu, Tray, Icon, shell32.dll, 290  ; 使用更好的关机图标
Menu, Tray, Tip, 自动关机助手

; 创建时间子菜单
Menu, TimeMenu, Add, 21:00, SetPredefinedTime
Menu, TimeMenu, Add, 22:00, SetPredefinedTime
Menu, TimeMenu, Add, 23:00, SetPredefinedTime
Menu, TimeMenu, Add, 23:30, SetPredefinedTime
Menu, TimeMenu, Add, 00:00, SetPredefinedTime
Menu, TimeMenu, Add
Menu, TimeMenu, Add, 自定义时间..., SetShutdownTime

; 创建托盘菜单
Menu, Tray, Add, 设置关机时间(&T), :TimeMenu
Menu, Tray, Add, 未设置关机时间, DummyLabel  ; 添加初始状态的时间显示
Menu, Tray, Disable, 未设置关机时间  ; 禁用这个菜单项，使其只作为显示用
Menu, Tray, Add
Menu, Tray, Add, 取消关机(&C), CancelShutdown
Menu, Tray, Add
Menu, Tray, Add, 退出(&X), ExitApp

; 设置定时器检查时间
SetTimer, CheckTime, 60000  ; 每分钟检查一次
SetTimer, UpdateRemainingTime, 1000  ; 每秒更新剩余时间显示

return

; 空标签（用于时间显示菜单项）
DummyLabel:
return

; 更新剩余时间显示
UpdateRemainingTime:
if (!isShutdownScheduled) {
    Menu, Tray, Rename, 2&, 未设置关机时间
    return
}

FormatTime, currentTime, %A_Now%, HH:mm
remainingMinutes := GetTimeDifference(currentTime, shutdownTime)
timeDisplay := FormatTimeDisplay(remainingMinutes)
Menu, Tray, Rename, 2&, %timeDisplay%
return

; 格式化时间显示
FormatTimeDisplay(minutes) {
    if (minutes <= 0)
        return "已过今天的关机时间，将在明天 " . shutdownTime . " 关机"
    
    if (minutes < 1)
        return "即将关机"
    else if (minutes < 60)
        return "剩余 " . minutes . " 分钟"
    else {
        hours := Floor(minutes / 60)
        mins := Mod(minutes, 60)
        if (mins = 0)
            return "剩余 " . hours . " 小时"
        else
            return "剩余 " . hours . " 小时 " . mins . " 分钟"
    }
}

; 设置预定义时间
SetPredefinedTime:
shutdownTime := A_ThisMenuItem
isShutdownScheduled := true
SaveConfig()
Gosub, UpdateRemainingTime
return

; 设置自定义关机时间
SetShutdownTime:
InputBox, newTime, 设置关机时间, 请输入关机时间 (如: 23:00),,,,,,,, %shutdownTime%
if (!ErrorLevel) {
    if (RegExMatch(newTime, "^([01]?[0-9]|2[0-3]):[0-5][0-9]$")) {
        shutdownTime := newTime
        isShutdownScheduled := true
        SaveConfig()
        Gosub, UpdateRemainingTime
        MsgBox, 关机时间已设置为 %shutdownTime%
    } else {
        MsgBox, 时间格式无效！请使用24小时制 (如: 23:00)
    }
}
return

; 取消关机
CancelShutdown:
isShutdownScheduled := false
SaveConfig()
Run, shutdown.exe -a
MsgBox, 已取消关机计划
return

; 检查时间并执行关机
CheckTime:
if (!isShutdownScheduled)
    return

FormatTime, currentTime, %A_Now%, HH:mm
if (currentTime = shutdownTime) {
    StartCountdown()
}
return

; 开始倒计时
StartCountdown() {
    global countdownSeconds
    remainingSeconds := countdownSeconds
    
    while (remainingSeconds > 0) {
        if (!isShutdownScheduled)
            return
        
        if (Mod(remainingSeconds, 10) = 0 || remainingSeconds <= 5) {
            SoundBeep, 750, 500  ; 发出提示音
            TrayTip, 自动关机提醒, 系统将在 %remainingSeconds% 秒后关机`n右键点击托盘图标可取消, 30, 1
        }
        
        Sleep, 1000
        remainingSeconds--
    }
    
    if (isShutdownScheduled)
        Shutdown, 1
}

; 计算时间差（分钟）
GetTimeDifference(currentTime, targetTime) {
    currentHour := SubStr(currentTime, 1, 2)
    currentMinute := SubStr(currentTime, 4, 2) 
    targetHour := SubStr(targetTime, 1, 2)
    targetMinute := SubStr(targetTime, 4, 2)
    
    currentTotalMinutes := currentHour * 60 + currentMinute
    targetTotalMinutes := targetHour * 60 + targetMinute
    
    if (targetTotalMinutes <= currentTotalMinutes)
        targetTotalMinutes += 1440  ; 加24小时
        
    return targetTotalMinutes - currentTotalMinutes
}

; 保存配置
SaveConfig() {
    IniWrite, %shutdownTime%, %A_ScriptDir%\shutdown_config.ini, Settings, ShutdownTime
    IniWrite, % isShutdownScheduled ? 1 : 0, %A_ScriptDir%\shutdown_config.ini, Settings, IsScheduled
}

ExitApp:
ExitApp
return
