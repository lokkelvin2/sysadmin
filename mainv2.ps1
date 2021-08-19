# Get list of installed software
# Version 2: Remove KB updates from list
#

$NAME = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$NAME = $NAME -replace '\\','_'
Write-Output "Generating Report for $NAME"


$OUTPUTFOLDER = [Environment]::GetFolderPath("Desktop")
$FILENAME = "InstalledSoftwarev2_$NAME.csv"
$FPATH = Join-Path -Path $OUTPUTFOLDER -ChildPath $FILENAME
$REG_PATH = @()

if (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
}
if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
}
if (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
}
if (Test-Path "HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
}


$OUTPUT = Get-ItemProperty $REG_PATH| 
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent,ParentDisplayName  | 
                Where-Object {$_.SystemComponent -ne 1 -and $_.DisplayName -and !$_.ParentDisplayName}|
                    Sort-Object Publisher, DisplayName

$count = 1
$OUTPUT = $OUTPUT | ForEach-Object {
    $_ |  Select-Object @{Name = 'Line'; Expression = {$count}}, *
    $count++ }

$OUTPUT| Format-Table -AutoSize
$OUTPUT| Export-Csv $FPATH -NoTypeInformation

$OUTPUT_stats = $OUTPUT | measure

Write-Output "Found $(($OUTPUT_stats).Count) installed applications"
Write-Output "Saving output to $FPATH"
Write-Output "Done"

# Ways to get hostname and username
# [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# $env:UserName
# $env:UserDomain
# $env:ComputerName
# hostname

# get writable paths
# [Environment]::GetFolderPath("Desktop")
# [enum]::GetNames( [System.Environment+SpecialFolder] )
