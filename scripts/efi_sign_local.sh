#!/usr/bin/env bash
set -euo pipefail
KEY="${SOVRN_SB_KEY:-sb.key}"
CRT="${SOVRN_SB_CERT:-sb.crt}"
IN="boot/BOOTX64.EFI"
OUT="boot/BOOTX64.SIGNED.EFI"
if ! command -v sbsign >/dev/null 2>&1; then
  echo "sbsign not installed (ok for now)."; exit 0
fi
[ -f "$IN" ] || { echo "Missing $IN"; exit 1; }
sbsign --key "$KEY" --cert "$CRT" --output "$OUT" "$IN" && echo "Signed → $OUT"
