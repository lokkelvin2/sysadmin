@echo off
::powershell.exe -noprofile -NoExit -command "&{start-process powershell -ArgumentList '-NoExit -noprofile -file \"%~dp0\mainv6.ps1\"' -verb RunAs}"
powershell.exe -noprofile -NoExit -command "&{start-process powershell -ArgumentList '-noprofile -file \"%~dp0\mainv6.ps1\"' -verb RunAs}"