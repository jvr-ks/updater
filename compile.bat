@rem compile.bat
@rem without branding!

@echo off

cd %~dp0

echo.
echo Using Selja as test-app, i.e. branding "updater.exe" to "selja"
echo.

echo repoName := "selja"  > reponame.ahk

pause

set appname=updater
set _testDir=C:\jvrks\updater\

mkdir %_testDir% 2> NUL

set autohotkeyExe=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe
set autohotkeyCompilerPath=C:\Program Files\AutoHotkey\Compiler\

call "%autohotkeyExe%" /in %appname%.ahk /out %_testDir%%appname%.exe /icon %appname%.ico /bin "%autohotkeyCompilerPath%Unicode 64-bit.bin"
call "%autohotkeyExe%" /in %appname%.ahk /out %_testDir%%appname%32.exe /icon %appname%.ico /bin "%autohotkeyCompilerPath%Unicode 32-bit.bin"

copy /Y updaterfiles$_$_$*.* %_testDir%*.*

cd %_testDir%


@rem should open the default file-explorer 
start %_testDir%


