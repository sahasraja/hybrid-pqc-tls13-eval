# Path A: OpenSSL FIPS Provider Variant (Specified, Not Tested)

**Status: not executed.** This variant was specified in the developer handover but was not run as part of the validation. It is included for completeness and as a starting point for contributors. See Section V-E of the paper.

## Goal

Keep the hybrid group `X25519MLKEM768` while having random bits served by the DRBG in OpenSSL's FIPS provider.

## Important caveat

Loading the FIPS provider **does not by itself make the key exchange FIPS-validated**. When the `fips` and `default` providers are both active, an algorithm request without a property query (for example `fips=yes`) may be satisfied by the `default` provider. In this configuration the hybrid KEM is expected to come from the `default` provider. Whether ML-KEM is available from a validated module depends on that module's version and validation status. RFC 10024 also specifies which component of each hybrid group must come from a certified implementation.

## Outline

1. Confirm the build includes a FIPS module:

   ```powershell
   & "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" version -a
   & "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" list -providers
   ```

2. Install (self-test) the FIPS module:

   ```powershell
   $confDir = "$env:ProgramFiles\OpenSSL-Win64\bin\cnf"
   & "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" fipsinstall `
     -out "$confDir\fipsmodule.cnf" `
     -module "$env:ProgramFiles\OpenSSL-Win64\bin\fips.dll"
   ```

3. Create an `openssl.cnf` that includes `fipsmodule.cnf` and activates the `fips`, `base` and `default` providers, then set `$env:OPENSSL_CONF` to it.

4. Check the providers and random generators:

   ```powershell
   & "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" list -providers
   & "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" list -random-generators
   ```

5. Run the server and client as in Path B, adding `-provider fips -provider default -provider base`, and record which provider serves each algorithm.

## Evidence a contributor should capture

- `openssl list -providers` and `openssl list -random-generators` output
- The negotiated group line from the client
- A statement of which provider served the ML-KEM and X25519 operations
