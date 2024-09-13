#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$PostgresqlUser,
	[parameter(Mandatory=$true)][string]$PostgresqlHost,
	[parameter(Mandatory=$true)][int]$PostgresqlPort,
	[parameter(Mandatory=$false)][bool]$TestArchive = $false,
	[parameter(Mandatory=$true)][string]$BackupFolder
)
$ErrorActionPreference = "Stop"
try
{
	$7zipPath = "/usr/lib/p7zip/7z"

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
	$BackupPath = Join-Path $BackupFolder -ChildPath "$date.7zbk"

	$bashCommand = @"
	pg_basebackup \
		--username=$PostgresqlUser \
		--pgdata=- \
		--wal-method=fetch \
		--format=tar \
		--checkpoint=fast \
		--compress=none \
		--host=$PostgresqlHost \
		--port=$PostgresqlPort \
	| \
	$7zipPath \
		a $BackupPath \
		-si -bt -mx=1;

	backupStatus=`$((`${PIPESTATUS[0]} | `${PIPESTATUS[1]}));
	echo BackupStatus: `$backupStatus;
	exit `$backupStatus;
"@
	bash -c $bashCommand

	if ($LASTEXITCODE -ne 0) { throw "pg_basebackup exited with code $LASTEXITCODE." }

	if ($TestArchive) {
		&$7zipPath `
			t $BackupPath

		if ($LASTEXITCODE -ne 0) { throw "7z test exited with code $LASTEXITCODE." }
	}

	$doneFile = "$BackupPath.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
}
catch {
    throw
}