@rem compile.bat

@echo off

@call sbt_console_select.exe remove

@"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in sbt_console_select.ahk /out sbt_console_select.exe /icon sbt_console_select.ico /bin "C:\Program Files\AutoHotkey\Compiler\Unicode 64-bit.bin"


