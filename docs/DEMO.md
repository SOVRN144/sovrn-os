# Phase-1 Demo (Hybrid layout scaffold)
This ISO is a *placeholder* (not bootable yet). Verify artifacts:

## 1) Mount ISO (macOS)
hdiutil attach iso/sovrn.iso
# Expect /Volumes/SOVRN/EFI/BOOT/BOOTX64.EFI
hdiutil detach "/Volumes/SOVRN"

## 2) MBR signature
od -An -tx1 -N2 -j510 boot/mbr.bin   # -> 55 aa
wc -c boot/mbr.bin                    # -> 512

## 3) Banner + Buildinfo
sed -n '1,12p' out/BANNER.txt
sed -n '1,12p' out/BUILDINFO

## 4) Checksums
sed -n '1,20p' out/SHA256SUMS
