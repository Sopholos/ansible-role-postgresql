#!/snap/bin/powershell -Command
# Ansible managed
param(
        [parameter(Mandatory=$true)][string]$BackupFolder,
		[parameter(Mandatory=$true)][int]$Days
)

$ErrorActionPreference = "Stop"

function Cleanup-Folder($BackupFolder, $Days) {
		
	foreach ($File in Get-Childitem $BackupFolder -Recurse -Include *.bak,*.dmbk,*.done) {
		if ($File.LastWriteTime.Day -eq 1) {
			continue
		}
		if ($File.LastWriteTime -lt (Get-Date).AddDays($Days)) {
			del $File
		}
	}
	
	Get-ChildItem $BackupFolder -Recurse -Directory | ? { -Not ($_.EnumerateFiles('*',1) | Select-Object -First 1) } | Remove-Item -Recurse
}

try
{

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
	Cleanup-Folder $BackupFolder $Days

}

catch {
    throw
}
