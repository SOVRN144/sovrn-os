#!/bin/sh
set -eux
mkdir -p isoroot iso
cp -f boot.img isoroot/boot.img
cp -f esp.img  isoroot/efi.img
xorriso -as mkisofs -V SOVRN -o iso/sovrn.iso \
  -b boot.img -c boot.cat \
  -eltorito-alt-boot -e efi.img -no-emul-boot \
  isoroot
