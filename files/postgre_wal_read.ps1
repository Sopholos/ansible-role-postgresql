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

function Start-ProcessSimple([string]$exe, [string]$exeargs) {
	$process = Start-Process $exe -Wait -NoNewWindow -PassThru -ArgumentList $exeargs
	if ($process.ExitCode -ne 0) {
		throw "Failed to start: $($process.ExitCode) $exe $exeargs"
	}	
}

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
        $7zipPath = "7z"
		if (-not (Test-Path -Path $7zipPath -PathType Leaf)) {
			throw "7zip file '$7zipPath' not found"
		}
		
		$exeargs = "x ""$Source"""	
		if (Test-Path -Path $Target -PathType Container) {
			$exeargs = "$exeargs -o""$Target"" $UnComressionArgs"
			$process = Start-Process $7zipPath -Wait -NoNewWindow -PassThru -ArgumentList $exeargs
			
			if ($process.ExitCode -ne 0) {	
				throw "7zip failed to uncompress file: $($process.ExitCode) $exeargs"
			}
		}
		else {
			$exeargs = "$exeargs -so $UnComressionArgs"
			$process = Start-Process $7zipPath -Wait -NoNewWindow -PassThru -ArgumentList $exeargs -RedirectStandardOutput $Target
			
			if ($process.ExitCode -ne 0) {	
				throw "7zip failed to uncompress file: $($process.ExitCode) $exeargs to $Target"
			}
		}
	}
	catch {
		throw
	}
}

try
{
	#$date = Get-Date -Format "yyyy-MM-dd_HH-mm_ss.fff"	
	#$logsdir = "t:\logs\"
	#Start-Transcript -Path (Join-Path $logsdir -ChildPath "wal_read$($num)_$date.log")
	
	Write-Host $ArchiveFullPath
	Write-Host $ArchiveName
	
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
catch {
    throw
}
finally {	
	#Stop-Transcript
}