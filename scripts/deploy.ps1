Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\..\infra"
try {
    terraform init
    terraform apply
}
finally {
    Pop-Location
}
