#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$PostgresqlUser,
	[parameter(Mandatory=$false)][string]$QueryPostgresqlUser,
	[parameter(Mandatory=$false)][string]$QueryPostgresqlPassword,
	[parameter(Mandatory=$true)][string]$PostgresqlHost,
	[parameter(Mandatory=$true)][int]$PostgresqlPort,
	[parameter(Mandatory=$false)][bool]$TestArchive = $true,
	[parameter(Mandatory=$true)][string]$BackupFolder
)
$ErrorActionPreference = "Stop"
try
{
	if ((/usr/local/bin/Get-PGIsInRecovery `
			-PostgresqlHost $PostgresqlHost `
			-PostgresqlPort $PostgresqlPort `
			-PostgresqlUser $QueryPostgresqlUser `
			-PostgresqlPassword $QueryPostgresqlPassword) -eq $true) {
		Write-Host -ForegroundColor Yellow "Postgresql is in restoring state"
		return;
	}

	$7zipPath = "/usr/bin/7za"
	if (!(Test-Path -Path $7zipPath)) {
		$7zipPath = "/usr/lib/p7zip/7z"
	}

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
	$BackupPath = Join-Path $BackupFolder -ChildPath "$date.7zbk"

	&pg_basebackup `
		--progress `
		--username=$PostgresqlUser `
		--pgdata=$BackupPath `
		--wal-method=stream `
		--format=tar `
		--checkpoint=fast `
		--compress=1 `
		--host=$PostgresqlHost `
		--port=$PostgresqlPort

	if ($LASTEXITCODE -ne 0) { throw "pg_basebackup exited with code $LASTEXITCODE." }

	if ($TestArchive) {
		$gz = Join-Path $BackupPath "base.tar.gz"
		&$7zipPath `
			t $gz

		if ($LASTEXITCODE -ne 0) { throw "7z test exited with code $LASTEXITCODE." }

		$gz = Join-Path $BackupPath "pg_wal.tar.gz"
		if (Test-Path -Path $gz) {
			&$7zipPath `
				t $gz

			if ($LASTEXITCODE -ne 0) { throw "7z test wal exited with code $LASTEXITCODE." }
		}
	}

	$doneFile = "$BackupPath.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
}
catch {
	throw
}