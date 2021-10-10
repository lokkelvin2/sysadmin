# Entry script to pass cmdprmpt variables into main powershell script
# Separate into another script for readability
Param(
    [Parameter(Mandatory=$True)]
    [string]$filePath,
    [Parameter(Mandatory=$True)]
    [string]$currentUser,
    [Parameter(Mandatory=$True)]
    [string]$userProfile

)

# Script Path is the name of the main script
$scriptPath = "$filePath\mainv8.ps1"

# Desktop is the path of the user's desktop
$DESKTOP = "$userProfile\desktop"

# Nasty bug occurs when $variables have whitespace in them.
# ArgumentList internally implements a ArgumentList.join(' ') which targets all white spaces.
# Use this patch to force powershell variables into the string values, and append double quotes to the head and tail
start-process powershell.exe -verb RunAs -ArgumentList "-executionpolicy bypass -file", '"', $scriptPath, '"', '"' ,$currentUser,'"', '"', $DESKTOP, '"'