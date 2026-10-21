<#
.SYNOPSIS
  Start a TLS 1.3 test server restricted to a hybrid post-quantum group.
.DESCRIPTION
  Creates a short-lived self-signed RSA-2048 lab certificate (if missing), opens the
  Windows firewall port (requires an elevated session), and starts openssl s_server.
  Randomness: OpenSSL's own DRBG, seeded from the Windows CNG entropy source (no provider flags).
.EXAMPLE
  .\server.ps1
  .\server.ps1 -Group SecP384r1MLKEM1024
#>
param(
  [string]$OpenSSL = "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe",
  [string]$Group   = "X25519MLKEM768",
  [int]$Port       = 4433,
  [string]$WorkDir = "$env:USERPROFILE\pqc-lab"
)

New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
Set-Location $WorkDir

if (-not (Test-Path "server.key")) {
  & $OpenSSL req -x509 -newkey rsa:2048 -nodes `
    -keyout server.key -out server.crt -days 7 -subj "/CN=demo.local"
}

$ruleName = "OpenSSL s_server $Port"
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
  try {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound `
      -Action Allow -Protocol TCP -LocalPort $Port | Out-Null
  } catch {
    Write-Warning "Could not add firewall rule (run as Administrator for cross-host tests). Loopback tests still work."
  }
}

Write-Host "Starting server on port $Port, group $Group. Press Ctrl+C to stop." -ForegroundColor Cyan
& $OpenSSL s_server -accept $Port -tls1_3 -cert server.crt -key server.key `
  -groups $Group -www
