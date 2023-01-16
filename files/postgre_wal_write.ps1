#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)]
		[string]$ArchiveFullPath,
	[parameter(Mandatory=$true)]
		[string]$ArchiveName,
	[parameter(Mandatory=$true)]
		[string]$BackupPath
)
$ErrorActionPreference = "Stop"
$backwal = $BackupPath
try
{
    if (-not (Test-Path -Path $backwal -PathType Container)) {
        mkdir $backwal
    }

	$destination = Join-Path $backwal -ChildPath $ArchiveName    
    Copy-Item -Path $ArchiveFullPath -Destination $destination
	    
	$doneFile = "${destination}.done"
	$(Get-Date -format "yyyy-MM-dd HH:mm:ss") | Set-Content $doneFile
}
catch {
    throw
}