#!/usr/bin/env bash
# Verify that the OpenSSL build supports native ML-KEM and hybrid TLS groups.
# Requires OpenSSL 3.5 or later. Override the binary with: OPENSSL=/opt/openssl-3.5/bin/openssl
set -euo pipefail
OPENSSL="${OPENSSL:-openssl}"

"$OPENSSL" version
kems="$("$OPENSSL" list -kem-algorithms)"
echo "$kems"

if ! grep -q 'X25519MLKEM768' <<<"$kems"; then
  echo "ERROR: X25519MLKEM768 not available. Install OpenSSL 3.5 or later (native ML-KEM); no plug-in provider is needed." >&2
  exit 1
fi
echo "OK: native ML-KEM and hybrid TLS groups are available."
