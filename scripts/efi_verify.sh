#!/usr/bin/env bash
set -euo pipefail
if ! [ -f boot/BOOTX64.EFI ]; then
  echo "EFI verify: no BOOTX64.EFI yet (expected pre-Phase-1)"; exit 0
fi
if command -v sbverify >/dev/null 2>&1; then
  sbverify --list boot/BOOTX64.EFI || echo "EFI not signed yet (expected until keys flow)"
else
  echo "sbverify not present; skipping (runner doesn't have it by default)"
fi
