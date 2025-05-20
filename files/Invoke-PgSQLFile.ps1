#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$File,
	[parameter(Mandatory=$false)][string]$PostgresqlHost = "localhost",
	[parameter(Mandatory=$false)][int]$PostgresqlPort = 5432,
	[parameter(Mandatory=$false)][string]$Database = "postgres",
	[parameter(Mandatory=$false)][string]$PostgresqlUser,
	[parameter(Mandatory=$false)][string]$PostgresqlPassword
)
$ErrorActionPreference = "Stop"
Write-Host "Executing against $($PostgresqlHost):$PostgresqlPort/$Database file $File"

$args = "--no-psqlrc", "--variable=ON_ERROR_STOP=1", "--pset=pager=off", "--tuples-only"

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

$result = &psql @args

if (0 -ne $LASTEXITCODE) {
	throw "Failed to start: $LASTEXITCODE psql"
}

return $result
