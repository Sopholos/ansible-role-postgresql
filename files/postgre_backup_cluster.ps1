#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$PostgresqlUser,
	[parameter(Mandatory=$true)][string]$PostgresqlHost,
	[parameter(Mandatory=$true)][int]$PostgresqlPort,
	[parameter(Mandatory=$true)][string]$BackupFolder
)
$ErrorActionPreference = "Stop"
try
{
	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
	$BackupPath = Join-Path $BackupFolder -ChildPath "$date"

	pg_basebackup --progress `
		--username=$PostgresqlUser `
		--pgdata=$BackupPath `
		--wal-method=stream `
		--format=tar `
		--checkpoint=fast `
		--compress=9 `
		--host=$PostgresqlHost `
		--port=$PostgresqlPort

	if ($LASTEXITCODE -ne 0) { throw "pg_basebackup exited with code $LASTEXITCODE." }

	$doneFile = Join-Path $BackupPath "backup_manifest.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile

	$doneFile = Join-Path $BackupPath "pg_wal.tar.gz.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile

	$doneFile = Join-Path $BackupPath "base.tar.gz.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
}
catch {
    throw
}