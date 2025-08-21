# Secure Boot (plan)
- Keys are **never** committed. Generate locally:
  openssl req -new -x509 -newkey rsa:2048 -sha256 -days 365 -nodes \
    -subj "/CN=SOVRN Test SB/" -keyout sb.key -out sb.crt
- Local signing (Phase-1/2 dev only):
  sbsign --key sb.key --cert sb.crt --output boot/BOOTX64.SIGNED.EFI boot/BOOTX64.EFI
- CI does **not** sign; it only verifies if tools are present.
- Real release keys live off-repo; signing happens on a secured host.
