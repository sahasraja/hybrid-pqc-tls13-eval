# Post-Quantum TLS Developer Playbook (Windows and Linux)

**Scope:** upgrade the TLS 1.3 key exchange to ML-KEM, using a hybrid group for interoperability.

## Why this matters: harvest now, decrypt later

Adversaries can record TLS traffic today and decrypt it later, once a large fault-tolerant quantum computer exists.

- TLS 1.3 has two parts: **key establishment** (public-key cryptography, typically ECDHE) and **bulk encryption** (symmetric ciphers such as AES-GCM).
- Shor's algorithm breaks RSA, DH, ECDH and ECDSA. Grover's algorithm gives only a quadratic speedup against symmetric ciphers, which AES-256 absorbs.
- The weak link is therefore the handshake. If an adversary records today's handshake and later breaks ECDHE, they can derive the session keys and decrypt the capture.
- **Risk window:** if the required confidentiality lifetime of the data (D) is at least the time until quantum computers can break classical public-key cryptography (T), key establishment must be upgraded now.

## What changes and what does not

| Changes | Does not change |
|---|---|
| TLS 1.3 key exchange (the KeyShare group) | Application protocol |
| | Cipher suite (AES-GCM) |
| | Existing RSA or ECDSA certificates |

Note: OpenSSL 3.5 already offers `X25519MLKEM768` by default. The `-groups` flag below **enforces** the hybrid group so the test cannot silently fall back to a classical group.

## Prerequisites

- Two endpoints (two VMs, or two terminals on one host)
- **OpenSSL 3.5 or later** on both endpoints. Older builds do not include ML-KEM, and third-party provider DLLs built for another OpenSSL version will fail to load.
- Wireshark (or tcpdump) on at least one side

Sanity check on each box:

```bash
openssl version
openssl list -kem-algorithms | grep -E 'X25519MLKEM|SecP.*MLKEM|MLKEM[0-9]+'
```

## Windows (PowerShell)

Create a short-lived test certificate and open the port (server):

```powershell
cd "$env:USERPROFILE"
& "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" req -x509 -newkey rsa:2048 -nodes `
  -keyout server.key -out server.crt -days 7 -subj "/CN=demo.local"
New-NetFirewallRule -DisplayName "OpenSSL s_server 4433" -Direction Inbound `
  -Action Allow -Protocol TCP -LocalPort 4433
```

Server:

```powershell
& "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" s_server `
  -accept 4433 -tls1_3 -cert server.crt -key server.key `
  -groups X25519MLKEM768 -www
```

Client (use `-ign_eof`; PowerShell rejects `< NUL`):

```powershell
& "$env:ProgramFiles\OpenSSL-Win64\bin\openssl.exe" s_client `
  -connect 127.0.0.1:4433 -tls1_3 -groups X25519MLKEM768 -brief -ign_eof
```

Expected client output:

```
Protocol version: TLSv1.3
Ciphersuite: TLS_AES_256_GCM_SHA384
Negotiated TLS1.3 group: X25519MLKEM768
```

## Linux (bash)

```bash
openssl req -x509 -newkey rsa:2048 -nodes -keyout server.key -out server.crt \
  -days 7 -subj "/CN=demo.local"

# server
openssl s_server -accept 4433 -tls1_3 -cert server.crt -key server.key \
  -groups X25519MLKEM768 -www

# client
openssl s_client -connect 127.0.0.1:4433 -tls1_3 -groups X25519MLKEM768 -brief </dev/null
```

## Packet-level verification (Wireshark)

- Capture filter: `tcp port 4433`
- In ClientHello and ServerHello, open **KeyShare** and confirm `X25519MLKEM768`
- Expect much larger KeyShare entries than classical groups (client 1216 bytes, server 1120 bytes, per RFC 10024)

## Optional: pure ML-KEM (controlled lab only)

```bash
openssl s_server -accept 4433 -tls1_3 -cert server.crt -key server.key -groups MLKEM768 -www
openssl s_client -connect 127.0.0.1:4433 -tls1_3 -groups MLKEM768 -brief </dev/null
```

## Optional: standalone ML-KEM encapsulation

Generate an ML-KEM key pair, encapsulate a shared secret, and confirm both sides derive the same secret:

```bash
openssl genpkey -algorithm ML-KEM-768 -out mlkem_priv.pem
openssl pkey -in mlkem_priv.pem -pubout -out mlkem_pub.pem

openssl pkeyutl -encap -pubin -inkey mlkem_pub.pem -out ct.bin -secret ss_sender.bin
openssl pkeyutl -decap -inkey mlkem_priv.pem -in ct.bin -secret ss_receiver.bin

cmp ss_sender.bin ss_receiver.bin && echo "Shared secrets match"
```

To protect data with this secret, derive a key with HKDF and use an **authenticated** cipher such as AES-256-GCM in application code. Do not use an unauthenticated mode such as AES-CTR, which lets an attacker modify ciphertext undetected. (The `openssl enc` command does not support GCM, so this step belongs in code, not the CLI.)

## Artifacts to capture

- Terminal proof: `s_client -brief` showing the negotiated group
- pcap proof: Wireshark KeyShare showing the same group
- Optional: handshake bytes and first-request latency, hybrid vs. classical

## Troubleshooting

| Symptom | Fix |
|---|---|
| Hybrid group not listed | OpenSSL is older than 3.5. Install a 3.5+ build; no plug-in is needed. |
| Client shows a classical group | Ensure both sides offer `X25519MLKEM768`. |
| Handshake fails across a network device | Test VM to VM first; some middleboxes do not yet handle large ClientHello messages. |
| PowerShell error on `<` | Use `-ign_eof` instead of `< NUL`. |
| Port blocked on Windows | Confirm the firewall rule for TCP 4433. |
