# sbt_console_select

##### Description  

Simple app to start "sbt console" or "sbt consoleQuick" in different directories.  
[SBT](https://www.scala-sbt.org/) is a [Scala](https://www.scala-lang.org/) build tool,   
"sbt console" or "sbt consoleQuick" starts the Scala REPL,  
using additional information supplied by the SBT build system.  
Windows only, but can be used with the WSL.  
The app changes the Clipboard-content!  
  
Can be used to start any programm/app in a selectable directory.  
("sbt console" needs a ["build.sbt"-file](https://www.scala-sbt.org/1.x/docs/Basic-Def.html) in the running directory  
and the file "project\build.properties" with the SBT version information).  
 
##### App status  

* Usable, but work in progress!  
* Executable is **64bit** now.

##### Download  

Download from github:  
[sbt_console_select as ZIP-file](https://github.com/jvr-ks/sbt_console_select/raw/master/sbt_console_select.zip)  


or  
[sbt_console_select.exe](https://github.com/jvr-ks/sbt_console_select/raw/master/sbt_console_select.exe)   
[sbt_console_select.ini](https://github.com/jvr-ks/sbt_console_select/raw/master/sbt_console_select.ini)   
[sbt_console_select.txt](https://github.com/jvr-ks/sbt_console_select/raw/master/sbt_console_select.txt)    
[sbt_console_select_shortcuts.txt](https://github.com/jvr-ks/sbt_console_select/raw/master/sbt_console_select_shortcuts.txt)   
  
Virus check see below.  

#### Latest changes:  
  
Version (>=)| Change
------------ | -------------
0.185 | If focus lost, Gui closes after 3 seconds, use hotkey to reopen (app still running in the background!)
0.185 | WSL Support: activate Capslock (autom. deactivated) to use WSL (additionalCommand not used)
0.183 | Start-parameter "imports"
0.183 | "Use imports.scc" CheckBox
0.181 | Special operation of the left \[Ctrl]-key changed, returns to the previously open window  
0.180 | Special operation of the left \[Ctrl]-key changed, see below ...   
0.175 | Imports mechanism: uses "--load imports--" 
0.174 | commented out replcommands are allways hidden
0.173 | codeExec section to include the two parts in one source-file, commented out replcommands are allways shown as comments
0.172 | \[Config-file] ->  additionalCommand \*1)
0.170 | Selects correct console window if already open
0.168 | JAVA_HOME etc. settings removed, use [Selja](https://github.com/jvr-ks/selja) to select Java!  
0.167 | Blanks in entry-names allowed, but must be surrounded by quotation marks then.

\*1) send  to console after "title", example: additionalCommand=chcp 65001

#### Known issues / bugs 

Issue / Bug | Type | fixed in version
------------ | ------------- | -------------
Ctrl + E copies old contents | bug | 0.179 
Blanks in entry-names not allowed | issue | 0.167  
  
 
    
##### Usage  

* Start sbt_console_select by a doubleclick onto the file "sbt_console_select.exe".  
or  
* drag the "sbt_console_select.exe" to the taskbar.  
or  
* create a shortcut of "sbt_console_select.exe" in the windows-autostart folder ("shell:startup")  
and add "hidewindow" as a parameter.  
Two powershell scripts included:  
"create_sbt_console_select_exe_link_hidewindow_in_autostartfolder.bat"
or  
to be used with the project [startdelayed](https://github.com/jvr-ks/startdelayed):  
"create_sbt_console_select_exe_link_hidewindow.bat"

or manually:   
-> "sbt_console_select - Shortcut.lnk" -> rightclick -> properties -> target -> add "hidewindow" as a parameter,  
(and optional the Command-file and Config-file path),  
then start with the hotkey.  

Click an entry in the list to start the command as defined in "sbt_console_select.txt".  

##### Hotkey operations supplied by the app  
 
[Overview of all default Hotkeys used by my Autohotkey "tools"](https://github.com/jvr-ks/cmdlinedev/blob/master/hotkeys.md)  
   
(default -> \[Config-file]):  

* menuhotkey: **\[ALT] + \[t]** -> open menu,    
* exitHotkey: **\[SHIFT] + \[ALT] + \[t]** -> sends \[CTRL] + \[d] and "exit",   

* replLoadHotkey: **\[ALT] + \[e]**  
or  
* **\[CTRL] + \[e]**  
(use only the selected code).  
  
The code is saved to the temporary file "repl.tmp".  
Then the "[replcommands]"-section of the \[Config-file] is used, to execute the code, see below.  
(Using the ":load repl.tmp" REPL-command, so only Scala-code is allowed, not REPL-commands!).  

##### Special operation of the left \[Ctrl]-key after replLoadHotkey was executed:  
Pressing the left \[Ctrl]-key activates the last open window.  

* replLoadExecHotkey: **\[SHIFT] + \[ALT] + \[e]**  
   
The code is saved to the temporary file "replExec.tmp".  
Can be used if code execution must consist of two parts.  
  
Execute the "[replcommands]"-section of the \[Config-file]:  
The \[Config-file] contains commands of the form:  
replcommand1=  
replcommand2=  
...  
which are executed from top to down, i.e. 1,2,3 ...  
  
There are 2 "dummy" commands defined internally:  
>--load the code--  

and  

>--load the codeExec--  
  
If "replcommandN=--load the code--" is reached,  
the content of the file "repl.tmp" is executed.  
  
If "replcommandN=--load the codeExec--" is reached,  
the content of the file "replExec.tmp" is executed.
 
The default "[replcommands]"-section of the \[Config-file] looks like:  

```
[replcommands]  
replcommand1=--load the code--  
replcommand2=--load the codeExec--  
```  

"replcommand2=" is only needed, if the two code execution sections are used.
 
To inactivate the second execution section mechanism you can:  
* Mark "//" in your code and press the replLoadExecHotkey again,  
* Remove the content of "replExec.tmp" in your sbt_console_select-directory,  
* Remove the file "replExec.tmp" in your sbt_console_select-directory,  
* Press **\[CTRL] + \[r]**, but this cleans the REPL too,  
* take a look at the "codeExec section" below.  
   
If you allways need a reset before executing, just add it as the first command:  
  
```
[replcommands]  
replcommand1=:reset  
replcommand2=--load the code--  
replcommand3=--load the codeExec--  
```

Comment out any commands with "//".  
All SBT console commands are usable, i.e. ":load" etc. .  
  
The SBT-console is identified by its title with an id created from actual time.  
  
After SBT has finished execution, press the **\[CTRL]**-key to bring the Notepad\++ window to the foreground again.
  
Remember: SBT-Console depends on "build.sbt" and the files in the "project"-subfolder!   

Why not using a direct "replcommand1=:load repl.tmp" instead the --load the code-- mechanism?  
It's because the "repl.tmp"-file is allways in the sbt_console_select-directory!  
(so you can use the "replcommand1=:load path_to_sbt_console_select-directory\repl.tmp") ...  
Off course you can load any other file,
example with "imports.ssc"-file in the running directory:  
"imports.ssc"-file:
  
```
// imports.ssc

import scala.language.postfixOps
```
  
```
[replcommands]  
replcommand1=//:reset  
replcommand2=:load imports.ssc  
replcommand3=--load the code--  
replcommand4=--load the codeExec--  
```

There is a special hardcoded feature to only load "imports.ssc" once!  
Press the replResetHotkey to load it again on next run.  

\*1) Sends Ctrl + C keys or Ctrl + A, Ctrl + C keys to your editor.  
\*2) Drawback: Code is inserted as a block, you cannot navigate thru each line afterwards.  
  
* replResetHotkey: **\[CTRL] + \[r]**  
Executes a ":reset" REPL-command, deletes the "replExec.tmp"-file and resets "importsLoaded".  
  
##### Imports mechanism  
  
It is annoying to repeatedly load the imports (using ":load imports.ssc").  
Instead use "replcommandN=--load imports--" to run ":load imports.ssc" only once!  
(at first start and after pressing replResetHotkey, the Name "imports.ssc" is hardcoded).  
There is a checkbox to enable/disable the imports mechanism.  
The start-parameter "imports / noimports" activates / deactivates the imports mechanism for this session, 
regardless of the checkbox status.  
   
##### codeExec section  
  
Add this comment lines to the code to automatically load the "replExec.tmp"-file:  
```
/** codeExec section  
...  
*/  
```
 
Example 1:  
```
/** codeExec section  
println("Hello ") // codeline 1  
println("world!") // codeline 2  
*/  
```
  
Example 2:  
``` 
import cats.effect.{IO, IOApp}  
import cats.effect.unsafe.implicits._     
  
object Main extends IOApp.Simple:  
  val run = IO.println("Hello, World!")   
end Main  
  
/** codeExec section  
Main.run.unsafeRunSync()  
*/   
```
  
Hint:  
Can be used to inactivate the second execution section mechanism too, just use an empty section:  
```
/** codeExec section  
*/  
```
   
##### Setting Java and Scala versions  

Use [Selja](https://github.com/jvr-ks/selja) and [Selsca](https://github.com/jvr-ks/selsca) to set the approbiate versions.  
Using SBT:   
Scala-version: SBT uses the definition in the file "build.sbt"  

##### Remarks

* Do not change the Console-Window if the last command has not started!  
* Last opened (by sbt_console_select) Console-Window is peferred over other Console-Windows running. 
* Can be used not only to start sbt but many other tools, starts a %comspec% shell if command-field is emtpy.
* REPL Past mode:  
* * Just prepend code with :paste, mark the code and press a replLoadHotkey.   
* * No Ctrl+D is needed, past-mode ends when the file-end is reached.  


##### Configure "sbt_console_select":  

* Click on \[Edit] -> \[Edit Command-file], edit the last line ", sbt -sbt-version 1.5.4 consoleQuick,graalvm11_203", replace "graalvm11_203" with your just configured Java/JDK name, save, close editor  
(-sbt-version 1.5.4 is added because there is not "project/build.properties"-file yet (is created then),  
the path is not set, so using the actual path of the "sbt_console_select.exe")    
  
##### Start REPL

(SBT must be installed!) 
* Using included files "build.sbt" and "scalafxTest2.sc" which is [based on https://github.com/scalafx/scalafx/blob/master/scalafx-demos/src/main/scala/scalafx/ColorfulCircles.scala](https://github.com/scalafx/scalafx/blob/master/scalafx-demos/src/main/scala/scalafx/ColorfulCircles.scala)
* Type \[Alt] + \[t] to reopen sbt_console_select
* Click on the last entry, sbt consoleQuick is started  
* It takes a moment to start the REPL, (using included file "built.sbt") 
* Type ":load scalafxTest2.sc"  
* After closing the demo, type \[Shift] + \[Alt] + \[t] to close the REPL (sends \[Ctrl] + \[D] and "exit")
* For ScalaFX us \[Ctrl] + \[D] then \[Arrow Up] then ":load scalafxTest2.sc" to restart

##### Executable  

* "sbt_console_select.exe"  
* "sbt_console_select.exe" \[Command-file] \[Config-file] \[hidewindow] \[remove]   
 
\[Command-file], \[Config-file] see below
\[hidewindow] = the word "hidewindow" 
\[remove] = the word "remove" , remove app from memory (to compile a new one)  

##### Configuration  

* \[Config-file], default is "sbt_console_select.ini",  
contains name=value pairs,  
divided by different \[sections].
Currently:  
- Hotkey definitions  
- Path to Notepad\++, emailapp and filemanager. 
   
The Config-file **must** have the extension *.ini  
  
Only simple Hotkey modifications are reflected in the menu.  
(Parsing is limited to \[CTRL], \[ALT], \[WIN], \[SHIFT]).  
  
  
##### Startparameter / Autostart  

Startparameter |  action
------------ | ------------- 
hidewindow | start app in the background  
Command-number: 1 or 2 ... N | autostart this command (app stays in the background afterwards)
Config-file | must have extension ".ini"
Command-file | must have extension ".txt"
remove | removes app from memory
  
##### Sourcecode: [Autohotkey format](https://www.autohotkey.com)  

* "sbt_console_select.ahk".  
  
##### Requirements  

* Windows 10 or later only.  
* Installed [SBT](https://www.scala-sbt.org/)  
* Portable app, nothing to install. 
  
##### Sourcecode  

Github URL [github](https://github.com/jvr-ks/sbt_console_select).  

##### License: MIT  

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sub-license, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANT-ABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  
  
Copyright (c) 2020/2021 J. v. Roos  


##### Virus check at Virustotal 
[Check here](https://www.virustotal.com/gui/url/ff99979467dfc66771a6fc4ea2525f0071804ae60257147bee1b05f626c48eb8/detection/u-ff99979467dfc66771a6fc4ea2525f0071804ae60257147bee1b05f626c48eb8-1644515767
)  
Use [CTRL] + Click to open in a new window! 
