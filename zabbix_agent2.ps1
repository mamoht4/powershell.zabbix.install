$zabbixfolder = 'c:\Zabbix\'
$zabbixexeold = $zabbixfolder + 'zabbix_agentd.exe'
$zabbixexe2 = $zabbixfolder + 'zabbix_agent2.exe'
$zabbixconf = $zabbixfolder + 'zabbix_agent2.win.conf'
$log = 'LogFile=' + $zabbixfolder + 'zabbix_agent2.log'
$server = "Server=servzabbix"
$serverActive = "ServerActive=servzabbix"
$hostname = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname
$hostvalue = "Hostname=" + $hostname

# Add custom UserParameters 
$userParameter1 = 'UserParameter=windowsdisk.discovery, powershell -NoProfile -ExecutionPolicy Bypass -File c:\Zabbix\Scripts\get-disks.ps1'
$userParameter3 = 'UserParameter=lsi.raid[*], powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -File "C:\zabbix\lsi-raid.ps1" $1 $2 $3 $4'
$userParameter4 = 'UserParameter=IISservises.webreqest[*], powershell -NoProfile -ExecutionPolicy Bypass -File c:\Zabbix\Scripts\webreqest-servises.ps1 $1 $2'

If($zabbixfolder) {
    Stop-Service "Zabbix Agent*"
	Wait-Event -Timeout 5
}

If($zabbixexeold) {
    .$zabbixexeold  --uninstall
	Get-ChildItem -Path $zabbixfolder -Recurse | Where-Object {$_.Name -notMatch "scripts|ps1"} | Remove-Item -Recurse -Force
}

If($zabbixexe2) {
    .$zabbixexe2  --uninstall
	Get-ChildItem -Path $zabbixfolder -Recurse | Where-Object {$_.Name -notMatch "scripts|ps1"} | Remove-Item -Recurse -Force
}


#New-Item -Name "Zabbix" -Path "c:\" -Type Directory
Copy-Item -Path \\parus31.local\Install\Install\Zabbix\ -Destination c:\ -Recurse -Force
Set-Content $zabbixconf -value $log 
Add-Content $zabbixconf -value $server 
Add-Content $zabbixconf -value $serverActive 
Add-Content $zabbixconf -value $hostvalue
Add-Content $zabbixconf -value Timeout=10

#Add UserParameters
#For physical servers
if ((systeminfo | find "System Model") -notlike "*Virtual Machine*") {
   Add-Content $zabbixconf -value $userParameter1
}

# For IIS Parus 8 servises server
if ($hostname -like "ServWebFSS*") {
   Add-Content $zabbixconf -value $userParameter4
}

#Check firewall rule
if ((Get-NetFirewallRule -DisplayName 'Zabbix').PrimaryStatus -ne "OK") {
    New-NetFirewallRule -DisplayName 'Zabbix' -Direction Inbound -Action Allow -Protocol TCP -LocalPort '10050'
}

#Check service Zabbix agent 2. Install if not exist.
if (!(Get-Service "Zabbix agent 2" -ErrorAction SilentlyContinue)) {
    .$zabbixexe2 --config $zabbixconf --install
}
Wait-Event -Timeout 5
Start-Service "Zabbix Agent 2"
