Get-WmiObject win32_PerfFormattedData_PerfDisk_PhysicalDisk| Select @{L="{#DISKNUMLET}";E={$_.Name}} | ?{$_."{#DISKNUMLET}" -ne "_Total"} | convertto-json