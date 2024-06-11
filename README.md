# Updater  
Windows only!  
Autohotkey-script.  
For use with Github repositories.  
  
**Hint:** "XXX" -> empty or 64 = 64 bit, 32 = 32 bit  
  
** Usable but has a few bugs and is old AHK 1 code! ** 
  
#### Latest changes:  
  
Version (>=)| Change  
------------ | -------------  
0.046 | A32 (ANSI) version removed
0.045 | "updater_default_files*.bat" rename to "__updater_default_files*.bat"
0.044 | "xcopy"-command replace bei "copy /y /v"
0.043 | "xcopy"-command parameter changed to /Y /I
0.042 | "gendefaultbatch" operation: "copy"-command replaced by "xcopy"-command
0.037 | File "updater.ini" removed, gui simplified (always centered now!)  
0.032 | Restart version bug fixed  
0.031 | "gui.ini" renamed to "updater_gui.ini"  
0.030 | \_files\_required subdirectory renamed to files\_required  
0.029 | "Brand" Updater to a repository with the file "reponame.ahk" containing "repoName := "REPONAME""  
0.027 | Using separate File-list files (64bit, 32bit, 32bitANSI)  
0.026 | Introducing "sourceURL"-entry  
0.017 | "updater.ini" bug-fix  
0.016 | Other sever configurable  
0.014 | 32bit and 32bit ANSI version  
0.012 | Subdirectory support  
0.009 | useless "updaterversion\$\_\$\_\$.txt" removed  
0.004 | Repo "master" changed to "main"  
  
#### TODO:  
  
TODO | Done in  
------------ | -------------  
Add a CRC check (?)| -  
Strategy: merge | -   
Strategy: delete | 0.018  
Subdirectory support | 0.012  
  
#### Description:  
**Do not run the Updater inside the updater-repo-directory!**  
(see below "Copy to target" section)  
  
Updater is a simple app downloader/updater.  
Checks a Github repository if a new version is available,     
by reading the file "version.txt" (No file-dependent versions used).  
  
The download-process uses temporary files with the extension ".default",   
but not if files are external, i.e. using a "sourceURL"-entry!  
  
After completion of the download-process these temporary files are converted to the usable files.  
The conversion-strategy default is a simple overwrite (if strategy is blank or overwrite),  
external files are always directly downloaded i.e. overwritten.  
   
Portable, run from any directory, but running from a subdirectory of the windows programm-directories   
(C:\Program Files, C:\Program Files (x86) etc.)  
requires admin-rights and is not recommended!  
  
Other conversion-strategies will be implemented, if I need them ...    
  
<a href="#virusscan">Virus check see below.</a>  
  
    
#### Using Updater with a repo  
Updater requires 5 files to operate:  
  
Two files need to be adjusted:   
* 1\) File-list file: **updaterfiles\$\_\$\_\$64.txt**  
and (if it is or has a 32 bit version) **updaterfiles\$\_\$\_\$32.txt**   
Contains a list of all files to update (update-list).  
The file is downloaded from the repo upon start of UpdaterXXX.exe.     
  
Column | Content | If empty | remarks  
------------ | ------------- | ------------- | -------------    
1 | filename  | error | csv-format, column-separator is a comma.  
2 | download  | yes | yes/no/forced  
3 | strategy  | overwrite | overwrite/delete (more under construction)  
4 | subdirectory  | - | without leading path-separator  
5 | server-url | default-github | allowed for subdirectories only!   
  
All non existend files will become "forced" automatically.   
Example entry-column:   
libraryfile.jar,yes,overwrite,lib  
  
* 2\) updater.exe or updater32.exe  
The main executable.  
  
* 3\) updateupdater\$\_\$\_\$.bat  
A batch-file to restart updater.exe after a self update.  
Created by updaterXXX.exe.  
  
* 4\) updater\_default\_files\$\_\$\_\$XXX.bat  
Is used to copy all files listed in "updaterfiles\$\_\$\_\$XXX.txt" to their *.default counterpart.  
It can be automaticlly created by calling "updater.exe" with the parameter "gendefaultbatch".  
Example (part of my makefile):  
call updater.exe gendefaultbatch  
call updater\_default\_files\$\_\$\_\$64.bat  
call updater32.exe gendefaultbatch  
call updater\_default\_files\$\_\$\_\$32.bat  
  
* * **Hint:**  
SBT (using Coursier internally) does not use url-decode file/directory-names,  
i.e. which leads to pathnames like:  
"\$HOME\.coursier\cache\...\openjfx\javafx-base\16-ea%2B7\javafx-base-16-ea%2B7.jar"   
Uploader uses url-decoded file/directory-names which leads to pathnames like:  
"lib\javafx-base-16-ea+7.jar"  
  
* 5\) The branding-file "reponame.ahk" containing: "repoName := "REPONAME""  
The REPONAME should be the lowercase appname!  
I use this code in my make-file "make.bat":  
````
rem create updater-repo branding
echo repoName := "%appname%" > "C:\ ... path to ...\appname\reponame.ahk"  
````
* * **Hint:**  
It is not possible to update the Updater with itself!  
(Updater.exe contains content which is interpreted as a download error).  
But Updater has a builtin self-update feature!  
  
#### Copy to target  
** Do not run the Updater inside the updater-repo-directory!**  
  
Copy the files from the "files\_required"-subdirectory to the target-app-directory  
and edit them accordingly:  
updater.ini -> change the "targetAppname=Your target appname"  
updaterfiles\$\_\$\_\$XXX.txt -> look at "File-list file" above.  
reponame.ahk ->  replace repoName := "REPONAME" by repoName := "the actual appname"  
  
#### Other than Github-server  
Example: If files are located at "https://xit.jvr.de/pricecompare/*  
Chance the "Configuration file" to:  
````
[config]
targetAppname=Pricecompare  
font="Calibri"  
fontsize=10  
serverURL="https://xit.jvr.de/"  
serverURLExtension="/"  
serverUpdaterURL="https://github.com/jvr-ks/"  
serverUpdaterURLExtension="/raw/main/"  
 ````
  
This is not rocket-science, so missing slashes are not corrected automatically!  
**Values containig special characters must be quotet.**   
  
#### Strategies  
Can only handle simple updates.  
Cannot handle update-scenarios with history dependent procedures. 
  
Each strategy is only applied after a complete download (due to using temporary *.default files as download target).    
  
* overwite (default)  
Overwites the file. File  directory must be writable.  
  
* delete  
Deletes the file without any question!  
Because strategies are not version dependant, it should never be removed!  
  
#### Operation modes  
Updater has two mode: "copy-mode" and "run-mode".  
After downloading and starting Updater (without parameters) it is in the "copy-mode".  
The user can only select an installation-directory.  
By pressing the button "Use this installation-directory" Updater copies itself \*1) into the installation-directory  
and is restarted there, with the parameters "runMode" and "--copiedFrom=THE DOWNLOAD DIRECTORY".  
  
The file "updater_runMode.txt" is created also and a timestamp is added.  
If this file exists, Updater is always started in the "update-mode",  
so apps that have no Gui can use it too (the user can manualy start updaterXXX.exe).  
  
The parameter "--copiedFrom= ..." tells updater the path of the download-folder,  
so the containing files can be removed, if the user confirms with "OK".   
  
The parameter "--usePath= ..." can be used to set a new default installation-directory.  
  
  
\*1) Files copied are: "upaterXXX.exe" and "updater.ini", other files are downloaded again.  
A self update is only done or can be requested, if the "run-mode" is active,  
i.e. if Updater is called with the "runMode" parameter or the file "updater_runMode.txt" exists.  
  
#### Buttons in "copy-mode"  
There are four additional buttons if "copy-mode" is active:  
* Select: opens the windows directory-browser,  
* Default: selects the default-installation-directory again,  
* Filemanager: opens the windows-default-filemanager (user can copy the directory to the clipboard),  
* &#8615;: (Down-arrow) uses clipboard-content as the installation-directory.  
  
#### Remarks  
* Files containing the string "\$\_\$\_\$" are forbidden in the update-list "updaterfiles\$\_\$\_\$XXX.txt".  
  
* Files automatically **downloaded** by "Updater" are:  
* * "updaterfiles\$\_\$\_\$XXX.txt"  
* * "updaterversion\$\_\$\_\$.txt"  
* * "version.txt"  
  
* Files automatically **generated** by "Updater" are:  
* * "updateupdater\$\_\$\_\$.bat" 
* * "updater_gui.ini"  (to store the window size and position)  
  
* Files generated by **"updaterXXX.exe gendefaultbatch"** are:  
* * "updater\_default\_files\$\_\$\_\$XXX.bat"  
* * "updaterfiles\$\_\$\_\$XXX.txt.tmp" (temporary, deleted after use)  
    
#### License  
All files are licensed under the **GNU GENERAL PUBLIC LICENSE**  
A copy is included of the file "license.txt" is included in each download.  
  
Copyright (c) 2021 J. v. Roos  
  
<a name="virusscan"></a>  
##### Virusscan at Virustotal 
[Virusscan at Virustotal, updater.exe 64bit-exe, Check here](https://www.virustotal.com/gui/url/9ca6068490d1399cfc37307778b41523c880130032a45202c4558ef373604f65/detection/u-9ca6068490d1399cfc37307778b41523c880130032a45202c4558ef373604f65-1718098976
)  
[Virusscan at Virustotal, updater32.exe 32bit-exe, Check here](https://www.virustotal.com/gui/url/c2d6e7bff3feb95d149da772a6c6636d3ef0c0293d4a6515f396706ebfe21a5b/detection/u-c2d6e7bff3feb95d149da772a6c6636d3ef0c0293d4a6515f396706ebfe21a5b-1718098977
)  
Use [CTRL] + Click to open in a new window! 
