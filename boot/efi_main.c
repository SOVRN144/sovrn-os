#include <efi.h>
#include <efilib.h>
#include "banner.h"

// banner.h should provide ASCII strings. We accept a few names to be tolerant.
#ifndef SOVRN_BANNER
#  ifdef BANNER_TEXT
#    define SOVRN_BANNER BANNER_TEXT
#  else
#    define SOVRN_BANNER "SOVRN ENGINE ONLINE\n"
#  endif
#endif

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    InitializeLib(ImageHandle, SystemTable);

    // Print ASCII banner to UEFI console (Print supports %a for ASCII)
    Print(L"%a", SOVRN_BANNER);

    // If banner.h exposes COMMIT or VERSION, show them too
    #ifdef SOVRN_COMMIT
      Print(L"COMMIT=%a\n", SOVRN_COMMIT);
    #endif
    #ifdef SOVRN_VERSION
      Print(L"VERSION=%a\n", SOVRN_VERSION);
    #endif

    return EFI_SUCCESS;
}
