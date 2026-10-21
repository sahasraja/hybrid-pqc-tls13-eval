<#
.SYNOPSIS
  Verify that the installed OpenSSL build supports native ML-KEM and hybrid TLS groups.
.DESCRIPTION
  Requires OpenSSL 3.5 or later. Older builds do not include ML-KEM, and third-party
  provider DLLs built for a different OpenSSL version will fail to load.
#>
param(
  [string]$OpenSSL = "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe"
)

if (-not (Test-Path $OpenSSL)) {
  Write-Error "OpenSSL not found at '$OpenSSL'. Pass -OpenSSL <path>."
  exit 1
}

& $OpenSSL version
$kems = & $OpenSSL list -kem-algorithms
$kems

if (-not ($kems -match 'X25519MLKEM768')) {
  Write-Error "X25519MLKEM768 not available. Install OpenSSL 3.5 or later (native ML-KEM); no plug-in provider is needed."
  exit 1
}
Write-Host "OK: native ML-KEM and hybrid TLS groups are available." -ForegroundColor Green
