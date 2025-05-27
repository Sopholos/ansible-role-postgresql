#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$PostgresqlUser,
	[parameter(Mandatory=$false)][string]$QueryPostgresqlUser,
	[parameter(Mandatory=$false)][string]$QueryPostgresqlPassword,
	[parameter(Mandatory=$true)][string]$PostgresqlHost,
	[parameter(Mandatory=$true)][int]$PostgresqlPort,
	[parameter(Mandatory=$false)][bool]$TestArchive = $true,
	[parameter(Mandatory=$true)][string]$BackupFolder,
	[parameter(Mandatory=$false)][int]$Compress = 1,
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3TempPath = '',
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Endpoint = '',
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Profile = ''
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
	if ($s3Endpoint -or $s3Profile -or $BackupFolder.StartsWith('s3://')) {
		if (-not $s3TempPath) {
			throw "s3TempPath must be not empty"
		}

		$BackupPath = Join-Path $s3TempPath -ChildPath $date
		$s3dest = "$BackupFolder/$date"
	}
	else {
		$BackupPath = Join-Path $BackupFolder -ChildPath $date
	}

	try {
		$pgArgs = @(
			"--progress",
			"--username=$PostgresqlUser",
			"--pgdata=$BackupPath",
			"--wal-method=stream",
			"--format=tar",
			"--checkpoint=fast",
			"--compress=$Compress",
			"--host=$PostgresqlHost",
			"--port=$PostgresqlPort"
		)

		Write-Host "&pg_basebackup $pgArgs"
		&pg_basebackup $pgArgs
		if ($LASTEXITCODE -ne 0) { throw "pg_basebackup exited with code $LASTEXITCODE." }
		Write-Host "Backed up $BackupPath"

		if ($s3dest) {
			$awsArgs = @(
				"s3", "cp", "--recursive",
				$BackupPath,
				$s3dest
			)
			if ($s3Endpoint) {
				$awsArgs +="--endpoint-url", $s3Endpoint
			}
			if ($s3Profile) {
				$awsArgs += "--profile", $s3Profile
			}

			Write-Host "&aws $awsArgs"
			&aws $awsArgs
			if ($LASTEXITCODE -ne 0) { throw "aws s3 cp exited with code $LASTEXITCODE." }
			Write-Host "Copied up $s3dest"
		}
	}
	finally {
		if ($s3TempPath) {
			Remove-Item $s3TempPath/* -Recurse -Force -Verbose
		}
	}

	if ($Compress -gt 0) {
		$postfix = ".gz"
	}
	else {
		$postfix = ""
	}

	if ($TestArchive) {
		if ($s3dest) {
			function Validate-S3 {
				param(
					[parameter(Mandatory=$true)][string]$url
				)

				$fileName = Split-Path $url -Leaf

				$awsArgs = @(
					"s3", "cp",
					$url,
					"-"
				)
				if ($s3Endpoint) {
					$awsArgs +="--endpoint-url", $s3Endpoint
				}
				if ($s3Profile) {
					$awsArgs += "--profile", $s3Profile
				}

				$7zArgs = @(
					"t",
					"-si$fileName"
				)

				Write-Host "&aws $awsArgs | &$7zipPath $7zArgs"
				&aws $awsArgs | &$7zipPath $7zArgs
				if ($LASTEXITCODE -ne 0) { throw "7z exited with code $LASTEXITCODE." }
				Write-Host "Validated $url"
			}

			Validate-S3 "$s3dest/base.tar$postfix"

			$awsArgs = @(
				"s3", "ls",
				"$s3dest/pg_wal.tar$postfix"
			)
			if ($s3Endpoint) {
				$awsArgs +="--endpoint-url", $s3Endpoint
			}
			if ($s3Profile) {
				$awsArgs += "--profile", $s3Profile
			}
			Write-Host "&aws $awsArgs"
			&aws $awsArgs
			if ($LASTEXITCODE -eq 0) {
				Validate-S3 "$s3dest/pg_wal.tar$postfix"
			 }
		}
		else {
			$gz = Join-Path $BackupPath "base.tar$postfix"
			Write-Host "&$7zipPath t $gz"
			&$7zipPath t $gz
			if ($LASTEXITCODE -ne 0) { throw "7z test exited with code $LASTEXITCODE." }
			Write-Host "Validated $gz"

			$gz = Join-Path $BackupPath "pg_wal.tar$postfix"
			if (Test-Path -Path $gz) {
				Write-Host "&$7zipPath t $gz"
				&$7zipPath t $gz
				if ($LASTEXITCODE -ne 0) { throw "7z test wal exited with code $LASTEXITCODE." }
				Write-Host "Validated $gz"
			}
		}
	}

	if ($s3dest) {
		$doneFile = $s3dest + ".done"

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

		Write-Host "&aws $awsArgs"
		$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | &aws $awsArgs
		if ($LASTEXITCODE -ne 0) { throw "aws s3 cp done file exited with code $LASTEXITCODE." }
	}
	else {
		$doneFile = "$BackupPath.done"
		$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
	}
	Write-Host "Wrote $doneFile"

	Write-Host -ForegroundColor Green "Backed up successfully"
}
catch {
	throw
}