#include <efi.h>
#include <efilib.h>
EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *ST){
  InitializeLib(ImageHandle, ST);
  Print(L"Hello UEFI (gnu-efi)\r\n");
  if (ST && ST->BootServices && ST->BootServices->Stall) ST->BootServices->Stall(300000);
  return EFI_SUCCESS;
}
