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
	
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\60\dump\" -31
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\51\dump\" -31
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\geo2\dump\" -31	
	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\wb\15-main\dump\" -31	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\ge\15-main\dump\" -31	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\mn\15-main\dump\" -31	
	
	#Cleanup-Folder -folder "e:\Backups\PostgreSQL\60\dump\" -31	
	#Cleanup-Folder -folder "e:\Backups\PostgreSQL\51\dump\" -31
}
catch {
    throw
}
