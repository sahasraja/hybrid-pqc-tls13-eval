<#
.SYNOPSIS
  Connect to the test server and verify which TLS 1.3 group was negotiated.
.DESCRIPTION
  Sends one HTTP request to the s_server -www endpoint, which replies and closes,
  so the client exits on its own. Uses -ign_eof instead of "< NUL"
  (PowerShell reserves the < operator).
  Pass -Group default to omit -groups and observe what OpenSSL negotiates by default.
.EXAMPLE
  .\client.ps1
  .\client.ps1 -Server 10.0.0.5
  .\client.ps1 -Group default
#>
param(
  [string]$OpenSSL = "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe",
  [string]$Server  = "127.0.0.1",
  [int]$Port       = 4433,
  [string]$Group   = "X25519MLKEM768"
)

$sargs = @("s_client", "-connect", "${Server}:${Port}", "-tls1_3", "-brief", "-ign_eof")
if ($Group -ne "default") { $sargs += @("-groups", $Group) }

$out = "GET / HTTP/1.0`r`n`r`n" | & $OpenSSL @sargs 2>&1 | Out-String

# Print the handshake summary only (stop at the HTTP response body).
foreach ($l in ($out -split "`r?`n")) {
  if ($l -match "^HTTP/") { break }
  $l
}

$line = ($out -split "`r?`n" | Where-Object { $_ -match "Negotiated TLS1.3 group|Server Temp Key" } | Select-Object -First 1)
if ($line) {
  Write-Host "RESULT: $($line.Trim())" -ForegroundColor Green
  if ($Group -ne "default" -and $line -notmatch [regex]::Escape($Group)) { exit 1 }
} else {
  Write-Error "Handshake failed or negotiated group not reported."
  exit 1
}
