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
	$7zipPath = "/usr/lib/p7zip/7z"

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
	$BackupPath = Join-Path $BackupFolder -ChildPath "$date.7zbk"

	pg_basebackup `
		--progress `
		--username=$PostgresqlUser `
		--pgdata=- `
		--wal-method=fetch `
		--format=tar `
		--checkpoint=fast `
		--compress=0 `
		--host=$PostgresqlHost `
		--port=$PostgresqlPort `
	| `
	&$7zipPath `
		a $BackupPath `
		-si -bt -mx=1

	if ($LASTEXITCODE -ne 0) { throw "pg_basebackup exited with code $LASTEXITCODE." }

	$doneFile = "$BackupPath.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
}
catch {
    throw
}