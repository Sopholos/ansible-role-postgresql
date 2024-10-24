#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$Query,
	[parameter(Mandatory=$false)][string]$Database = "postgres"
)
Write-Host "Executing against $Database query $Query"

$args = "--no-psqlrc", "--variable=ON_ERROR_STOP=1", "--pset=pager=off", "--tuples-only"
$args += "--dbname=$Database"
$args += "--command=$Query"

$result = &psql @args

if (0 -ne $LASTEXITCODE) {
	throw "Failed to start: $LASTEXITCODE psql"
}

return $result