# Get list of installed software
# Version 2: Remove KB updates from list
# Version 3: 1) Remove SystemComponent and ParentDisplayName (kb updates) filter
#            2) Include list of UWP apps for all users (may or may not work on Windows 7)
#            3) Get every HKCU by searching HKEY_USERS

$NAME = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$NAME = $NAME -replace '\\','_'
Write-Output "Generating Report for $NAME"


$OUTPUTFOLDER = [Environment]::GetFolderPath("Desktop")
$FILENAME = "InstalledSoftwarev3_$NAME.csv"
$FPATH = Join-Path -Path $OUTPUTFOLDER -ChildPath $FILENAME
$REG_PATH = @()

if (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
}
if (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
}
# From https://stackoverflow.com/q/52363926
# SID explanation
# https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab 
$Users = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where {$_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } | #regex looking for pattern of 4 x digits and hypen for 3 domain ID and 1 relative ID
                Select-Object @{Name="SID"; Expression={$_.PSChildName}}, @{Name="UserFolder"; Expression={$_.ProfileImagePath}}

foreach ($User in $Users){
    # Check each HKU
    if (Test-Path "Registry::HKEY_USERS\$($User.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"){
        $REG_PATH += "Registry::HKEY_USERS\$($User.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }
    if (Test-Path "Registry::HKEY_USERS\$($User.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"){
        $REG_PATH += "Registry::HKEY_USERS\$($User.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }
}

$OUTPUT = Get-ItemProperty $REG_PATH| 
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent,ParentDisplayName  | 
                Where-Object {$_.DisplayName}|
                    Sort-Object Publisher, DisplayName

try{
    $UWP_OUTPUT = Get-AppxPackage -AllUsers|
                    Select-Object @{Name='DisplayName';Expression={$_.Name}},@{Name='DisplayVersion';Expression={$_.Version}},@{Name='Publisher';Expression={$_.Publisher}}

    $OUTPUT += $UWP_OUTPUT
}
catch{
    # Will windows 7 run into an error?
    Write-Host "Error occured with Get-AppxPackage"
}
$count = 1
$OUTPUT = $OUTPUT | ForEach-Object {
    $_ |  Select-Object @{Name = 'Line'; Expression = {$count}}, *
    $count++ }

$OUTPUT| Format-Table -Autosize

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