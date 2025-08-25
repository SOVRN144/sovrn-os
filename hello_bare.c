#include <efi.h>
EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  if (SystemTable && SystemTable->ConOut && SystemTable->ConOut->OutputString)
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"Hello bare UEFI\r\n");
  if (SystemTable && SystemTable->BootServices && SystemTable->BootServices->Stall)
    SystemTable->BootServices->Stall(300000);
  return EFI_SUCCESS;
}
