#!/usr/bin/env bash
set -euo pipefail
mkdir -p out
OUT="out/SHA256SUMS"
: > "$OUT"
for f in kernel.bin boot/BOOTX64.EFI boot/mbr.bin iso/sovrn.iso out/BUILDINFO out/BANNER.txt; do
  [ -f "$f" ] && shasum -a 256 "$f" >> "$OUT"
done
echo "Wrote $OUT"
