# Instructions
- Download [here](https://github.com/lokkelvin2/sysadmin/archive/refs/tags/v2.zip)
- Extract folder to target computer
- run `run.bat`
- Output csv is saved to desktop

# Get list of installed applications on windows


## Using powershell to query Registry
**Note** 
- `HKLM` is for local machine installations
- `HKCU` is for current user installations
- `Wow6432Node` is for 32bit apps running on 64bit windows
- Portable apps should not write to registry and so will not show up in these lists
- HKCU displays only 1 user. If there are multiple user accounts, rerun it for all users in HKEY_USERS.


### 32 bit windows
```powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | Sort-Object Publisher, DisplayName | Format-Table -AutoSize

Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | Sort-Object Publisher, DisplayName | Format-Table -AutoSize
```

### 64 bits windows
```powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | Sort-Object Publisher, DisplayName | Format-Table -AutoSize

Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | Sort-Object Publisher, DisplayName | Format-Table -AutoSize

Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | Sort-Object Publisher, DisplayName | Format-Table -AutoSize

Get-ItemProperty HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | Sort-Object Publisher, DisplayName | Format-Table -AutoSize
```
### Saving outputs
Using the `Export-CSV` cmdlet, the table can be saved and post-processed in Excel.
``` powershell
 Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | 
        Sort-Object Publisher, DisplayName | 
            Export-Csv 'D:\Software_LocalMachine.csv'
```

### Putting it all together
```powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
    HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,
        HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*,
            HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, SystemComponent  | 
                Where-Object SystemComponent -ne 1 |
                    Sort-Object Publisher, DisplayName | 
                        Format-Table -AutoSize
```

## Others
Script from
[#1603935](https://superuser.com/a/1603935) filters away the hidden system components
```powershell
foreach ($UKey in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*'){foreach ($Product in (Get-ItemProperty $UKey -ErrorAction SilentlyContinue)){if($Product.DisplayName -and $Product.SystemComponent -ne 1){$Product.DisplayName}}}
```


### Installed Apps from microsoft store
Script from [skycommand](https://github.com/skycommand/AdminScripts/blob/67701785cf74a43c2d74d4f2111f9191e8df244b/AppX/Inventory%20AppX%20Packages.ps1) returns a human readable DisplayName for the UWP apps. It uses `SHLoadIndirectString()` from [here](https://github.com/SamuelArnold/StarKill3r/blob/master/Star%20Killer/Star%20Killer/bin/Debug/Scripts/SANS-SEC505-master/scripts/Day1-PowerShell/Expand-IndirectString.ps1).
```powershell
Get-AppxPackage -AllUsers|
    Select-Object Name, Version, Publisher|
        Format-Table -AutoSize
```


https://gist.github.com/mark05e/e9ff8067211caa51ca4556b161b0f0a7

