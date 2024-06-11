/*
 *********************************************************************************
 * 
 * updater.ahk
 * 
 * all files are UTF-8 no BOM encoded
 * 
 * from https://www.autohotkey.com/board/topic/10384-download-progress-bar/
 * 
 * Copyright (c) 2022 jvr.de. All rights reserved.
 *
 * Licens -> Licenses.txt
 * 
 *********************************************************************************
*/
#Requires AutoHotkey v1.0

#NoEnv
#Warn
#SingleInstance force
#Persistent

#InstallKeybdHook
#InstallMouseHook
#UseHook On

; branding
#Include reponame.ahk

SendMode Input
SetWorkingDir %A_ScriptDir%


clipboardSave := clipboardAll

hMain := 0
hLV1 := 0

buttonWidth := 200
buttonWidthSmall := 80
buttonHeight := 35
deltaButton := 10

fontDefault := "Segoe UI"
fontsizeDefault := 8

; used in first msgbox while maingui has not started yet!
font := fontDefault
fontsize := fontsizeDefault

longOperationRunning := false ; "semaphore"

SetTitleMatchMode, 2
DetectHiddenWindows, Off

CR := "`n"
CR2 := "`n`n"
runMode := 0
copiedFromPath := ""

wrkDir := A_ScriptDir . "\"

appName := "Updater"
appnameLower := "updater"
extensionExe := ".exe"
appVersion := "0.046"
appVersionRemote := "0.000"
appVersionFile := "updaterversion$_$_$.txt"

screenDPI := 96
total := 0

bit := (A_PtrSize=8 ? "64" : "32")

if (!A_IsUnicode)
  bit := "A" . bit
  
app := appName . " " . appVersion . " (" . bit . " bit)"

targetAppname := repoName

localVersion := 0.000
localVersionFile := "version.txt"

filesToUpdate := "updaterfiles$_$_$" . bit . ".txt"
defaultBatch := "_updater_default_files$_$_$" . bit . ".bat"
restartBatch := "updateupdater$_$_$.bat"

githubFailureSignatur := "This is not the web page you are looking for"
failureSignatur := "<head><title>404 Not Found</title></head>"
serverURL := "https://github.com/jvr-ks/"
serverURLExtension := "/raw/main/"

; self updates from:
serverUpdaterURL := "https://github.com/jvr-ks/"
serverUpdaterURLExtension := "/raw/main/"

downloadFileAddExtension := ".default"

preferedPathForced := ""

;------------------------------ start-parameter ------------------------------
Loop % A_Args.Length()
{
  if(eq(A_Args[A_index],"remove"))
    exitApp
    
  if(eq(A_Args[A_index],"gendefaultbatch")){
    filesToUpdateArr := []

    Loop, read, %filesToUpdate%
    {
      if (A_LoopReadLine != "") {
        filesToUpdateArr.Push(A_LoopReadLine)
      }
    }
    genDefaultBatch()
    clipboard := clipboardSave
    exitApp
  }
    
  if(eq(A_Args[A_index],"runMode"))
    runMode := 1
    
  FoundPos := RegExMatch(A_Args[A_index],"O)--copiedFromPath=(.*)", m)
  if(FoundPos > 0){
    copiedFromPath := m.value(m.Count())
  }
  
  FoundPos := RegExMatch(A_Args[A_index],"O)--usePath=(.*)", m)
  if(FoundPos > 0){
    preferedPathForced := m.value(m.Count())
  }
}

clientWidth := 900
clientHeight := 350

lv1MarginX := 10
lv1MarginY := 200
lv1Width := clientWidth - lv1MarginX
lv1Height := clientHeight - lv1MarginY

currentDownLoadFile := ""
hasFinished := false
downloadStarted := false

targetAppnameLower := StrLower(targetAppname)
preferedPathDefault := "C:\jvrde\" . targetAppnameLower . "\"

preferedPath := preferedPathDefault

if (preferedPathForced != "")
  preferedPath := preferedPathForced

createRestartBatch()

server := serverURL . targetAppnameLower . serverURLExtension
serverApp := serverUpdaterURL . appnameLower . serverUpdaterURLExtension

filesToUpdateArr := []

msgDefault := "Click on an entry to toggle update, click on the ""Start installation / update""-button, or press ESCAPE to exit!"

localVersion := getLocalVersion(localVersionFile)

remoteVersion := getVersionFromGithubServer(server . localVersionFile)

appVersionRemote := getAppVersionFromGithubServer(serverApp . appVersionFile)

if (FileExist("updater_runMode.txt")){
; runMode
  runMode := true
  updateUpdater(false)
  if (remoteVersion != "unknown!" && remoteVersion != "error!"){
    if (remoteVersion > localVersion){
      mainWindow()
      readLocalSize()
    } else {
      mainWindow()
      readLocalSize()
    }
  }
} else {
; not runMode
  msgDefault := "Please enter or select an installation-directory and press the ""Ok, install to this directory""-button then!"

  if (remoteVersion != "unknown!" && remoteVersion != "error!"){
    if (remoteVersion > localVersion){
      msg1 := "New version available: " . localVersion . " -> " . remoteVersion
      msgbox, 1, %targetAppname%, %msg1%`n`nUpdate %targetAppname%?`n`n- Exit a running %targetAppname% before!

      IfMsgBox, OK
        {
          mainWindow()
          readLocalSize()
        } else {
          globalMsgArr := {}
          globalMsgArr.push("Closing Updater!" . CR)
          globalMsgArr.push("Please restart Updater later!")
          errorExit(globalMsgArr, targetAppname)
        }
    } else {
      msg2 := "No new version available: " . localVersion . " >= " . remoteVersion . " `n`nOpen anyway?"
      msgbox, 4,%app%, %msg2%
      IfMsgBox, Yes
        {
          mainWindow()
          readLocalSize()
       } else {
         exit()
       }
    }
  } else {
    exitWithMessage()
  }
}


return

;-------------------------------- mainWindow --------------------------------
mainWindow() {
  global hMain, hLV1, wrkdir
  global lv1Width, lv1Height
  global app, appVersion 
  global font, fontsize, fontDefault, fontsizeDefault
  global buttonWidth, buttonWidthSmall, buttonHeight, deltaButton
  global ProgressBar, ProgressN, progressDownLoadURL, KB, Text1
  global server, targetAppname, localVersion, remoteVersion
  global preferedPath, preferedPathLabel, preferedPathText
  global Button1, filesToUpdateArr, runMode, selectFolder
  global setPreferedPathToDefault
  global openFileManager
  global insertFromClipboard, showHelp, clipboardSave, targetAppnameLower
  
  getUpdateInfo()

  Menu, Tray, UseErrorLevel   ; This affects all menus, not just the tray.
  if (runMode){
    Menu, SystemMenu, Add, Forced self-update, updateUpdater
  }
  
  Menu, MainMenu, DeleteAll
  Menu, MainMenu, Add, System, :SystemMenu
  Menu, MainMenu,Add,Exit, exit

  Gui,guiMain:New, +OwnDialogs +LastFound MaximizeBox HwndhMain -Resize, %app% Target: %targetAppname%`, version: %localVersion% -> %remoteVersion%

  Gui, guiMain:Margin,4,4
  Gui, guiMain:Font, s%fontsize%, %font%
  
  Gui, guiMain:Add, ListView, x5 w%lv1Width% h%lv1Height% GguiMainListViewClick vLV1 hwndhLV1 Grid AltSubmit -Multi, |File|Download|Local|Remote|Strategy|Subdir|SourceURL
  
  Gui, guiMain:Menu, MainMenu
  
  Gui, guiMain:Add, Progress, Section vProgressBar w500 -Smooth
  Gui, guiMain:Add, Text, x+m ys w50 vProgressN
  Gui, guiMain:Add, Text, x+m yp+0 w200 vKB
  Gui, guiMain:Add, Text, xm Section w400 vprogressDownLoadURL
  

  if (!runMode){
    arrow := Chr(0x21A7)
    Gui, guiMain:Add, Text, xm yp+20 VpreferedPathText, Installation-directory: 
    Gui, guiMain:Add, Edit, xm r1 w400 VpreferedPathLabel GsetPreferedPath, %preferedPath%
    Gui, guiMain:Add, Button, xm vButton1 w%buttonWidth% GstartDownload, Ok, install to this directory
    Gui, guiMain:Add, Button, xm VselectFolder GselectFolder, Select
    Gui, guiMain:Add, Button, x+m yp VsetPreferedPathToDefault GsetPreferedPathToDefault, Reset
    Gui, guiMain:Add, Button, x+m yp VopenFileManager GopenFileManager, FileManager
    Gui, guiMain:Add, Button, x+m yp VinsertFromClipboard GinsertFromClipboard,%arrow%
    Gui, guiMain:Add, Button, x+m yp VshowHelp GshowHelp, ?
  } else {
    Gui, guiMain:Add, Text, xm VpreferedPathText, Installation-directory: 
    
    preferedPath := wrkdir
    Gui, guiMain:Add, Edit, xm r1 w400 VpreferedPathLabel GsetPreferedPath, %preferedPath%
    Gui, guiMain:Add, Button, xm vButton1 GstartDownload, Start installation / update
  }
  
  
  Gui, guiMain:Add, StatusBar, 0x800 hWndhMainStatusBarHwnd
   
  for index, element in filesToUpdateArr
  {
    elementArr := StrSplit(element,",")
    name := elementArr[1]
    enable := elementArr[2]
    if (enable == "")
      enable := "yes"
    strategy := elementArr[3]
    targetpath := elementArr[4]
    sourceURL := elementArr[5]
    LV_Add("",index,name,enable,"","",strategy,targetpath,sourceURL)
  }
 
  Gui, guiMain:Show, xcenter y20 autosize

  adjustLV1()
  
  if (targetAppnameLower == "updater"){
    msgbox, You cannot update Updater with itself, exiting!`n(Updater has a builtin self-update!)
    clipboard := clipboardSave
    exitApp
  }

  return
}
;----------------------------- guiMainGuiEscape -----------------------------
guiMainGuiEscape(){
  exit()

  return
}
;------------------------------ guiMainGuiClose ------------------------------
guiMainGuiClose(){

  exit()

  return
}
;------------------------------ exitWithMessage ------------------------------
exitWithMessage(){
  ; keep namespace clean
  global CR, remoteVersion, localVersionFile, server

  msgArr := {}
  msgArr.push("Updatecheck failed: " . remoteVersion)
  msgArr.push("URL: " . server . localVersionFile)
  msgArr.push("(URL -> clipboard)" . CR)
  msgArr.push("Check your internet-connection!" . CR)
  msgArr.push("Check the targetAppname in the file ""updater.ini""" . CR)
  msgArr.push("Closing Updater due to an error!")
  
  errorExit(msgArr, server . localVersionFile)

  
  return
}
;------------------------------- updateUpdater -------------------------------
updateUpdater(force := true){
  global appVersionRemote, app, bit
  global appnameLower, appVersion, downloadFileAddExtension
  global appVersionFile, extensionExe, serverApp, serverURLExtension
  global restartBatch, longOperationRunning
  
  if (longOperationRunning){
    msgbox, Please wait until current operation has finished!
  
    return
  }
  
  if (bit == "64"){
    appnameLowerWithExtension := appnameLower . extensionExe . downloadFileAddExtension
    url := serverApp . appnameLowerWithExtension
  } else{
    appnameLowerWithExtension := appnameLower . bit . extensionExe . downloadFileAddExtension
    url := serverApp . appnameLowerWithExtension
  }
  
  if (appVersionRemote != "unknown!"){
    if ((appVersionRemote > appVersion) || force){
      question := "The Updater must be self-updated first!`n(Version: " . appVersion . " -> " . appVersionRemote . ")`n`nPlease restart the Updater manually afterwards!`n`nSelf-update the Updater now?"
      
      if (force)
        question := "Forced Self-update!`n(Version: " . appVersion . " -> " . appVersionRemote . ")`n`nPlease restart the Updater manually afterwards!`n`nSelf-update the Updater now?"
          
      msgbox,36,%app%, %question%
      IfMsgBox, Yes
        {
          ; forced download
          Try {
             UrlDownloadToFile, %url%, %appnameLowerWithExtension%
          }
          catch e {
            eMsg := e.Message
            msgbox, Closing the app due to the error`n`n(while updating Updater): %eMsg%`n`nDownload URL: %url%
            clipboard := url
            exit()
          }

          if (bit == "64")
            bit := ""
            
          run,%restartBatch% %bit%
          
          exit()
      }
    }
  } else {
    msgbox, Could not get the Updater version from the sever!`nVersion-info was: %appVersionRemote%
  }
  
  return
}
;------------------------------ getLocalVersion ------------------------------
getLocalVersion(file){
  
  versionLocal := 0.000
  if (FileExist(file) != ""){
    file := FileOpen(file,"r")
    versionLocal := file.Read()
    file.Close()
  }

  return versionLocal
}
;--------------------------------- showHelp ---------------------------------
showHelp(){
  global WB, gui_position

  cont := "<!DOCTYPE html>"
  cont .= "<html>"
  cont .= "<head></head>"
  cont .= "<body>"
  cont .= "<h4 id=""buttons-in-"" copy-mode""""="""">Buttons in the ""copy-mode""</h4><p>There are four additional buttons, if ""copy-mode"" is active:  </p><ul>
<li>Select: opens the windows directory-browser,  </li><li>Default: selects the default-installation-directory again,  </li><li>Filemanager: opens the windows-default-filemanager (user can copy the directory to the clipboard),  </li><li>&#8615;: (Down-arrow) uses clipboard-content as the installation-directory.  </li><li>?: Shows this help-window.</li></ul><ul>"

  cont .= "</body></html>"

  gui, help:new,+resize
  gui, help:margin,0,0
  gui, help:Add, ActiveX, x0 y0 w800 h600 vWB, about:<!DOCTYPE html><meta http-equiv="X-UA-Compatible" content="IE=edge">
  wb.document.write(cont)
  gui, help:Show, %gui_position% autosize, Help

  return
}
;------------------------------ openFileManager ------------------------------
openFileManager(){
  global preferedPath

  run,%preferedPath%,%preferedPath%

  return
}

;---------------------------- insertFromClipboard ----------------------------
insertFromClipboard(){
  global preferedPath, preferedPathLabel
  
  fClip := clipboard
  
  if (!eq(fClip,"")){
    preferedPath := fClip . "\"
    preferedPath := StrReplace(preferedPath,"\\","\")
  
    GuiControl,, preferedPathLabel, %preferedPath%
  }

  return
}
;------------------------------- selectFolder -------------------------------
selectFolder(){
  global preferedPath, preferedPathLabel

  FileSelectFolder, outputvari, *%preferedPath%, 1, Please select an installation-directory!
  
  if (outputvari != ""){
    preferedPath := outputvari . "\"
    preferedPath := StrReplace(preferedPath,"\\","\")
  
    GuiControl,, preferedPathLabel, %preferedPath%
  }

  return
}
;------------------------------ setPreferedPath ------------------------------
setPreferedPath(){
  global preferedPath, preferedPathLabel
  
  Gui, guiMain:submit, NoHide
  
  preferedPath := preferedPathLabel . "\"
  
  preferedPath := StrReplace(preferedPath,"\\","\")
  
  ; GuiControl,, preferedPathLabel, %preferedPath%
  
  return
}
;-------------------------- setPreferedPathToDefault --------------------------
setPreferedPathToDefault(){
  global preferedPath, preferedPathLabel, preferedPathDefault
  
  GuiControl,, preferedPathLabel, %preferedPath%
  
  return
}
;--------------------------------- adjustLV1 ---------------------------------
adjustLV1(){

  LV_ModifyCol(1,"AutoHdr Integer")
  LV_ModifyCol(2,"AutoHdr Text")
  LV_ModifyCol(3,"AutoHdr Text")
  LV_ModifyCol(4,"AutoHdr Text")
  LV_ModifyCol(5,"AutoHdr Text")
  LV_ModifyCol(6,"AutoHdr Text")
  LV_ModifyCol(7,"AutoHdr Text")
  LV_ModifyCol(8,"AutoHdr Text")
  
  return
}
;-------------------------------- refreshGui --------------------------------
refreshGui(){
  global targetAppname, server, progressDownLoadURL, filesToUpdateArr, LV1, hLV1
  
  for index, element in filesToUpdateArr
  {
    elementArr := StrSplit(element,",")
    name := elementArr[1]
    enable := elementArr[2]
    if (enable == "")
      enable := "yes"
      
    strategy := elementArr[3]
    targetpath := elementArr[4]
    sourceURL := elementArr[5]
      
    LV_Modify(index , "Col2", name)
    LV_Modify(index , "Col3", enable)
    LV_Modify(index , "Col6", strategy)
    LV_Modify(index , "Col7", targetpath)
    LV_Modify(index , "Col8", sourceURL)
  }
  
  adjustLV1()
  
  return
}
;------------------------------- readLocalSize -------------------------------
readLocalSize(){
  global server, filesToUpdateArr, hLV1, downloadFileAddExtension, msgDefault, longOperationRunning
  
  sizeLocal := ""
  
  longOperationRunning := true
  
  sendmessage, 0x115, 6, 0,, ahk_id %hLV1%
  for index, element in filesToUpdateArr
  {
    elementArr := StrSplit(element,",")
    name := elementArr[1]
    enable := elementArr[2]
    if (enable == "")
      enable := "yes"
      
    strategy := Trim(elementArr[3])
    targetpath := elementArr[4]
    sourceURL := elementArr[5]
    
    targetpathServer := ""
    if (targetpath != ""){
      targetpath := StrReplace(targetpath, "\", "")
      targetpath := StrReplace(targetpath, "/", "")
      targetpathServer:= targetpath . "/" ; on server use forwardslash!
      targetpath := targetpath . "\"
    }
    
    if (sourceURL == ""){
      url := server . targetpathServer . name . downloadFileAddExtension

      if (!FileExist(targetpath . name) && ((strategy == "" || strategy == "overwrite"))){
        LV_Modify(index , "Col4", "-")
        LV_Modify(index , "Col3", "forced")
        filesToUpdateArr[index] := name . ",forced," . strategy . "," . elementArr[4] . "," . sourceURL
      } else {
        fl := FileOpen(targetpath . name, "r").Length
        LV_Modify(index , "Col4", fl)
      }
    } else {
      fl := FileOpen(targetpath . name, "r").Length
      if (fl == ""){
        filesToUpdateArr[index] := name . ",forced," . strategy . "," . elementArr[4] . "," . sourceURL
        LV_Modify(index , "Col3", "forced")
      }
        
      LV_Modify(index , "Col4", fl)
      LV_Modify(index , "Col5", "external")
    }
    sendmessage, 0x115, 1, 0,, ahk_id %hLV1%
  }
 
  sendmessage, 0x115, 6, 0,, ahk_id %hLV1%
  
  showMessage(msgDefault)
  
  adjustLV1()
  
  longOperationRunning := false
  
  return
}
;-------------------------------- checkSize --------------------------------
checkSize(){
; resets forced
  global server, filesToUpdateArr, hLV1, downloadFileAddExtension
  global msgDefault, longOperationRunning
  global hmain, font, fontsize
   
  longOperationRunning := true
  
  sendmessage, 0x115, 6, 0,, ahk_id %hLV1%
  for index, element in filesToUpdateArr
  {
    elementArr := StrSplit(element,",")
    name := elementArr[1]
    targetpath := elementArr[4]
    
    targetpathServer := ""
    if (targetpath != ""){
      targetpath := StrReplace(targetpath, "\", "")
      targetpath := StrReplace(targetpath, "/", "")
      targetpathServer:= targetpath . "/" ; on server use forwardslash!
      targetpath := targetpath . "\"
    }
    
    fl := FileOpen(targetpath . name, "r").Length
    if (fl == ""){
      LV_Modify(index , "Col4", "ERROR!")
      showHintColored(hmain, "ERROR occured (file-size is zero)!", 5000)
      Beep(750, 300)
      Beep(750, 300)
      Beep(750, 300)
      Beep(750, 300)
      Beep(750, 300)
    } else {
      LV_Modify(index , "Col4", fl)
    }
        
    LV_Modify(index , "Col3", "")
      
    sendmessage, 0x115, 1, 0,, ahk_id %hLV1%
  }
  
  longOperationRunning := false
  
  return
}
;--------------------------- guiMainListViewClick ---------------------------
guiMainListViewClick(){
  global filesToUpdateArr
  
  if (A_GuiEvent = "normal"){
    LV_GetText(rowSelected, A_EventInfo)
    element := filesToUpdateArr[rowSelected]
    elementArr := StrSplit(element,",")
    name := elementArr[1]
    enable := elementArr[2]
    if (enable == "")
      enable := "yes"
    strategy := elementArr[3]
    targetpath := elementArr[4]
    sourceURL := elementArr[5]
    
    ; toggle thru
    if(InStr(enable,"forced"))
      enable := "yes"
    else if(InStr(enable,"yes"))
      enable := "no"
    else if(InStr(enable,"no"))
      enable := "forced"
    
    if (sourceURL != "" && targetpath == ""){
      msgbox, ERROR sourceURL: %sourceURL% only allowed with a subdirectory!`nexiting due to this error ...
      
      msgArr := {}
      msgArr.push("ERROR sourceURL: " . sourceURL  . " only allowed with a non empty subdirectory!")
      msgArr.push("Closing Updater due to an error!")
      
      errorExit(msgArr, sourceURL)
    }
      
    filesToUpdateArr[rowSelected] := name . "," . enable . "," . strategy . "," . targetpath . "," . sourceURL
    refreshGui()
  }
    
  return
}
;------------------------------- getUpdateInfo -------------------------------
getUpdateInfo(){
  ; get updater-files.txt
  
  global targetAppname, server, filesToUpdate, filesToUpdateArr
  
  url := server . filesToUpdate
  
  Try {
    if FileExist(filesToUpdate . ".tmp")
      FileDelete, %filesToUpdate%.tmp
      
    UrlDownloadToFile, %url%, %filesToUpdate%.tmp
  }
  catch e
  {
    eMsg := e.Message
    msgbox, Closing the app due to the error: %eMsg%
    exit()
  }

  FileRead, content, %filesToUpdate%.tmp
  
  if (InStr(content,"not found")){
    if FileExist(filesToUpdate . ".tmp")
      FileDelete, %filesToUpdate%.tmp
      
    msgArr := {}
    msgArr.push("ERROR, page not found on GitHub!")
    msgArr.push("Missing page: " . url)
    msgArr.push("Copied the address to the clipboard.")
    msgArr.push("Closing Updater due to an error!")
    
    errorExit(msgArr, url)
  }
  
  if (StrLen(content) > 100000){
  
    msgArr := {}
    msgArr.push("ERROR, something went wrong, file is to big!")
    msgArr.push("URL: " . url)
    msgArr.push("Copied the URL to the clipboard.")
    msgArr.push("Closing Updater due to an error!")
    msgArr.push("Please start Updater again!")
    
    errorExit(msgArr, url)

  } else {
    Try {
      FileCopy, %filesToUpdate%.tmp, %filesToUpdate%, 1
      
      if FileExist(filesToUpdate . ".tmp")
        FileDelete, %filesToUpdate%.tmp
          
      filesToUpdateArr := []

      Loop, read, %filesToUpdate%
      {
        if (A_LoopReadLine != "") {
          filesToUpdateArr.Push(A_LoopReadLine)
        }
      }
    }
    catch e
    {
      eMsg := e.Message
      msgbox, Closing the app due to the error: %eMsg%
      exit()
    }
  }
  
  return
}
;------------------------------- startDownload -------------------------------
startDownload(){
  global filesToUpdateArr, ProgressBar, ProgressN, hasFinished
  global downloadStarted, longOperationRunning, hLV1, hmain
  global font, fontsize
  global wrkDir, preferedPath, runMode, app
  global bit, appnameLower, appVersion, extensionExe
  global targetAppname, targetAppnameLower
  
  if (longOperationRunning){
    msgbox, Please wait until current operation has finished!
  
    return
  }
  
  if (!runMode){
    if (!eq(preferedPath, "")){
      if (!eq(preferedPath, wrkDir)) {
        if (bit == "64"){
          appnameLowerWithExtension := appnameLower . extensionExe
        } else{
          appnameLowerWithExtension := appnameLower . bit . extensionExe
        }
        ; msgbox, copy %appnameLowerWithExtension% %preferedPath%
        Try {
          FileCreateDir, %preferedPath%
          FileCopy,%appnameLowerWithExtension%,%preferedPath%,1
        }
        catch e
        {
          eMsg := e.Message
          msgbox, Closing the app due to the error (during cloning Updater): %eMsg%
          exit()
        }
        
        runParam := preferedPath . appnameLowerWithExtension . " runMode --copiedFromPath=" . wrkDir

        run,%runParam%,%preferedPath%
        exitApp
        
      } else {
        msgbox, ERROR`, using the download-directory as a path is not allowed!
      }
    } else {
      msgbox, ERROR`, an empty path is not allowed!
    }
  } else { 
    showMessage("Operation DOWNLOAD takes a while! (if ready, it beeps 3 times!)")
    
    hasFinished := false
    downloadStarted := true
    
    for index, element in filesToUpdateArr
    {
      elementArr := StrSplit(element,",")
      downLoadFilename := elementArr[1]
      enable := elementArr[2]
      targetpath := elementArr[4]
      sourceURL := elementArr[5]
      
      if InStr(downLoadFilename,"$_$_$"){
        msgbox, Filenames containing a "$_$_$" are not allowed!`n`nClosing the app due to an error!   
        exit()
      }
      
      if(enable == "" || InStr(enable,"y") || InStr(enable,"j") || InStr(enable,"forced")){
        downloadRun(index, downLoadFilename, targetpath, sourceURL)
      }
    }
    GuiControl, , ProgressBar, OFF
    GuiControl, , ProgressN, 
    
    refreshGui()
    hasFinished := true
    
    adjustLV1()
    
    applyStrategies()
    
    checkSize()
    
    sendmessage, 0x115, 6, 0,, ahk_id %hLV1%
    
    GuiControl, , progressDownLoadURL, Update done!
     
    showHintColored(hmain, "Update done!")
      
    Beep(750, 300)
    Beep(750, 300)
    Beep(750, 300)
    
    removeOldFiles()

    if (!FileExist("updater_runMode.txt")){
      FileAppend,This file is created by Updater to select the runMode and to log updates!`nDo NOT DELETE it!`n,updater_runMode.txt
    } else {
      FormatTime, TimeString,,'Date:' MM/dd/yy 'Time:' HH:mm:ss tt
      FileAppend,Updater run: %TimeString%`n,updater_runMode.txt
    }
    
    msgbox,33,Update done!,`nStart / restart %targetAppname% now?
    IfMsgBox Cancel
        return
        
    ; use appropriate updater exe-version to update app exe-version
    toRun := ""
    if (bit == "64"){
      toRun := targetAppnameLower . extensionExe
    } else{
      toRun := targetAppnameLower . bit . extensionExe
    }
    
    if (FileExist(toRun)){
      run,%toRun%
    } else {
      msgbox, Warning: Possible cross-version update!`nPlease manually start/restart the app now!`n`n Tried to start: %toRun%
    }
    
    exitApp
  }

    
  return
}
;------------------------------ removeOldFiles ------------------------------
removeOldFiles(){
  global copiedFromPath

  if (copiedFromPath != ""){
  
    msgbox,33,,Remove temporary used files from download-directory (%copiedFromPath%)?
    IfMsgBox Cancel
        return
        
    Try {
     if (FileExist(copiedFromPath . "updater.exe"))
        FileDelete, %copiedFromPath%updater.exe
     
      if (FileExist(copiedFromPath . "updater32.exe"))
        FileDelete, %copiedFromPath%updater32.exe
        
      if (FileExist(copiedFromPath . "updater.ini"))
        FileDelete, %copiedFromPath%updater.ini
        
        
      if (FileExist(copiedFromPath . "updaterfiles$_$_$64.txt"))
        FileDelete, %copiedFromPath%updaterfiles$_$_$64.txt
        
      if (FileExist("copiedFromPath . updaterfiles$_$_$32.txt"))
        FileDelete, %copiedFromPath%updaterfiles$_$_$32.txt
        
      if (FileExist(copiedFromPath . "updateupdater$_$_$.bat"))
        FileDelete, %copiedFromPath%updateupdater$_$_$.bat
        
    }
    catch e
    {
      msgbox, Warning, cannot delete all downloaded old files in:`n%copiedFromPath%`,`nplease remove them later manually!
    } 
  }

  return
}
;-------------------------------- downloadRun --------------------------------
downloadRun(theIndex, downLoadFilename, theTargetpath, theSourceURL){
  global targetAppname, server
  global progressDownLoadURL, ProgressBar, ProgressN, KB, downloadFileAddExtension

  if (downLoadFilename != ""){

    Gui, guiMain:Show, , Download %targetAppname% update (press ESC to abort)
    OnMessage(0x1100, "SetCounter")

    Download(theIndex, server, downLoadFilename, theTargetpath, theSourceURL, 150)
    
    GuiControl, , ProgressBar, 100
    GuiControl, , ProgressN, 100`%
    GuiControl, , progressDownLoadURL,
    GuiControl, , KB,
  }
   
  return
}
;--------------------------------- Download ---------------------------------
Download(theIndex, theServer, downloadFilename, theTargetpath, theSourceURL, sleep := 200) {
  global ProgressBar, progressDownLoadURL, downloadFileAddExtension
  global currentDownLoadFile, total
  global hLV1, wrkDir, preferedPath

  targetpath := theTargetpath
  sourceURL := theSourceURL
  
  targetpathServer := ""
  if (targetpath != ""){
    targetpath := StrReplace(targetpath, "\", "")
    targetpath := StrReplace(targetpath, "/", "")
    targetpathServer:= targetpath . "/" ; on server use forwardslash!
    targetpath := targetpath . "\"
    
    if (targetpath != "")
      FileCreateDir, %targetpath%
  }
  
  if (theSourceURL == ""){
    currentDownLoadFile := targetpath . downloadFilename . downloadFileAddExtension
    downloadUrl := theServer . targetpathServer . downLoadFilename . downloadFileAddExtension
    
    GuiControl, , progressDownLoadURL,Downloading: %downloadFilename%
    SetTimer, _dlprocess, %sleep%
  } else {
    currentDownLoadFile := targetpath . downloadFilename
    downloadUrl := theSourceURL . downLoadFilename
    
    GuiControl, , progressDownLoadURL, Downloading external file %currentDownLoadFile%
    SetTimer, _dlprocess, %sleep%
  }
  
  total := 0 + getLength(downloadUrl) ; not exact if external file due to compression
  
  if (total == 0){
    msgArr := {}
    msgArr.push("Problem with URL:")
    msgArr.push(downloadUrl)
    msgArr.push("failed!")
    msgArr.push("URL -> clipboard")
    msgArr.push("Closing Updater due to an error!")
  } else {
    LV_Modify(theIndex, "Col5", total)
    sendmessage, 0x115, 1, 0,, ahk_id %hLV1%
  }
  
  GuiControl, , progressDownLoadURL,Downloading: %downloadFilename%
  SetTimer, _dlprocess, %sleep%

  Try {
    if (fileExist(currentDownLoadFile))
      FileDelete, %currentDownLoadFile%
       
    UrlDownloadToFile, %downloadUrl%, %currentDownLoadFile%
    
    if (InStr(downloadUrl,"github.com")){
      if (github404(currentDownLoadFile)){
        msgArr := {}
        msgArr.push("Download of:")
        msgArr.push(downloadUrl)
        msgArr.push("failed!")
        msgArr.push("URL -> clipboard")
        msgArr.push("Error: content is HTML, containing github-failure-signature 404, page not found!")
        msgArr.push("Closing Updater due to an error!")
        
        errorContinue(msgArr, downloadUrl)
      }
    } else {
      if (other404(currentDownLoadFile)){
        msgArr := {}
        msgArr.push("Download of:")
        msgArr.push(downloadUrl)
        msgArr.push("failed!")
        msgArr.push("URL -> clipboard")
        msgArr.push("Error: content is HTML, containing the 404-failure-signature!")
        msgArr.push("Closing Updater due to an error!")
        
        errorContinue(msgArr, downloadUrl)
      }
    }
  }
  catch e
  {
    eMsg := e.Message
    msgArr := {}
    msgArr.push("Download of:")
    msgArr.push(downloadUrl)
    msgArr.push("failed!")
    msgArr.push("Error-type: " . eMsg)
    msgArr.push("URL -> clipboard")
    msgArr.push("Closing Updater due to an error!")  
    errorExit(msgArr, downloadUrl)
  }
  
  SetTimer, _dlprocess, Off
  return
  
_dlprocess:
  global total
  
  current := floor(FileOpen(targetpath . downloadFilename . downloadFileAddExtension, "r").Length)
  Process, Exist
  PostMessage, 0x1100, current, total, , ahk_pid %ErrorLevel%
  
  return
}

;------------------------------ applyStrategies ------------------------------
applyStrategies(){
  global filesToUpdateArr, downloadFileAddExtension, localVersionFile, remoteVersion
  
  for index, element in filesToUpdateArr
  {
    elementArr := StrSplit(element,",")
    downLoadFilename := elementArr[1]
    enable := elementArr[2]
    strategy := Trim(elementArr[3])
    strategyFound := false
    targetpath := elementArr[4]
    sourceURL := elementArr[5]
    
    if (Trim(sourceURL) == ""){
      targetpathServer := ""
      if (targetpath != ""){
        targetpath := StrReplace(targetpath, "\", "")
        targetpath := StrReplace(targetpath, "/", "")
        targetpathServer:= targetpath . "/" ; on server use forwardslash!
        targetpath := targetpath . "\"
      }
      
      savedDownLoadFilename := targetpath . downLoadFilename . downloadFileAddExtension
      localFileName := targetpath . downLoadFilename
      
      if (strategy == "" || strategy == "overwrite"){
        strategyFound := true
        if(enable == "" || InStr(enable,"y") || InStr(enable,"j") || InStr(enable,"forced")){
          try
          {
            FileCopy, %savedDownLoadFilename%,%localFileName%,1
          }
          catch e
          {
            eMsg := e.Message
            msgbox, Closing the app due to the error: %eMsg%`n`nPerhabs a file is missing on the server?`n`nOr you did not close the app before starting an update?
          }
          
          try
          {
            if FileExist(savedDownLoadFilename)
              FileDelete, %savedDownLoadFilename%
          }
          catch e
          {
            eMsg := e.Message
            msgbox, Closing the app due to the error: %eMsg%
            exit()
          }
        }
      }
      ; independant from enable:
      if (strategy == "delete"){
        strategyFound := true
        
        try
        {
          if (FileExist(localFileName))
            FileDelete, %localFileName%
            
          if (FileExist(savedDownLoadFilename))
            FileDelete, %savedDownLoadFilename%
        }
        catch e
        {
          eMsg := e.Message
          msgbox, Closing the app due to the error: %eMsg%!
          exit()
        }
      }
      
      if (!strategyFound){
        msgbox,48,ERROR,strategy %strategy% (entry: %index%) is not implemented yet!
      }
    }
  }
  
  ; last operation: write new version info
  Try {
    if FileExist(localVersionFile)
      FileDelete, %localVersionFile%
      
    FileAppend, %remoteVersion%, %localVersionFile%
  }
  catch e
  {
    eMsg := e.Message
    msgbox, Closing the app due to the error (while updating Updater): %eMsg%
    exit()
  }
   
  return
}
;-------------------------------- SetCounter --------------------------------
SetCounter(wParam, lParam) {
  global ProgressBar, ProgressN, KB
  
; wParam is the current progress of the download and lParam is the total size of the remote file, both in bytes.
; https://www.autohotkey.com/docs/commands/OnMessage.htm
  progress := Round(wParam / lParam * 100)
  GuiControl, , ProgressBar, %progress%
  GuiControl, , ProgressN, %progress%`%
  wParam := floor(wParam / 1024)
  lParam := floor(lParam / 1024)
  GuiControl, , KB, (%wParam%kb of %lParam%kb)
  
  return
}
;--------------------------------- github404 ---------------------------------
github404(downloadFile){
  global githubFailureSignatur
  
  ret := false

  Loop, read, %downloadFile%
  {
    if (InStr(A_LoopReadLine,githubFailureSignatur)){
      ret := true
      break
    }
  }
  
  return ret
}
;--------------------------------- other404 ---------------------------------
other404(downloadFile){
  global failureSignatur
  
  ret := false

  Loop, read, %downloadFile%
  {
    if (InStr(A_LoopReadLine,failureSignatur)){
      ret := true
      break
    }
  }
  
  return ret
}
;--------------------------------- getLength ---------------------------------
getLength(url){
 
  if InStr(url,"$_$_$"){
    msgbox, Filenames containing a "$_$_$" are not allowed!`n`nClosing the app due to an error!  
    exit()
  }
  
  ret := HttpQueryInfo(url,5)

  return ret

}
;------------------------------- HttpQueryInfo -------------------------------
; curl -I -L  https://xit.jvr.de/pricecompare/priceextractors.txt
; HttpQueryInfo length possible not correct due to compression

HttpQueryInfo(URL, QueryInfoFlag=21, Proxy := "", ProxyBypass := "") {
  ; https://autohotkey.com/board/topic/10384-download-progress-bar/
  res := ""
  hqi := 0
  hModule := DllCall("LoadLibrary", "str", dll := "wininet.dll")
  ver := (A_IsUnicode && !RegExMatch(A_AhkVersion, "\d+\.\d+\.4") ? "W" : "A")
  InternetOpen := dll "\InternetOpen" ver, HttpQueryInfo := dll "\HttpQueryInfo" ver
  InternetOpenUrl := dll "\InternetOpenUrl" ver, AccessType := Proxy > "" ? 3 : 1
  io_hInternet := DllCall(InternetOpen, "str", "", "uint", AccessType, "str", Proxy
                         , "str", ProxyBypass, "uint", 0)
  If (ErrorLevel || io_hInternet = 0) {
    DllCall("FreeLibrary", "uint", hModule)
    Return -1
  } Else iou_hInternet := DllCall(InternetOpenUrl, "uint", io_hInternet, "str", url, "str", "", "uint", 0, "uint", 0x80000000, "uint", 0)
  If (ErrorLevel || iou_hInternet = 0) {
    DllCall("FreeLibrary", "uint", hModule)
    Return -1
  } Else VarSetCapacity(buffer, 1024, 0), VarSetCapacity(buffer_len, 4, 0)
  Loop, 5 {
    hqi := DllCall(HttpQueryInfo, "uint", iou_hInternet, "uint", QueryInfoFlag, "uint", &buffer, "uint", &buffer_len, "uint", 0)
    If (hqi == 1) {
      Break
    }
  }
  If (hqi == 1) {
    p := &buffer
    Loop {
     l := DllCall("lstrlen", "UInt", p), VarSetCapacity(tmp_var, l+1, 0)
     DllCall("lstrcpy", "Str", tmp_var, "UInt", p)
     p += l + 1
     res .= tmp_var
     If (*p == 0)
       Break
    }
  } Else res := hqi
  DllCall("wininet\InternetCloseHandle",  "uint", iou_hInternet)
  DllCall("wininet\InternetCloseHandle",  "uint", io_hInternet)
  DllCall("FreeLibrary", "uint", hModule)
  Return res
}
;------------------------ getVersionFromGithubServer ------------------------
getVersionFromGithubServer(url){
  global targetAppname

  ret := "unknown!"

  whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
  Try
  {
    whr.Open("GET", url)
    whr.Send()
    status := whr.Status
    if (status == 200){
     ret := whr.ResponseText
    } else {
         
      msgArr := {}
      msgArr.push("Error while reading actual app version!")
      msgArr.push("Connection to:")
      msgArr.push(url)
      msgArr.push("failed!")
      msgArr.push("Repository-name: " . targetAppname . " (mispelled ?)")
      msgArr.push("URL -> clipboard")
      msgArr.push("Closing Updater due to an error!")
    
      errorExit(msgArr, url)
    }
  }
  catch e
  {
    ret := "error!"
  }

  return ret
}
;----------------------- getAppVersionFromGithubServer -----------------------
getAppVersionFromGithubServer(url){

  ret := "unknown!"

  whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
  Try
  {
    whr.Open("GET", url)
    whr.Send()
    status := whr.Status
    if (status == 200){
      ret := whr.ResponseText
    } else {
      msgArr := {}
      msgArr.push("Error while reading Updater version!")
      msgArr.push("Connection to:")
      msgArr.push(url)
      msgArr.push("failed!")
      msgArr.push("URL -> clipboard")
      msgArr.push("Closing Updater due to an error!")
    
      errorExit(msgArr, url)
    }
  }
  catch e
  {
    eMsg  := e.Message
    msgArr := {}
    msgArr.push("Connection to:")
    msgArr.push(url)
    msgArr.push("failed!")
    msgArr.push("URL -> clipboard")
    msgArr.push("Error: " . eMsg)
    msgArr.push("Closing Updater due to an error!")
    
    errorExit(msgArr, url)
  }

  return ret
}
;--------------------------------- StrLower ---------------------------------
StrLower(s){
  r := ""
  StringLower, r, s
  
  return r
}
;------------------------------ showHintColored ------------------------------
showHintColored(handle, s := "", n := 3000, fg := "cffffff", bg := "a900ff", newfont := "", newfontsize := ""){
  global guiMain
  global font, fontsize
  
  if (newfont == "")
    newfont := font
    
  if (newfontsize == "")
    newfontsize := fontsize
  
  Gui, hintColored:new, hwndhHintColored +0x80000000
  Gui, hintColored:Font, s%newfontsize%, %newfont%
  Gui, hintColored:Font, c%fg%
  Gui, hintColored:Color, %bg%
  Gui, hintColored:Add, Text,, %s%
  Gui, hintColored:-Caption
  Gui, hintColored:+ToolWindow
  Gui, hintColored:+AlwaysOnTop
  Gui, hintColored:Show
  Sleep, n
  Gui, hintColored:Destroy
  
  return
}
;------------------------------ genDefaultBatch ------------------------------
genDefaultBatch(){
  global filesToUpdateArr, defaultBatch, downloadFileAddExtension
  global hmain, font, fontsize

  Try {
    if FileExist(defaultBatch)
      FileDelete, %defaultBatch%
  }
  catch e
  {
    eMsg := e.Message
    msgbox, Closing the app due to the error (in gen. %defaultBatch% FileDelete): %eMsg%
    exit()
  }
  
  Try {
    content := "@rem " . defaultBatch . "`n`n"
    FileAppend, %content%, %defaultBatch%
  }
  catch e
  {
    eMsg := e.Message
    msgbox, Closing the app due to the error (in gen. %defaultBatch%): %eMsg%
    exit()
  }
  for index, element in filesToUpdateArr
  {
    elementArr := StrSplit(element,",")
      downLoadFilename := Trim(elementArr[1])
      downLoadFilenameTarget := urlToText(downLoadFilename)
    
    targetpath := Trim(elementArr[4])
    sourceURL := elementArr[5]
    
    if (sourceURL == ""){
      targetpathServer := ""
      if (targetpath != ""){
        targetpath := StrReplace(targetpath, "\", "")
        targetpath := StrReplace(targetpath, "/", "")
        targetpathServer:= targetpath . "/" ; on server use forwardslash!
        targetpath := targetpath . "\"
      }
      
      Try {
        quot := """"
        sl := "\"
        content := "copy /y /v " . quot . targetpath . downLoadFilename . quot . " " . quot . targetpath . downLoadFilenameTarget . downloadFileAddExtension . quot . "`n`n"
        FileAppend, %content%, %defaultBatch%
      }
      catch e
      {
        eMsg := e.Message
        msgbox, Closing the app due to the error (in gen. %defaultBatch% loop): %eMsg%
        exitApp
      }
    }
  }
  
  showHintColored(hmain, "Generated batch-file: " . defaultBatch)
  
  return
}
;------------------------------------ eq ------------------------------------
eq(a, b) {
  if (InStr(a, b) && InStr(b, a))
    return 1
  return 0
}
;---------------------------- createRestartBatch ----------------------------
createRestartBatch(){
  global restartBatch, bit
  
  Try {
  if (FileExist(restartBatch))
    FileDelete, %restartBatch%
    
  FileAppend,
(
@rem updateupdater$_$_$.bat

@echo off
timeout /t 3 /NOBREAK > nul
copy /Y updater`%1.exe.default updater`%1.exe  >nul 2>&1

echo Please restart the Updater now!
del /Q updater`%1.exe.default >nul 2>&1 

timeout /t 3 /NOBREAK > nul
exit
),%restartBatch%
  }
  catch e 
  {
    eMsg := e.Message
    msgbox, Error, could not create file: %restartBatch%`n`nClosing the app due to this error!
    exit()
  }  
  
  return
}
;------------------------------- errorContinue -------------------------------
errorContinue(theMsgArr, url) {
  global currentDownLoadFile, hasFinished, downloadStarted, downloadFileAddExtension, CR

  global appname

  if (downloadStarted && !hasFinished){
    fname := currentDownLoadFile . downloadFileAddExtension
    if FileExist(fname){
      FileDelete, %fname%
    }
  }
  
  msgComplete := ""
  for index, element in theMsgArr
  {
    msgComplete .= element . CR
  }
  
  msgComplete .= "Analyse the problem (closing " . appname . " afterwards!)?" . CR
  msgComplete .= "(Storing content to the file ""downloaded.bin""!)" . CR

  if (url != "")
    clipboard := url
    
  msgbox,4,ERROR,%msgComplete%
  
  IfMsgBox, yes 
  {
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", url, true)
    whr.Send()
    whr.WaitForResponse()
    rText := whr.ResponseText
    rText := RegExReplace(rText,"i)(<br[\\ ]*>)","$1`n")
    
    file := FileOpen("downloaded.bin","w")
    file.write(rText)
    file.Close()
    
    MsgBox, Ok!
  }
  exit()
  
  return
}
;--------------------------------- errorExit ---------------------------------
errorExit(theMsgArr, url := "") {
  global currentDownLoadFile, hasFinished, downloadStarted, downloadFileAddExtension, CR
 
  if (downloadStarted && !hasFinished){
    fname := currentDownLoadFile . downloadFileAddExtension
    if FileExist(fname){
      FileDelete, %fname%
    }
  }
  
  msgComplete := ""
  for index, element in theMsgArr
  {
    msgComplete .= element . CR
  }

  if (url != "")
    clipboard := url
    
  msgbox,48,ERROR,%msgComplete%
  
  exit()
  
  return
}
;--------------------------------- urlToText ---------------------------------
urlToText(url) {
 ; https://www.autohotkey.com/boards/viewtopic.php?style=17&p=292740#p292740
 VarSetCapacity(text, 600)
 DllCall("shlwapi\PathCreateFromUrl" (A_IsUnicode?"W":"A")
  , "Str", "file:" url, "Str", text, "UInt*", 300, "UInt", 0)
 Return text
}
;-------------------------------- CRC32_File --------------------------------
CRC32_File(filename) {
    if !(f := FileOpen(filename, "r", "UTF-8"))
        throw Exception("Failed to open file: " filename, -1)
    f.Seek(0)
    while (dataread := f.RawRead(data, 262144))
        crc := DllCall("ntdll.dll\RtlComputeCrc32", "uint", crc, "ptr", &data, "uint", dataread, "uint")
    f.Close()

    return Format("{:#x}", crc)
}

;-------------------------------- ConvertBase --------------------------------
ConvertBase(InputBase, OutputBase, nptr) {
; Base 2 - 36

  static u := A_IsUnicode ? "_wcstoui64" : "_strtoui64"
  static v := A_IsUnicode ? "_i64tow"    : "_i64toa"
  VarSetCapacity(s, 66, 0)
  value := DllCall("msvcrt.dll\" u, "Str", nptr, "UInt", 0, "UInt", InputBase, "CDECL Int64")
  DllCall("msvcrt.dll\" v, "Int64", value, "Str", s, "UInt", OutputBase, "CDECL")
  return s
}

;----------------------------------- CRC32 -----------------------------------
CRC32(str, enc := "UTF-8")
{
  size := (StrPut(str, enc) - 1) * (len := (enc = "CP1200" || enc = "UTF-16") ? 2 : 1)
  VarSetCapacity(buf, size, 0) && StrPut(str, &buf, Floor(size / len), enc)
  crc := DllCall("ntdll\RtlComputeCrc32", "uint", 0, "ptr", &buf, "uint", size, "uint")
  return Format("{:x}", crc) . ConvertBase(10,32,size + 32)
}

;---------------------------------- CRC32s ----------------------------------
CRC32s(str, enc := "UTF-8") {
  size := (StrPut(str, enc) - 1) * (len := (enc = "CP1200" || enc = "UTF-16") ? 2 : 1)
  VarSetCapacity(buf, size, 0) && StrPut(str, &buf, Floor(size / len), enc)
  crc := DllCall("ntdll\RtlComputeCrc32", "uint", 0, "ptr", &buf, "uint", size, "uint")
  return Format("{:x}", crc)
}

;----------------------------------- Beep -----------------------------------
Beep(Freq, Duration) {
; example: Beep(750, 300)

    if !(DllCall("kernel32.dll\Beep", "UInt", Freq, "UInt", Duration))
        return DllCall("kernel32.dll\GetLastError")
    return 1
}

;-------------------------------- showMessage --------------------------------
showMessage(t1 := "", t2 := ""){

  SB_SetParts(600,150)
  if (t1 != ""){
    SB_SetText(" " . t1 , 1, 1)
  }
    
  if (t2 != ""){
    SB_SetText(" " . t2 , 2, 1)
  }
  
  memory := "[" . GetProcessMemoryUsage() . " MB]      "
  SB_SetText("`t`t" . memory , 3, 2)

  return
}
;--------------------------- GetProcessMemoryUsage ---------------------------
GetProcessMemoryUsage() {
    PID := DllCall("GetCurrentProcessId")
    size := 440
    VarSetCapacity(pmcex,size,0)
    ret := ""
    
    hProcess := DllCall( "OpenProcess", UInt,0x400|0x0010,Int,0,Ptr,PID, Ptr )
    if (hProcess)
    {
        if (DllCall("psapi.dll\GetProcessMemoryInfo", Ptr, hProcess, Ptr, &pmcex, UInt,size))
            ret := Round(NumGet(pmcex, (A_PtrSize=8 ? "16" : "12"), "UInt") / 1024**2, 2)
        DllCall("CloseHandle", Ptr, hProcess)
    }
    return % ret
}
;----------------------------------- Exit -----------------------------------
exit(){
  global hMain, downloadStarted, hasFinished
  global clipboardSave
  
  if (hMain > 0){
  
    if (downloadStarted && !hasFinished)
      msgbox, Download aborted!`n`nTemporary files are not deleted!
 
  }
  
  clipboard := clipboardSave
  exitApp
}
;---------------------------------------------------------------------------
