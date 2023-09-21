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
		
	foreach ($File in Get-Childitem $BackupFolder -Recurse -File ) { #-Include *.7z,*.7zbk,*.done,*.gz) {
	   if ($File.LastWriteTime -lt (Get-Date).AddDays($Days)) {
			#echo $File
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
	
	Cleanup-Folder  $BackupFolder $Days
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\51\full\" -21	
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\51\wal\" -15	

#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\60\full\" -21
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\60\wal\" -15
	
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\zabbix\full\" -20
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\zabbix\wal\" -15
	
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\geo2\full\" -21
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\geo2\wal\" -15
	
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\mn2\15-main\full\" -21
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\mn2\wal\" -15
#	Cleanup-Folder -folder "e:\BackupCold\PostgreSQLPersistent\mn2\15-main\wal\" -15	
	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\mn\15-main\full\" -21
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\mn\15-main\wal\" -15
	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\wb\15-main\full\" -21
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\wb\15-main\wal\" -15
	
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\ge\15-main\full\" -21
#	Cleanup-Folder -folder "e:\BackupCold\AgroterraPostgreSQLPersistent\ge\15-main\wal\" -15
	
#	Write-Host "Cleanup finished"
}
catch {
    throw
}
#finally {
#	Write-Host "Took: " ((Get-Date) - $start)
#	Stop-Transcript
#}