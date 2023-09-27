#!/snap/bin/powershell -Command
# Ansible managed
param(
    [parameter(Mandatory=$true)][string]$BackupFolder,
    [parameter(Mandatory=$true)][int]$Days,
    [parameter(Mandatory=$true)][AllowNull()][System.Nullable[int]]$SaveEachMonthDay
)

$ErrorActionPreference = "Stop"

foreach ($file in Get-Childitem $BackupFolder -Recurse -File) {
    if ($SaveEachMonthDay -ne $null) {
        if ($file.lastWriteTime -eq $SaveEachMonthDay) {
            continue
        }
    }
    if ($file.lastWriteTime -lt (Get-Date).AddDays($Days)) {
        del $file -Verbose
    }
}

# delete empty dirs
Get-ChildItem $BackupFolder -Recurse -Directory | ? { -Not ($_.EnumerateFiles('*',1) | Select-Object -First 1) } | Remove-Item -Recurse