# Get list of installed applications on windows

## Using powershell to query Registry
**Note** 
- `HKLM` is for local machine installations
- `HKCU` is for current user installations
- `Wow6432Node` is for 32bit apps running on 64bit windows
- Portable apps should not write to registry and so will not show up in these lists

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



## Others
Script from
[#1603935](https://superuser.com/a/1603935) filters away the hidden system components
```powershell
foreach ($UKey in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKCU:\SOFTWARE\Wow6432node\Microsoft\Windows\CurrentVersion\Uninstall\*'){foreach ($Product in (Get-ItemProperty $UKey -ErrorAction SilentlyContinue)){if($Product.DisplayName -and $Product.SystemComponent -ne 1){$Product.DisplayName}}}
```