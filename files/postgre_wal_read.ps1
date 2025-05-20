#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$ArchiveFullPath,
	[parameter(Mandatory=$true)][string]$ArchiveName,
	[parameter(Mandatory=$true)][string]$BackupPath,
	[parameter(Mandatory=$false)][string]$s3Endpoint,
	[parameter(Mandatory=$false)][string]$s3Profile
)

$ErrorActionPreference = "Stop"
$backwal = $BackupPath

function Expand-7ZipItem {
	param(
		[parameter(Mandatory=$true)]
			[string]$Source,
		[parameter(Mandatory=$true)]
			[string]$Target,
		[parameter(Mandatory=$false)]
			[string]$UnComressionArgs = "-bd"
	)

	try
	{
		$7zipPath = "/usr/lib/p7zip/7z"
		if (Test-Path -Path $Target -PathType Container) {
			$exeargs = "x ""$Source"""
			$exeargs = "$exeargs -o""$Target"" $UnComressionArgs"
			$process = Start-Process $7zipPath -Wait -NoNewWindow -PassThru -ArgumentList $exeargs

			if ($process.ExitCode -ne 0) {
				throw "7zip failed to uncompress file: $($process.ExitCode) $exeargs"
			}
		}
		else {
			$tmpdst = "/tmp/wal_copy"
			[System.IO.File]::Copy($Source, $tmpdst, $true);
			$Source = $tmpdst

			$tmpfold = "/tmp/wal_copy_ex"
			if (-not (Test-Path -Path $tmpfold -PathType Container)) {
				New-Item -ItemType Directory $tmpfold
			}

			$exeargs = "x ""$Source"""
			$exeargs = "$exeargs -o""$tmpfold"" $UnComressionArgs -aoa"
			$process = Start-Process $7zipPath -Wait -NoNewWindow -PassThru -ArgumentList $exeargs

			if ($process.ExitCode -ne 0) {
				throw "7zip failed to uncompress file: $($process.ExitCode) $exeargs"
			}

			$Source = Join-Path $tmpfold $ArchiveName

			[System.IO.File]::Move($Source, $Target, $true);
		}
	}
	catch {
		throw
	}
}

try
{
	Write-Host $ArchiveFullPath
	Write-Host $ArchiveName

	if ($s3Endpoint -or $s3Profile -or $BackupPath.StartsWith('s3://')) {
		$walFile = $backwal + '/' + $ArchiveName
		$awsArgs = @(
			"s3", "cp",
			$walFile,
			$ArchiveFullPath
		)

		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}

		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		aws @awsArgs

		if ($LASTEXITCODE -ne 0) { throw "aws s3 cp exited with code $LASTEXITCODE." }

		return
	}
	else {
		if (-not (Test-Path -Path $backwal -PathType Container)) {
			throw "$backwal folder does not exists"
		}

		$walFile = Join-Path $backwal $ArchiveName

		if (Test-Path -Path $walFile -PathType Leaf) {
			Write-Host "$walFile copying to $ArchiveFullPath"
			Copy-Item -Path $walFile -Destination $ArchiveFullPath
			return
		}

		$walFile = "$walFile.7z"
		if (Test-Path -Path $walFile -PathType Leaf) {
			Write-Host "$walFile expanding to $ArchiveFullPath"
			Expand-7ZipItem -Source $walFile -Target $ArchiveFullPath
			return
		}

		$walFile = Join-Path $backwal "oldstorage" $ArchiveName

		if (Test-Path -Path $walFile -PathType Leaf) {
			Write-Host "$walFile copying to $ArchiveFullPath"
			Copy-Item -Path $walFile -Destination $ArchiveFullPath
			return
		}

		$walFile = "$walFile.7z"
		if (Test-Path -Path $walFile -PathType Leaf) {
			Write-Host "$walFile expanding to $ArchiveFullPath"
			Expand-7ZipItem -Source $walFile -Target $ArchiveFullPath
			return
		}

		throw "$ArchiveName does not exists at $backwal"
	}
}
catch {
	throw
}
finally {
}