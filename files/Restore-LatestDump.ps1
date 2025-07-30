#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$false)][int]$PostgresqlPort = 5432,
	[parameter(Mandatory=$true)][string]$DestinationDB,
	[parameter(Mandatory=$true)][string]$BackupFolder,
	[parameter(Mandatory=$true)][string]$BackupFileFilter,
	[parameter(Mandatory=$true)][string]$QueryFile,
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3TempPath = '',
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Bucket = '',
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Endpoint = '',
	[parameter(Mandatory=$false)][AllowEmptyString()][string]$s3Profile = ''
)

$scriptDir = Split-Path $PSCommandPath

function Find-Dump {
	param(
		[parameter(Mandatory=$true)][string]$path,
		[parameter(Mandatory=$true)][string]$filter
	)

	Write-Host "Searching for $filter inside $path"

	if ($s3Bucket -or $s3Endpoint -or $s3Profile) {
		$awsArgs = @(
			"s3api", "list-objects-v2",
			"--bucket", $s3Bucket,
			"--prefix", $BackupFolder,
			"--query", "reverse(sort_by(sort_by(Contents[$filter], &Key), &LastModified))[:1].Key",
			"--output", "json"
		)
		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}
		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		Write-Host "&aws $awsArgs"
		$file = &aws $awsArgs

		if ($LASTEXITCODE -ne 0) { throw "aws s3api exited with code $LASTEXITCODE." }

		if (-not $file) {
			throw "aws s3api not found $s3Bucket/$BackupFolder/$filter."
		}
		Write-Host "aws found: $file"
		$file = $file | ConvertFrom-Json | Select-Object -Index 0
		if (-not $file) {
			throw "aws s3api not found $s3Bucket/$BackupFolder/$filter."
		}
		$result = $file -replace '\.done$', ''
		Write-Host "result: $result"
		return $result
	}

	$file = Get-ChildItem $path -Filter $filter | Sort-Object LastWriteTime | Select-Object -last 1

	return $file.FullName -replace '\.done$', ''
}

function Restore-DB {
	param(
		[parameter(Mandatory=$true)][string]$destdb,
		[parameter(Mandatory=$true)][string]$sourceFile
	)

	Write-Host "Restoring $destdb from source $sourceFile"

	Write-Host "Dropping $destdb"
	$msg = &dropdb "--force" $destdb
	Write-Host $msg

	$msg = &createdb $destdb
	Write-Host $msg
	if (0 -eq $LASTEXITCODE) {
		Write-Host -ForegroundColor Green "Created $destdb"
	}
	else {
		Write-Error "Creating $destdb failed"
	}

	$cpuCount = [math]::Max([Environment]::ProcessorCount - 2, 1)

	if ($s3Bucket -or $s3Endpoint -or $s3Profile) {
		if ($s3TempPath) {
			$s3dest = Join-Path $s3TempPath $sourceFile
		}
		else {
			$s3dest = "-"
		}

		$awsArgs = @(
			"s3", "cp",
			"s3://$s3Bucket/$sourceFile",
			$s3dest
		)
		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}
		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		if ($s3TempPath) {
			try {
				Write-Host "&aws $awsArgs"
				$msg = &aws $awsArgs
				Write-Host $msg
				if ($LASTEXITCODE -ne 0) { throw "aws cp exited with code $LASTEXITCODE." }
				Write-Host "Copied to $s3dest"

				$pgArgs = @(
					"--jobs=$cpuCount",
					"--dbname=$destdb",
					$s3dest
				)

				Write-Host "&pg_restore $pgArgs"
				$msg = &pg_restore $pgArgs
				Write-Host $msg
				$exitcode = $LASTEXITCODE
			}
			finally {
				Remove-Item $s3TempPath\* -Recurse -Force -Verbose -ProgressAction SilentlyContinue
			}
		}
		else {
			$pgArgs = @(
				"--dbname=$destdb"
			)

			Write-Host "&aws $awsArgs | &pg_restore $pgArgs"
			$msg = &aws $awsArgs | &pg_restore $pgArgs
			Write-Host $msg
			$exitcode = $LASTEXITCODE
		}
	}
	else {
		$pgArgs = @(
			"--jobs=$cpuCount",
			"--dbname=$destdb",
			"$sourceFile"
		)

		Write-Host "&pg_restore $pgArgs"
		$msg = &pg_restore $pgArgs
		Write-Host $msg
		$exitcode = $LASTEXITCODE
	}

	if (0 -eq $exitcode) {
		Write-Host -ForegroundColor Green "Restored $sourceFile to $destdb"

		return $true;
	}
	else {
		Write-Host -ForegroundColor Yellow "Restored $sourceFile to $destdb with warnings $exitcode"

		return $false;
	}
}

$ErrorActionPreference = "Stop"
$start = Get-Date

try {
	$env:LC_MESSAGES="C"
	$env:PGOPTIONS='-c lc_monetary=C'

	$sourceFile = Find-Dump $BackupFolder $BackupFileFilter

	$success = Restore-DB `
		-destdb $DestinationDB `
		-sourceFile $sourceFile
	Write-Host $success

	if ($null -ne $QueryFile) {
		/usr/local/bin/Invoke-PgSQLFile.ps1 `
			-PostgresqlPort $PostgresqlPort `
			-File $QueryFile -Database $DestinationDB
	}

	if ($success) {
		Write-Host -ForegroundColor Green "Restored all successfully"
	}
	else {
		throw "restored with warnings"
	}
}
finally {
	Write-Host "Took: " ((Get-Date) - $start)
}