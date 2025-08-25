#include <efi.h>
__attribute__((used,section(".rodata")))
static const char MARKER[] = "SOVRN_MARKER_v3";

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *ST) {
    ST->ConOut->OutputString(ST->ConOut, L"SOVRN v3: RESET IN 3s\r\n");
    ST->BootServices->Stall(3000000);
    ST->RuntimeServices->ResetSystem(EfiResetWarm, EFI_SUCCESS, 0, NULL);
    for(;;) { }
}
