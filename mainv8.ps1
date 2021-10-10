# Get list of installed software
# Version 2: Remove KB updates from list
#
# Version 3: 1) Remove SystemComponent and ParentDisplayName (kb updates) filter
#            2) Include list of UWP apps for all users (may or may not work on Windows 7)
#            3) Get every HKCU by searching HKEY_USERS
#
# Version 4: 1) Checks if appx fails due to privileges
#            2) Added appx column
#
# Version 5: 1) Resolve appx displaynames to human readable names (not sure if win 7 will throw a tantrum)
#            2) Remove duplicate entries (not sure why there are duplicates anyway)
#            3) Save information on program owner (SYSTEM or USERNAME)
#
# Version 6: 1) Bug fixes
#
# Version 7: 1) Fixed issue with variable passing between user process and admin process
#            2) Added time stamp
#
# Version 8: 1) Fixed whitespace bug with ArgumentList

Param(
    [Parameter(Mandatory=$True)]
    [string]$currentUser2,
    [Parameter(Mandatory=$True)]
    [string]$desktop2

)
#$NAME = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
# Due to the quirk of the ArgumentList patch, there will be whitespace appended to the head of the string variable
if ($currentUser2[0] -eq ' '){
    # Another quirk of PS is the array indexing and slicing operation
    # [1..N-2] removes the first space and the tail space 
    $NAME = $currentUser2[1..($currentUser2.Length-2)] -join''  
}
else{
    $NAME = $currentUser2
}
$NAME = $NAME -replace '\\','_'
Write-Output "Generating Report for $NAME"


#$OUTPUTFOLDER = [Environment]::GetFolderPath("Desktop")
if ($desktop2[0] -eq ' '){
    $OUTPUTFOLDER = $desktop2[1..($desktop2.Length-2)] -join''  
}
else{
    $OUTPUTFOLDER = $desktop2
}
$FILENAME = "AdminSoftwarev8_$($NAME)_$(Get-Date -format "yyyy-MM-dd").csv"
$FPATH = Join-Path -Path $OUTPUTFOLDER -ChildPath $FILENAME


########################################################
## Installed programs (x64 and x86) from registry 
########################################################
# List programs installed in HKLM as SYSTEM
$OWNER = "SYSTEM"
$REG_PATH = @()
if (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
}
if (Test-Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"){
    $REG_PATH += "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
}

# Get list of programs per hklm
$OUTPUT_SYSTEM = Get-ItemProperty $REG_PATH| 
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, @{Name='Owner';Expression={$OWNER}}, SystemComponent,ParentDisplayName,@{Name='UWP (Store/Metro)';Expression={}}  | 
                    Where-Object {$_.DisplayName}


# List programs installed by every user by looking through HKU for every user's SID
# Adapted from https://stackoverflow.com/q/52363926
# SID explanation https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-dtyp/81d92bba-d22b-4a8c-908a-554ab29148ab 
$Users = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*" |
                Where {$_.PSChildName -match "S-1-5-21-(\d+-?){4}$" } | #regex looking for pattern of 4 x digits and hypen for 3 domain ID and 1 relative ID
                Select-Object @{Name="SID"; Expression={$_.PSChildName}}, @{Name="UserFolder"; Expression={$_.ProfileImagePath}}

$OUTPUT_USERS = @()
foreach ($User in $Users){
    # Check each HKU
    $REG_PATH = @()
    if (Test-Path "Registry::HKEY_USERS\$($User.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"){
        $REG_PATH += "Registry::HKEY_USERS\$($User.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }
    if (Test-Path "Registry::HKEY_USERS\$($User.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"){
        $REG_PATH += "Registry::HKEY_USERS\$($User.SID)\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    }
    # Convert SID back into account name
    $OWNER = (New-Object System.Security.Principal.SecurityIdentifier($User.SID)).Translate([System.Security.Principal.NTAccount]).value

    # Get list of programs per user
    if ($REG_PATH){
        $OUTPUT_USER = Get-ItemProperty $REG_PATH| 
                        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, @{Name='Owner';Expression={$OWNER}}, SystemComponent,ParentDisplayName,@{Name='UWP (Store/Metro)';Expression={}}  | 
                            Where-Object {$_.DisplayName}

        if ($OUTPUT_USER){
            # Append to big list
            $OUTPUT_USERS += $OUTPUT_USER # May be slow if there are many users
        }
    }
}

$OUTPUT = $OUTPUT_SYSTEM + $OUTPUT_USERS

# Remove duplicate entries (not sure why there are even duplicate entries)
$OUTPUT = $OUTPUT | Sort-Object DisplayName, DisplayVersion, Owner -Unique


########################################################
## Installed UWP (Metro/ Windows store) apps
########################################################
# From MIT-Licensed Github snippet https://github.com/skycommand/AdminScripts/blob/67701785cf74a43c2d74d4f2111f9191e8df244b/AppX/Inventory%20AppX%20Packages.ps1
# Uses shlwapi to resolve indirect strings in registry 
# See for explanation https://docs.microsoft.com/en-us/windows/win32/api/shlwapi/nf-shlwapi-shloadindirectstring 
$CSharpSHLoadIndirectString = @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public class IndirectStrings
{
  [DllImport("shlwapi.dll", BestFitMapping = false, CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = false, ThrowOnUnmappableChar = true)]
  internal static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, uint cchOutBuf, IntPtr ppvReserved);
  public static string GetIndirectString(string indirectString)
  {
    StringBuilder lptStr = new StringBuilder(1024);
    int returnValue = SHLoadIndirectString(indirectString, lptStr, (uint)lptStr.Capacity, IntPtr.Zero);
    return returnValue == 0 ? lptStr.ToString() : null;
  }
}
'@

# Add the IndirectStrings type to PowerShell
Add-Type -TypeDefinition $CSharpSHLoadIndirectString -Language CSharp

# Get a list of Appx packages
$UWP_OUTPUT = @()
$AppxPackages = $null
$AppxIdentities = $null
try{
    $AppxPackages = Get-AppxPackage -AllUsers    
}
catch{
    try{
        # Error because of privileges?
        # Try again with current user
        $AppxPackages = Get-AppxPackage
        Write-Host "Error occured with Get-AppxPackage -AllUsers."
    }
    catch{
        # Error due to windows 7 not having appx command
        Write-Host "Error occured with Get-AppxPackage"
    }
}   

if ($AppxPackages)
{
    $AppxSum = $AppxPackages.Count

    # Create an array to store Appx identities
    Class AppxIdentity {
      [ValidateNotNullOrEmpty()][string]$Name
      [string]$DisplayNameResolved
      [string]$DisplayNameRaw
      [string]$DisplayNameMan # From manifest.xml
      [string]$PublisherDisplayNameMan # From manifest.xml
      [string]$Architecture
      [string]$Version
    }
    [AppxIdentity[]]$AppxIdentities = [AppxIdentity[]]::New($AppxSum)

    # Access the AppX repository in the Registry
    for ($i = 0; $i -lt $AppxSum; $i++) {
      # These variables help make the code more compact
      # AXN, AXF and AXI respectively mean AppX Name, AppX Fullname and AppX Identity
      $AXN = $AppxPackages[$i].Name
      $AXF = $AppxPackages[$i].PackageFullName
      $AXI = New-Object -TypeName AppxIdentity

      # The first property is easy to acquire
      $AXI.Name = $AXN
      $AXI.DisplayNameMan = ($AppxPackages[$i]|Get-AppxPackageManifest).Package.Properties.DisplayName
      $AXI.Architecture = $AppxPackages[$i].Architecture
      $AXI.Version = $AppxPackages[$i].Version
      $AXI.PublisherDisplayNameMan = ($AppxPackages[$i]|Get-AppxPackageManifest).Package.Properties.PublisherDisplayName

      # Leave publisher name empty if manifest file is missing this field
      if ($AXI.PublisherDisplayNameMan -match '^ms-resource:') {
        $AXI.PublisherDisplayNameMan = ''
      }

      #The display name is stored in the Registry
      $AppxPath = "Registry::HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages\$AXF"
      If (Test-Path $AppxPath) {
        try {
          $AXI.DisplayNameRaw = (Get-ItemProperty -Path $AppxPath -Name DisplayName).DisplayName
          if ($AXI.DisplayNameRaw -match '^@') {
            $AXI.DisplayNameResolved = [IndirectStrings]::GetIndirectString( $AXI.DisplayNameRaw )
        
          } else {
            $AXI.DisplayNameResolved = $AXI.DisplayNameRaw
            if ($AXI.DisplayNameRaw -match '^ms-resource\:') {
              Write-Verbose "$($AXN) has a bad display name."
              $AXI.DisplayNameResolved = $AXN
            }
          }
        } catch {
          Write-Verbose "There are no display names associated with $($AXN)."
        }
      }
      # If there is no resolved Name, use Get-AppxPackage DisplayName
      if (-Not $AXI.DisplayNameResolved) {
        $AXI.DisplayNameResolved = $AXN
        }

      #Hand over the info
      $AppxIdentities[$i] = $AXI
    }
    # Tidy up array
    $UWP_OUTPUT += $AppxIdentities | 
                    Select-Object @{Name='DisplayName';Expression={$_.DisplayNameResolved}}, @{Name='DisplayVersion';Expression={$_.Version}}, @{Name='Publisher';Expression={$_.PublisherDisplayNameMan}} `
                    ,@{Name='UWP (Store/Metro)';Expression={1}}  |
                    Sort-Object DisplayName

    # Append UWP list to programs list
    $OUTPUT += $UWP_OUTPUT
}# TODO: How to tag uwp to a user??


########################################################
## Save csv output to desktop
########################################################
# Add line number column
$count = 1
$OUTPUT = $OUTPUT | ForEach-Object {
    $_ |  Select-Object @{Name = 'Line'; Expression = {$count}}, *
    $count++ }

# Display table in console output
$OUTPUT| Format-Table -Autosize

# Use UTF8 encoding to capture LanguageExperiencePack glyphs
$OUTPUT| Export-Csv $FPATH -NoTypeInformation -Encoding UTF8

$OUTPUT_stats = $OUTPUT | measure

Write-Output "============== STATISTICS =============="
Write-Output ""
Write-Output "Found $(($OUTPUT_stats).Count) installed applications, of which $(($UWP_OUTPUT|measure).Count) are UWP applications"
Write-Output "Breakdown of non-UWP apps:"
($OUTPUT.Owner|group) | ForEach-Object{write-output "    $($_.Count) apps from $($_.Name)"}
Write-Output ""
Write-Output "========================================"
Write-Output "Saving output to $FPATH"
Write-Output "Done"
pause