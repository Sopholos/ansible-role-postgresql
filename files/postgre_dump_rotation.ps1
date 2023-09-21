#!/snap/bin/powershell -Command
# Ansible managed
param(
        [parameter(Mandatory=$true)][string]$BackupFolder,
		[parameter(Mandatory=$true)][int]$Days
)

$ErrorActionPreference = "Stop"
#$logs = "e:\Logs\Tasks"

$start = Get-Date

function Cleanup-Folder($BackupFolder, $Days) {
	echo "Cleaning up: $folder"
		
	foreach ($File in Get-Childitem $BackupFolder -Recurse -Include *.bak,*.dmbk,*.done) {
		if ($File.LastWriteTime.Day -eq 1) {
			#echo "Stay $($File.Name)"
			continue
		}
		if ($File.LastWriteTime -lt (Get-Date).AddDays($Days)) {
			#echo "Remove $($File.Name)"
			del $File -Verbose
		}
	}
	
	Get-ChildItem $BackupFolder -Recurse -Directory | ? { -Not ($_.EnumerateFiles('*',1) | Select-Object -First 1) } | Remove-Item -Recurse
}

try
{

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
#	$logName = [IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
#	$log = Join-Path $logs -ChildPath "$($logName)_$date.log"	
#	Start-Transcript -Path ($log)

	Cleanup-Folder $BackupFolder $Days
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\60\dump\" -31
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\51\dump\" -31
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\geo2\dump\" -31	
	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\wb\15-main\dump\" -31	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\ge\15-main\dump\" -31	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\mn\15-main\dump\" -31	
	
	#Cleanup-Folder -folder "e:\Backups\PostgreSQL\60\dump\" -31	
	#Cleanup-Folder -folder "e:\Backups\PostgreSQL\51\dump\" -31
#	Write-Host "Cleanup finished"
}
catch {
    throw
}
#finally {
#	Write-Host "Took: " ((Get-Date) - $start)
#	Stop-Transcript
#}