param(
    [string]$HostAddress = "0.0.0.0",
    [int]$Port = 8000
)

$ErrorActionPreference = "Stop"
if (-not $env:DERIVE_PAIRING_TOKEN -or $env:DERIVE_PAIRING_TOKEN -eq "change-me") {
    throw "Set DERIVE_PAIRING_TOKEN to a long random value before starting the server."
}

python -m uvicorn app.main:app --host $HostAddress --port $Port
