#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$PostgresqlUser,
	[parameter(Mandatory=$true)][string]$PostgresqlPassword,
	[parameter(Mandatory=$false)][string]$QueryPostgresqlUser,
	[parameter(Mandatory=$false)][string]$QueryPostgresqlPassword,
	[parameter(Mandatory=$true)][string]$PostgresqlHost,
	[parameter(Mandatory=$true)][int]$PostgresqlPort,
	[parameter(Mandatory=$true)][string]$Database,
	[parameter(Mandatory=$true)][string]$BackupFolder,
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Endpoint = '',
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Profile = ''
)
$ErrorActionPreference = "Stop"

$start = Get-Date

try
{
	$env:LC_MESSAGES="C"
	$env:PGOPTIONS='-c lc_monetary=C'

	if ((/usr/local/bin/Get-PGIsInRecovery `
			-PostgresqlHost $PostgresqlHost `
			-PostgresqlPort $PostgresqlPort `
			-PostgresqlUser $QueryPostgresqlUser `
			-PostgresqlPassword $QueryPostgresqlPassword) -eq $true) {
		Write-Host -ForegroundColor Yellow "Postgresql is in restoring state"
		return;
	}

	$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"
	$dburl = "postgresql://${PostgresqlUser}:$PostgresqlPassword@${PostgresqlHost}:$PostgresqlPort/$Database"

	if ($s3Endpoint -or $s3Profile -or $BackupFolder.StartsWith('s3://')) {
		$backupFile = "$BackupFolder/${Database}_$date.dmbk"

		$pgArgs = @(
			"--dbname=$dburl",
			"--format=c",
			"--compress=1"
		)

		$awsArgs = @(
			"s3", "cp",
			"-",
			$backupFile
		)
		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}
		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		&pg_dump $pgArgs | &aws @awsArgs

		if ($LASTEXITCODE -ne 0) { throw "aws s3 cp exited with code $LASTEXITCODE." }
		Write-Host "Backed up $backupFile"

		$pgArgs = @(
			"--list"
		)

		$awsArgs = @(
			"s3", "cp",
			$backupFile,
			"-"
		)
		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}
		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		&aws @awsArgs |	&pg_restore $pgArgs

		if ($LASTEXITCODE -ne 0) { throw "pg_restore exited with code $LASTEXITCODE." }
		Write-Host "Validated $backupFile"

		$doneFile = $backupFile + ".done"

		$awsArgs = @(
			"s3", "cp",
			"-",
			$doneFile
		)
		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}
		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | &aws @awsArgs

		if ($LASTEXITCODE -ne 0) { throw "aws s3 cp done file exited with code $LASTEXITCODE." }
		Write-Host "Wrote $doneFile"
	}
	else {
		New-Item -ItemType Directory -Force -Path $BackupFolder

		$backupFile = Join-Path $BackupFolder "${Database}_$date.dmbk"

		$pgArgs = @(
			"--dbname=$dburl",
			"--format=c",
			"--compress=1",
			"--file=$backupFile"
		)

		&pg_dump $pgArgs

		if ($LASTEXITCODE -ne 0) { throw "pg_dump exited with code $LASTEXITCODE." }
		Write-Host "Backed up $backupFile"

		$pgArgs = @(
			"--list",
			$backupFile
		)

		&pg_restore $pgArgs

		if ($LASTEXITCODE -ne 0) { throw "pg_restore exited with code $LASTEXITCODE." }
		Write-Host "Validated $backupFile"

		$doneFile = $backupFile + ".done"
		$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
		Write-Host "Wrote $doneFile"
	}

	Write-Host -ForegroundColor Green "Backed up successfully into $backupFile"
}
catch {
	throw
}
finally {
	Write-Host "Took: " ((Get-Date) - $start)
}
