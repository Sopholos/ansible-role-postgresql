#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$PostgresqlUser,
	[parameter(Mandatory=$true)][string]$PostgresqlPassword,
	[parameter(Mandatory=$true)][string]$PostgresqlHost,
	[parameter(Mandatory=$true)][int]$PostgresqlPort,
	[parameter(Mandatory=$true)][string]$Database,
	[parameter(Mandatory=$true)][string]$BackupFolder
)
$ErrorActionPreference = "Stop"

$start = Get-Date

try
{
	$env:LC_MESSAGES="C"
	$env:PGOPTIONS='-c lc_monetary=C'

	if (/usr/local/bin/Get-PGIsInRecovery -eq $true) {
		Write-Host -ForegroundColor Yellow "Postgresql is in restoring state"
		return;
	}

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"

	New-Item -ItemType Directory -Force -Path $BackupFolder

	$backupFile = Join-Path $BackupFolder "${Database}_$date.dmbk"

	pg_dump `
		--dbname=postgresql://${PostgresqlUser}:$PostgresqlPassword@${PostgresqlHost}:$PostgresqlPort/$Database `
		--format=c `
		--compress=1 `
		--file=$backupFile

	if ($LASTEXITCODE -ne 0) { throw "pg_dump exited with code $LASTEXITCODE." }

	$doneFile = $backupFile + ".done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile

	Write-Host -ForegroundColor Green "Backed up successfully"
}
catch {
    throw
}
finally {
	Write-Host "Took: " ((Get-Date) - $start)
}
