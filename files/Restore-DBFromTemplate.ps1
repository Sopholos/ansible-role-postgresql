#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$false)][int]$PostgresqlPort = 5432,
	[parameter(Mandatory=$true)][string]$DestinationDB,
	[parameter(Mandatory=$true)][string]$SourceDB,
	[parameter(Mandatory=$true)][string]$QueryFile
)

$scriptDir = Split-Path $PSCommandPath

function Stop-Sessions {
	param(
		[parameter(Mandatory=$true)][string]$destdb
	)

	/usr/local/bin/Invoke-PgSQL.ps1 `
		-PostgresqlPort $PostgresqlPort `
		-Query "select pg_terminate_backend(pid) as pg_terminate_backend_$destdb from pg_stat_activity where datname='$destdb';"
}

$ErrorActionPreference = "Stop"
$start = Get-Date

try {
	$env:LC_MESSAGES="C"

	Write-Host "Restoring $DestinationDB from $SourceDB"

	Write-Host "Dropping $DestinationDB"
	&dropdb "--force" $DestinationDB

	Stop-Sessions $SourceDB
	/usr/local/bin/Invoke-PgSQL `
		-PostgresqlPort $PostgresqlPort `
		-Query "create database `"$DestinationDB`" template `"$SourceDB`""

	if ($null -ne $QueryFile) {
		/usr/local/bin/Invoke-PgSQLFile.ps1 `
			-PostgresqlPort $PostgresqlPort `
			-File $QueryFile -Database $DestinationDB
	}

	Write-Host -ForegroundColor Green "Restored successfully"
}
finally {
	Write-Host "Took: " ((Get-Date) - $start)
}