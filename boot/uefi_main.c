#include <efi.h>
#include <efilib.h>
#include <Protocol/SerialIo.h>

static VOID print16(EFI_SYSTEM_TABLE *ST, CHAR16 *w) {
  // Ignore status from OutputString; never gate success on console quirks
  ST->ConOut->OutputString(ST->ConOut, w);
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  InitializeLib(ImageHandle, SystemTable);

  // Required: UEFI console
  CHAR16 *msg = L"SOVRN ENGINE ONLINE\r\n";
  print16(SystemTable, msg);

#ifndef SOVRN_NO_SERIAL
  // Optional: Serial — best effort, never propagate errors
  EFI_GUID SerialGuid = SERIAL_IO_PROTOCOL;
  EFI_SERIAL_IO_PROTOCOL *Serial = NULL;
  EFI_STATUS s = uefi_call_wrapper(BS->LocateProtocol, 3, &SerialGuid, NULL, (void**)&Serial);
  if (!EFI_ERROR(s) && Serial) {
    // 115200, 8N1
    (void)Serial->SetAttributes(Serial, 115200, 0, 0, DefaultParity, 8, OneStopBit);
    UINTN len_bytes = 2 * 20;   // worst case; we’ll just write ASCII subset
    // Quick ASCII->UTF16 on the stack
    CHAR16 buf[64]; UINTN i=0;
    for (const CHAR16 *p = msg; *p && i < (sizeof buf/sizeof buf[0])-1; ++p) buf[i++] = *p;
    buf[i] = 0;
    // Serial->Write expects bytes; cast buffer and length
    UINTN bytes = i * sizeof(CHAR16);
    (void)Serial->Write(Serial, &bytes, (VOID*)buf);
  }
#endif

  // Tiny stall to placate firmwares that dislike instant exit
  BS->Stall(300000); // 300 ms
  return EFI_SUCCESS;
}
