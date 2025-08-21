#!/usr/bin/env bash
set -euo pipefail
ROOT="iso_root"
ISO="iso/sovrn.iso"
VOL="SOVRN"

rm -rf "$ROOT"
mkdir -p "$ROOT/EFI/BOOT"
cp -f boot/BOOTX64.EFI "$ROOT/EFI/BOOT/BOOTX64.EFI"

# Prefer xorriso/genisoimage/mkisofs on Linux; hdiutil on macOS
if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs -R -J -V "$VOL" -o "$ISO" "$ROOT"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -R -J -V "$VOL" -o "$ISO" "$ROOT"
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -R -J -V "$VOL" -o "$ISO" "$ROOT"
elif command -v hdiutil >/dev/null 2>&1; then
  # macOS fallback
  hdiutil makehybrid -o "$ISO" "$ROOT" -iso -joliet -default-volume-name "$VOL" >/dev/null
else
  echo "No ISO tool found (need xorriso/genisoimage/mkisofs or hdiutil)"; exit 1
fi

# Enforce 32 MiB cap
./scripts/size_gate.sh "$ISO" 33554432
echo "ISO ready → $ISO"
