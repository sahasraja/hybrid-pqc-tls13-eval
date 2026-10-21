#!/usr/bin/env bash
# Connect to the test server and verify which TLS 1.3 group was negotiated.
# Usage: ./client.sh [SERVER] [PORT] [GROUP]
#   GROUP=default omits -groups to observe what OpenSSL negotiates by default.
# Sends one HTTP request to the s_server -www endpoint, which replies and closes.
set -euo pipefail
OPENSSL="${OPENSSL:-openssl}"
SERVER="${1:-127.0.0.1}"
PORT="${2:-4433}"
GROUP="${3:-X25519MLKEM768}"

args=(s_client -connect "${SERVER}:${PORT}" -tls1_3 -brief -ign_eof)
[[ "$GROUP" != "default" ]] && args+=(-groups "$GROUP")

out="$(printf 'GET / HTTP/1.0\r\n\r\n' | timeout 20 "$OPENSSL" "${args[@]}" 2>&1 || true)"
sed '/^HTTP\//,$d' <<<"$out"

line="$(grep -E 'Negotiated TLS1.3 group|Server Temp Key' <<<"$out" | head -1 || true)"
if [[ -z "$line" ]]; then
  echo "ERROR: handshake failed or negotiated group not reported." >&2
  exit 1
fi
echo "RESULT: $line"
if [[ "$GROUP" != "default" && "$line" != *"$GROUP"* ]]; then exit 1; fi
