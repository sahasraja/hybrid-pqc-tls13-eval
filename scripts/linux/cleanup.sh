#!/usr/bin/env bash
# Delete the lab key and certificate.
WORKDIR="${WORKDIR:-$HOME/pqc-lab}"
rm -f "$WORKDIR/server.key" "$WORKDIR/server.crt"
echo "Cleanup complete."
