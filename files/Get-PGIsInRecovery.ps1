#!/snap/bin/powershell -Command
# Ansible managed
$ErrorActionPreference = "Stop"

$result = /usr/local/bin/Invoke-PgSQL.ps1 `
	-Query "select case when pg_is_in_recovery() then 1 else 0 end;"

if ($result.Count -gt 0) {
	$isInRecovery = $result[0].Trim() -eq "1"
	return $isInRecovery;
}

return $Null;
