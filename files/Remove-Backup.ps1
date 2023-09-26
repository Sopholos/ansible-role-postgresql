#!/snap/bin/powershell -Command
# Ansible managed
param(
    [parameter(Mandatory=$true)][string]$backupFolder,
    [parameter(Mandatory=$true)][int]$days,
    [parameter(Mandatory=$true)][AllowNull()][System.Nullable[int]]$saveEachMonthDay
)

$ErrorActionPreference = "Stop"

foreach ($File in Get-Childitem $backupFolder -Recurse -File) {
    if ($saveEachMonthDay -ne $null) {
        if ($File.LastWriteTime.Day -eq $saveEachMonthDay) {
            continue
        }
    }
    if ($File.LastWriteTime -lt (Get-Date).AddDays($days)) {
        del $File -Verbose
    }
}

# delete empty dirs
Get-ChildItem $backupFolder -Recurse -Directory | ? { -Not ($_.EnumerateFiles('*',1) | Select-Object -First 1) } | Remove-Item -Recurse