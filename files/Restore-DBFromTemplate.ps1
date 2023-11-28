#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$DestinationDB,
	[parameter(Mandatory=$true)][string]$SourceDB
)

function Invoke-PgSQL {
	param(
		[parameter(Mandatory=$true)][string]$sql,
		[parameter(Mandatory=$false)][string]$database = "postgres"
	)

	Write-Host "Executing against $database query $sql"

	&psql "--dbname=$database" "--command=$sql"
	if (0 -ne $LASTEXITCODE) {
		throw "Failed to start: $LASTEXITCODE psql"
	}
}

function Stop-Sessions {
	param(
		[parameter(Mandatory=$true)][string]$destdb
	)

	Invoke-PgSQL -sql "select pg_terminate_backend(pid) as pg_terminate_backend_$destdb from pg_stat_activity where datname='$destdb';"
}

$ErrorActionPreference = "Stop"
$start = Get-Date

try {
	$env:LC_MESSAGES="C"
	
	Write-Host "Restoring $DestinationDB from $SourceDB"

	Write-Host "Dropping $DestinationDB"
	&dropdb "--force" $DestinationDB

	Stop-Sessions $SourceDB
	Invoke-PgSQL "create database $DestinationDB template $SourceDB"
		
	Write-Host -ForegroundColor Green "Restored successfully"	
}
finally {
	Write-Host "Took: " ((Get-Date) - $start)
}