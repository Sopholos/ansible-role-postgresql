#!/snap/bin/powershell -Command
# Ansible managed
param(
	[parameter(Mandatory=$false)][string]$PostgresqlHost = "localhost",
	[parameter(Mandatory=$false)][int]$PostgresqlPort = 5432,
	[parameter(Mandatory=$false)][string]$Database = "postgres",
	[parameter(Mandatory=$false)][string]$PostgresqlUser,
	[parameter(Mandatory=$false)][string]$PostgresqlPassword
)
$ErrorActionPreference = "Stop"

$result = /usr/local/bin/Invoke-PgSQL.ps1 `
	-PostgresqlHost $PostgresqlHost `
	-PostgresqlPort $PostgresqlPort `
	-Database $Database `
	-PostgresqlUser $PostgresqlUser `
	-PostgresqlPassword $PostgresqlPassword `
	-Query "select case when pg_is_in_recovery() then 1 else 0 end;"

if ($result.Count -gt 0) {
	$isInRecovery = $result[0].Trim() -eq "1"
	return $isInRecovery;
}

return $Null;
