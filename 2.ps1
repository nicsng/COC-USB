(Get-WmiObject -Class Win32_OperatingSystem).Caption + ' ' + (Get-WmiObject -Class Win32_OperatingSystem).Version
(Get-WmiObject -Class Win32_BIOS).Manufacturer + ' ' + (Get-WmiObject -Class Win32_BIOS).Version
(Get-WmiObject -Class Win32_ComputerSystem).Manufacturer + ' ' + (Get-WmiObject -Class Win32_ComputerSystem).Model
(Get-WmiObject -Class Win32_Processor).Name + ' ' + (Get-WmiObject -Class Win32_Processor).NumberOfCores + ' Cores'
(Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -ne $null }).Description + ' ' + ($_.IPAddress -join ', ') | Add-Content -Path $logPath
Get-NetIPAddress | Format-Table -AutoSize
Get-WmiObject -Class Win32_PhysicalMemory | Format-Table Manufacturer, Capacity -AutoSize
Get-WmiObject -Class Win32_QuickFixEngineering | Format-Table Description, HotFixID, InstalledOn -AutoSize
(Get-WmiObject -Class Win32_DiskDrive | ForEach-Object { $_.Model + ' ' + [math]::Round($_.Size/1GB, 2) + ' GB' })
(Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime
(Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true }).Name
(Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | Format-Table Name, CPU -AutoSize)
Get-HotFix | Format-Table InstalledOn, Description, HotFixID -AutoSize
(Get-TimeZone).Id + ' Timezone: ' + (Get-TimeZone).StandardName
Get-Culture | Select-Object -ExpandProperty DisplayName
Invoke-RestMethod -Uri ('http://ipinfo.io/json') | Select-Object ip, city, region, country, loc