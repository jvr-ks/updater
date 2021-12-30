@rem create_sbt_console_select_exe_link_hidewindow_in_autostartfolder.bat
@rem with parameter hidewindow

@set app=sbt_console_select

@cd %~dp0

@powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%userprofile%\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\%app%.lnk');$s.TargetPath='%~dp0\%app%.exe';$s.Arguments='hidewindow';$s.Save()"

