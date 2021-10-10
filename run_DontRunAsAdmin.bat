@echo off
:: This command pushes the output of 'whoami' into the variable NAMEin
for /f %%i in ('whoami') do set NAMEin=%%i

:: We call powershell twice. The first call is to set execution policy to Bypass, and feed in the second powershell call in plaintext. The second call needs to have the context of variables declared in this batch file, because environment variables here are run as a user process. If we were to declare these variables inside the elevated powershell process, we would get the variables from the admin process, which is not what we want. Next, we need to combine cmd wildcard escaping with powershell wildcard escaping. Powershell doesnt like spaces in filepaths so ensure folder and script names have no spaces.

:: this took me 3 hours to google and write

SET EntryScriptPath=%~dp0StartMain.ps1

powershell.exe -noprofile -noexit -command "&{start-process powershell -ArgumentList '-executionpolicy bypass -noprofile -file \"%EntryScriptPath%\" -filePath %~dp0 -currentUser %NAMEin% -userProfile %userprofile%' -verb RunAs}"
exit