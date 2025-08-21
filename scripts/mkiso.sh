#!/usr/bin/env bash
set -euo pipefail
ROOT="iso_root"
ISO="iso/sovrn.iso"
VOL="SOVRN"

EFI_IMG="$ROOT/EFI/efiboot.img"
EFI_SIZE=2M

rm -f "$ISO"
rm -rf "$ROOT"
mkdir -p "$ROOT/EFI/BOOT" "$(dirname "$EFI_IMG")"

truncate -s "$EFI_SIZE" "$EFI_IMG" 2>/dev/null || dd if=/dev/zero of="$EFI_IMG" bs=1M count=2
if command -v mkfs.vfat >/dev/null 2>&1; then
  mkfs.vfat -n SOVRN_EFI "$EFI_IMG" >/dev/null
elif command -v newfs_msdos >/dev/null 2>&1; then
  newfs_msdos -F 16 -v SOVRN_EFI "$EFI_IMG" >/dev/null
else
  echo "Need mkfs.vfat or newfs_msdos"; exit 1
fi

mmd  -i "$EFI_IMG" ::/EFI ::/EFI/BOOT
mcopy -i "$EFI_IMG" -s boot/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI

cp -f boot/BOOTX64.EFI "$ROOT/EFI/BOOT/BOOTX64.EFI"

mkdir -p iso
if command -v xorriso >/dev/null 2>&1; then
  xorriso -as mkisofs \
    -R -J -V "$VOL" \
    -eltorito-platform efi \
    -e EFI/efiboot.img -no-emul-boot \
    -isohybrid-gpt-basdat \
    -o "$ISO" "$ROOT"
elif command -v genisoimage >/dev/null 2>&1; then
  genisoimage -R -J -V "$VOL" \
    -eltorito-platform efi \
    -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot \
    -o "$ISO" "$ROOT"
elif command -v mkisofs >/dev/null 2>&1; then
  mkisofs -R -J -V "$VOL" \
    -eltorito-platform efi \
    -eltorito-alt-boot -e EFI/efiboot.img -no-emul-boot \
    -o "$ISO" "$ROOT"
else
  echo "Need xorriso/genisoimage/mkisofs"; exit 1
fi

./scripts/size_gate.sh "$ISO" 33554432
echo "ISO ready → $ISO"
