@rem compile.bat
@rem without branding!

@echo off

SET appname=updater

call "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in %appname%.ahk /out %appname%.exe /icon %appname%.ico /bin "C:\Program Files\AutoHotkey\Compiler\Unicode 64-bit.bin"

call "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in %appname%.ahk /out %appname%32.exe /icon %appname%.ico /bin "C:\Program Files\AutoHotkey\Compiler\Unicode 32-bit.bin"

call "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in %appname%.ahk /out %appname%A32.exe /icon %appname%.ico /bin "C:\Program Files\AutoHotkey\Compiler\ANSI 32-bit.bin"




