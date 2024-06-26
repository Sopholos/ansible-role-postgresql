#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$Query,
	[parameter(Mandatory=$false)][string]$Database = "postgres"
)
Write-Host "Executing against $Database query $Query"

&psql "--dbname=$Database" "--no-psqlrc" "--variable=ON_ERROR_STOP=1" "--pset=pager=off" "--command=$Query"
if (0 -ne $LASTEXITCODE) {
	throw "Failed to start: $LASTEXITCODE psql"
}
