<#
.SYNOPSIS
  Remove the lab firewall rule and delete the lab key and certificate.
#>
param(
  [int]$Port       = 4433,
  [string]$WorkDir = "$env:USERPROFILE\pqc-lab"
)

Remove-NetFirewallRule -DisplayName "OpenSSL s_server $Port" -ErrorAction SilentlyContinue
Remove-Item "$WorkDir\server.key", "$WorkDir\server.crt" -Force -ErrorAction SilentlyContinue
Write-Host "Cleanup complete."
