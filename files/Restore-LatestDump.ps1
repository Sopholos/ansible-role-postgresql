#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$DestinationDB,
	[parameter(Mandatory=$true)][string]$BackupFolder,
	[parameter(Mandatory=$true)][string]$BackupFileFilter,
	[parameter(Mandatory=$true)][string]$QueryFile
)

$scriptDir = Split-Path $PSCommandPath

function Find-Dump {
	param(
		[parameter(Mandatory=$true)][string]$path,
		[parameter(Mandatory=$true)][string]$filter
	)

	Write-Host "Searching for $filter inside $path"

	$file = Get-ChildItem $path -Filter $filter | Sort-Object LastWriteTime | Select-Object -last 1

	return $file.FullName -replace '\.done$', ''
}

function Restore-DB {
	param(
		[parameter(Mandatory=$true)][string]$destdb,
		[parameter(Mandatory=$true)][string]$sourceFile
	)

	$warning = $false;

	Write-Host "Restoring $destdb from source $sourceFile"

	Write-Host "Dropping $destdb"
	&dropdb "--force" $destdb

	&createdb $destdb
	if (0 -eq $LASTEXITCODE) {
		Write-Host -ForegroundColor Green "Created $destdb"
	}
	else {
		Write-Error "Creating $destdb failed"
	}

	$cpuCount = [Environment]::ProcessorCount - 2
	
	Write-Host "&pg_restore" "--jobs=$cpuCount" "--dbname=$destdb" "$sourceFile"
	&pg_restore "--jobs=$cpuCount" "--dbname=$destdb" "$sourceFile"

	if (0 -eq $LASTEXITCODE) {			
		Write-Host -ForegroundColor Green "Restored $sourceFile to $destdb"
	}
	else {
		$warning = $true
		Write-Host -ForegroundColor Yellow "Restored $sourceFile to $destdb with warnings"
	}

	return $warning
}

$ErrorActionPreference = "Stop"
$start = Get-Date

try {
	$env:LC_MESSAGES="C"
	$env:PGOPTIONS='-c lc_monetary=C'

	$sourceFile = Find-Dump $BackupFolder $BackupFileFilter

	$warning = Restore-DB `
		-destdb $DestinationDB `
		-sourceFile $sourceFile

	if ($null -ne $QueryFile) {
		/usr/local/bin/Invoke-PgSQLFile.ps1 -File $QueryFile -Database $DestinationDB
	}

	if ($warning) {
		throw "restored with warnings"
	}
	else {
		Write-Host -ForegroundColor Green "Restored all successfully"
	}
}
finally {
	Write-Host "Took: " ((Get-Date) - $start)
}