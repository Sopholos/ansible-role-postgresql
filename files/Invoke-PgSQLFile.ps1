#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$File,
	[parameter(Mandatory=$false)][string]$PostgresqlHost = "localhost",
	[parameter(Mandatory=$false)][int]$PostgresqlPort = 5432,
	[parameter(Mandatory=$false)][string]$Database = "postgres",
	[parameter(Mandatory=$false)]$PSQLargs = @("--no-psqlrc", "--variable=ON_ERROR_STOP=1", "--pset=pager=off", "--tuples-only"),
	[parameter(Mandatory=$false)][string]$PostgresqlUser,
	[parameter(Mandatory=$false)][string]$PostgresqlPassword
)
$ErrorActionPreference = "Stop"
Write-Host "Executing against $($PostgresqlHost):$PostgresqlPort/$Database file $File"

$args = $PSQLargs

$creds = ""
if ($PostgresqlUser) {
	if ($PostgresqlPassword) {
		$creds = "${PostgresqlUser}:$PostgresqlPassword@"
	}
	else {
		$creds = "$PostgresqlUser@"
	}
}

$args += "--dbname=postgresql://${creds}${PostgresqlHost}:$PostgresqlPort/$Database"

$args += "--file=$File"

$tempfile = New-TemporaryFile

$result = &psql @args 2>$tempfile

Get-Content $tempfile | Write-Host -ForegroundColor Red

if (0 -ne $LASTEXITCODE) {
	Write-Host $result

	throw "Failed to start: $LASTEXITCODE psql"
}

return $result
