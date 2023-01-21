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

function Start-ProcessOutputAsBinary([string]$processname, [string]$arguments) {
	$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
	$processStartInfo.FileName = $processname
	$processStartInfo.WorkingDirectory = (Get-Location).Path
	if($arguments) { $processStartInfo.Arguments = $arguments }
	$processStartInfo.UseShellExecute = $false
	$processStartInfo.RedirectStandardOutput = $true

	$process = [System.Diagnostics.Process]::Start($processStartInfo)
	
	$byteRead = -1
    do
    {
        $byteRead = $process.StandardOutput.BaseStream.ReadByte()
        if($byteRead -ge 0) { $byteRead }
    } while($byteRead -ge 0)	

	$process.WaitForExit()
	if ($process.ExitCode -ne 0) {	
		throw "failed to start: $($process.ExitCode) $processname $arguments"
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
        $7zipPath = "/usr/lib/p7zip/7z"
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
			$bytes = Start-ProcessOutputAsBinary $7zipPath $exeargs 
			[io.file]::WriteAllBytes($Target, $bytes)
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