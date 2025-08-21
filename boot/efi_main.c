#include <efi.h>
#include <efilib.h>
#include "banner.h"

#ifndef SOVRN_BANNER
#  ifdef BANNER_TEXT
#    define SOVRN_BANNER BANNER_TEXT
#  else
#    define SOVRN_BANNER "SOVRN ENGINE ONLINE\n"
#  endif
#endif

// --- Minimal 16550A UART on COM1 (0x3F8), no EDK2 headers required ---
static inline void outb(unsigned short port, unsigned char val) {
  __asm__ volatile ("outb %0,%1" : : "a"(val), "Nd"(port));
}
static inline unsigned char inb(unsigned short port) {
  unsigned char ret;
  __asm__ volatile ("inb %1,%0" : "=a"(ret) : "Nd"(port));
  return ret;
}

static void serial_init(void) {
  const unsigned short COM1 = 0x3F8;
  outb(COM1 + 1, 0x00);      // IER: disable interrupts
  outb(COM1 + 3, 0x80);      // LCR: enable DLAB
  outb(COM1 + 0, 0x01);      // DLL: 115200 baud (divisor 1)
  outb(COM1 + 1, 0x00);      // DLM
  outb(COM1 + 3, 0x03);      // LCR: 8N1, DLAB=0
  outb(COM1 + 2, 0xC7);      // FCR: enable FIFO, clear, 14-byte threshold
  outb(COM1 + 4, 0x0B);      // MCR: IRQs enabled, RTS/DSR set
}

static void serial_putc(char c) {
  const unsigned short COM1 = 0x3F8;
  // Wait for THR empty (LSR bit 5)
  while ((inb(COM1 + 5) & 0x20) == 0) { }
  outb(COM1 + 0, (unsigned char)c);
}

static void serial_write(const char *s) {
  while (*s) {
    if (*s == '\n') serial_putc('\r');
    serial_putc(*s++);
  }
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    InitializeLib(ImageHandle, SystemTable);

    // UEFI console
    Print(L"%a", SOVRN_BANNER);
#ifdef SOVRN_COMMIT
    Print(L"COMMIT=%a\n", SOVRN_COMMIT);
#endif
#ifdef SOVRN_VERSION
    Print(L"VERSION=%a\n", SOVRN_VERSION);
#endif

    // Serial mirror
    serial_init();
    serial_write(SOVRN_BANNER);
#ifdef SOVRN_COMMIT
    serial_write("COMMIT="); serial_write(SOVRN_COMMIT); serial_write("\n");
#endif
#ifdef SOVRN_VERSION
    serial_write("VERSION="); serial_write(SOVRN_VERSION); serial_write("\n");
#endif

    return EFI_SUCCESS;
}
