#!/usr/bin/env bash
set -euo pipefail
out="boot/mbr.bin"
# 512 bytes of zeroes
dd if=/dev/zero of="$out" bs=512 count=1 >/dev/null 2>&1
# Set boot signature 0x55AA at bytes 510..511
printf '\x55\xaa' | dd of="$out" bs=1 seek=510 conv=notrunc >/dev/null 2>&1
echo "MBR → $out"
