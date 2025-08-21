#!/usr/bin/env bash
set -euo pipefail

ISO="${1:-iso/sovrn.iso}"
[ -f "$ISO" ] || { echo "ISO not found: $ISO" >&2; exit 2; }

# timeout vs gtimeout
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=gtimeout
else
  echo "Install GNU coreutils for 'gtimeout' (macOS) or use 'timeout' (Linux)." >&2
  exit 2
fi

# Choose OVMF CODE
CODE=""
if [[ "$(uname -s)" == "Darwin" ]]; then
  CODE="$(brew --prefix)/share/qemu/edk2-x86_64-code.fd"
else
  for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE*; do
    [[ -f "$c" ]] && CODE="$c" && break
  done
fi
[ -f "$CODE" ] || { echo "OVMF CODE firmware not found"; exit 2; }

mkdir -p out
# Always start with a fresh log file
: > out/qemu-uefi-serial.log

# Preflight diagnostics go into the same log
{
  echo "[preflight] starting smoke"
  echo "[preflight] ls -l $ISO"
  ls -l "$ISO" || true
  echo "[preflight] OVMF CODE: $CODE"

  # Verify ISO really has an EFI boot image and BOOTX64.EFI
  if command -v xorriso >/dev/null 2>&1; then
    echo "[preflight] El Torito info:"
    xorriso -indev "$ISO" -report_el_torito plain 2>&1 || true
    echo "[preflight] ls /EFI/BOOT:"
    xorriso -indev "$ISO" -ls /EFI/BOOT 2>&1 || true
    # Extract BOOTX64.EFI and check it contains our banner text
    xorriso -osirrox on -indev "$ISO" -extract /EFI/BOOT/BOOTX64.EFI out/BOOTX64.from.iso 2>&1 || true
    if command -v strings >/dev/null 2>&1; then
      echo "[preflight] strings(BOOTX64.EFI) | grep -n 'SOVRN'"
      strings -a out/BOOTX64.from.iso | grep -n "SOVRN" || true
    fi
  fi
} >> out/qemu-uefi-serial.log 2>&1

# Make VARS pflash (keep small)
VARS="$(mktemp -t ovmf_vars).fd"
if command -v qemu-img >/dev/null 2>&1; then
  qemu-img create -f raw "$VARS" 4M >/dev/null
else
  dd if=/dev/zero of="$VARS" bs=1M count=4 status=none
fi

# Run QEMU headless; append to the same log
set +e
$TIMEOUT 35s qemu-system-x86_64 \
  -machine q35 -m 256 -serial stdio -display none -no-reboot \
  -drive if=pflash,format=raw,readonly=on,file="$CODE" \
  -drive if=pflash,format=raw,file="$VARS" \
  -boot order=d,menu=off \
  -cdrom "$ISO" \
  >> out/qemu-uefi-serial.log 2>&1
rc=$?
set -e

# Normalize CRs and search for the banner
if LC_ALL=C tr -d '\r' < out/qemu-uefi-serial.log | grep -q "SOVRN ENGINE ONLINE"; then
  echo "Smoke OK: banner observed on serial."
  exit 0
fi

echo "Smoke FAILED (rc=$rc). Last 60 serial lines:"
tail -n 60 out/qemu-uefi-serial.log || true
exit 1
