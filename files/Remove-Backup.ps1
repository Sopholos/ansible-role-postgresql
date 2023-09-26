#!/snap/bin/powershell -Command
# Ansible managed
param(
    [parameter(Mandatory=$true)][string]$BackupFolder,
    [parameter(Mandatory=$true)][int]$Days,
    [parameter(Mandatory=$true)][AllowNull()][System.Nullable[int]]$SaveEachMonthDay
)

$ErrorActionPreference = "Stop"

function Cleanup-Folder($BackupFolder, $Days) {
    foreach ($File in Get-Childitem $BackupFolder -Recurse -File) {
        if ($SaveEachMonthDay -ne $null) {
            if ($File.LastWriteTime.Day -eq $SaveEachMonthDay) {
                continue
            }
        }
        if ($File.LastWriteTime -lt (Get-Date).AddDays($Days)) {
            del $File -Verbose
        }
    }

    Get-ChildItem $BackupFolder -Recurse -Directory | ? { -Not ($_.EnumerateFiles('*',1) | Select-Object -First 1) } | Remove-Item -Recurse
}

Cleanup-Folder $BackupFolder $Days