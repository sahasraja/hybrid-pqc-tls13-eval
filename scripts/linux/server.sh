#!/usr/bin/env bash
# Start a TLS 1.3 test server restricted to a hybrid post-quantum group.
# Usage: ./server.sh [GROUP] [PORT]     e.g. ./server.sh SecP384r1MLKEM1024 4433
# Randomness: OpenSSL's own DRBG, seeded from the kernel entropy source (no provider flags).
set -euo pipefail
OPENSSL="${OPENSSL:-openssl}"
GROUP="${1:-X25519MLKEM768}"
PORT="${2:-4433}"
WORKDIR="${WORKDIR:-$HOME/pqc-lab}"

mkdir -p "$WORKDIR" && cd "$WORKDIR"
if [[ ! -f server.key ]]; then
  "$OPENSSL" req -x509 -newkey rsa:2048 -nodes \
    -keyout server.key -out server.crt -days 7 -subj "/CN=demo.local"
  chmod 600 server.key
fi

echo "Starting server on port $PORT, group $GROUP. Press Ctrl+C to stop."
exec "$OPENSSL" s_server -accept "$PORT" -tls1_3 -cert server.crt -key server.key \
  -groups "$GROUP" -www
