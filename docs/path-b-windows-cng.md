# Path B: Hybrid TLS with the Default Random Generator on Windows

**This is the configuration used for the validation reported in the paper.**

No provider flags are used. OpenSSL runs its **own** DRBG (deterministic random bit generator) from the built-in default provider, and Windows supplies the **seed** through its CNG (Cryptography API: Next Generation) entropy source.

> Precise wording matters here. The DRBG is OpenSSL's, not Windows'. Windows CNG only provides the seed. This distinction matters for any FIPS claim: enabling Windows FIPS mode does not make OpenSSL's DRBG FIPS-approved.

## Step 1: Point OpenSSL to its configuration file

```powershell
$env:OPENSSL_CONF = "C:\Program Files\OpenSSL-Win64\bin\cnf\openssl.cnf"
```

## Step 2: Generate a test certificate

```powershell
cd "$env:USERPROFILE"
& "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" req -x509 -newkey rsa:2048 -nodes `
  -keyout server.key -out server.crt -days 7 -subj "/CN=demo.local"
```

## Step 3: Open the firewall for port 4433

```powershell
New-NetFirewallRule -DisplayName "OpenSSL s_server 4433" -Direction Inbound `
  -Action Allow -Protocol TCP -LocalPort 4433
```

## Step 4: Start the TLS server

No `-provider` flags: OpenSSL uses its default provider and DRBG, seeded from Windows CNG.

```powershell
& "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" s_server `
  -accept 4433 -tls1_3 -cert server.crt -key server.key `
  -groups X25519MLKEM768 -www
```

## Step 5: Start the TLS client

```powershell
& "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" s_client `
  -connect 127.0.0.1:4433 -tls1_3 -groups X25519MLKEM768 -brief -ign_eof
```

Expected proof:

```
Negotiated TLS1.3 group: X25519MLKEM768
```

## Reading the client output

| Line | Meaning |
|---|---|
| `Connecting to 127.0.0.1` | Client is connecting to the local server |
| `Can't use SSL_get_servername` | Expected when no SNI is sent; not a problem |
| `verify error:num=18:self-signed certificate` | Lab certificate is self-signed; normal for a demo |
| `CONNECTION ESTABLISHED` | TLS handshake completed |
| `Protocol version: TLSv1.3` | TLS 1.3 is in use |
| `Ciphersuite: TLS_AES_256_GCM_SHA384` | Symmetric cipher is unchanged |
| `Negotiated TLS1.3 group: X25519MLKEM768` | Hybrid post-quantum key exchange succeeded |

Evidence screenshots (with the local user path redacted) are in [`../evidence`](../evidence).

## Step 6: Clean up

```powershell
Remove-NetFirewallRule -DisplayName "OpenSSL s_server 4433"
Remove-Item "$env:USERPROFILE\server.key","$env:USERPROFILE\server.crt" -Force
```
