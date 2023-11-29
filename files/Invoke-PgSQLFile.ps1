#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$true)][string]$File,
	[parameter(Mandatory=$false)][string]$Database = "postgres"
)
Write-Host "Executing against $Database query $File"

&psql "--dbname=$Database" "--pset=pager=off" "--file=$File"
if (0 -ne $LASTEXITCODE) {
	throw "Failed to start: $LASTEXITCODE psql"
}
