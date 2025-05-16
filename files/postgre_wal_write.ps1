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
try
{
	if ($s3Endpoint -or $s3Profile -or $BackupPath.StartsWith('s3://')) {
		$destination = $backwal + '/' + $ArchiveName
		$awsArgs = @(
			"s3", "cp",
			$ArchiveFullPath,
			$destination
		)

		if ($s3Endpoint) {
			$awsArgs +="--endpoint-url", $s3Endpoint
		}

		if ($s3Profile) {
			$awsArgs += "--profile", $s3Profile
		}

		aws @awsArgs

		if ($LASTEXITCODE -ne 0) { throw "aws s3 cp exited with code $LASTEXITCODE." }
	}
	else {
		if (-not (Test-Path -Path $backwal -PathType Container)) {
			New-Item -ItemType Directory $backwal
		}

		$destination = Join-Path $backwal -ChildPath $ArchiveName
		Copy-Item -Path $ArchiveFullPath -Destination $destination

		$doneFile = "${destination}.done"
		$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
	}
}
catch {
    throw
}