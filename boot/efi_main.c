#include <efi.h>
#include <efilib.h>
#include <Protocol/SerialIo.h>
#include "banner.h"

static UINTN ascii_len(const CHAR8* s){ UINTN n=0; while(s && s[n]) n++; return n; }

EFI_STATUS
efi_main (EFI_HANDLE image, EFI_SYSTEM_TABLE *systab) {
  InitializeLib(image, systab);

  // Console banner (UEFI text)
  Print(L"%s\n", BANNER_WIDE);

  // Serial banner (UEFI Serial I/O if available)
  EFI_STATUS Status;
  EFI_SERIAL_IO_PROTOCOL *Serial = NULL;
  EFI_GUID SerialGuid = EFI_SERIAL_IO_PROTOCOL_GUID;
  Status = uefi_call_wrapper(BS->LocateProtocol, 3, &SerialGuid, NULL, (VOID**)&Serial);
  if (!EFI_ERROR(Status) && Serial) {
    UINTN len = ascii_len((CONST CHAR8*)BANNER_ASCII);
    uefi_call_wrapper(Serial->Write, 3, Serial, &len, (VOID*)BANNER_ASCII);
    // newline
    CHAR8 crlf[2] = {'\r','\n'};
    UINTN two=2;
    uefi_call_wrapper(Serial->Write, 3, Serial, &two, (VOID*)crlf);
  } else {
    // Fallback: at least show something on console about serial
    Print(L"[uefi] Serial I/O protocol not found.\n");
  }

  return EFI_SUCCESS;
}
