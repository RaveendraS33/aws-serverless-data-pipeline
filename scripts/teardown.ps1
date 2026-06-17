Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\..\infra"
try {
    terraform destroy -auto-approve
}
finally {
    Pop-Location
}
