#include <efi.h>
#include <stdint.h>
#include "buildinfo_autogen.h"

/* very small COM1 (0x3F8) serial driver */
static inline void outb(uint16_t p, uint8_t v){ __asm__ volatile("outb %0,%1"::"a"(v),"Nd"(p)); }
static inline uint8_t inb(uint16_t p){ uint8_t r; __asm__ volatile("inb %1,%0":"=a"(r):"Nd"(p)); return r; }

static void serial_init(void){
  const uint16_t COM1=0x3F8;
  outb(COM1+1,0x00);        // disable interrupts
  outb(COM1+3,0x80);        // DLAB on
  outb(COM1+0,0x01);        // divisor low (115200)
  outb(COM1+1,0x00);        // divisor high
  outb(COM1+3,0x03);        // 8N1, DLAB off
  outb(COM1+2,0xC7);        // FIFO on, clear, 14-byte
  outb(COM1+4,0x0B);        // DTR, RTS, OUT2
}
static void serial_putc(char c){
  const uint16_t LSR=0x3F8+5, TX=0x3F8;
  while((inb(LSR)&0x20)==0) { }
  outb(TX,(uint8_t)c);
}
static void serial_puts(const char* s){ while(*s) serial_putc(*s++); }

/* print ASCII to UEFI console */
static void console_puts(EFI_SYSTEM_TABLE* ST, const char* s){
  CHAR16 buf[256];
  while(*s){
    UINTN n=0;
    for(; s[n] && n<255; ++n) buf[n]=(CHAR16)(unsigned char)s[n];
    buf[n]=0;
    ST->ConOut->OutputString(ST->ConOut, buf);
    s += n;
  }
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *ST) {
  serial_init();

  const char* banner =
    "SOVRN ENGINE ONLINE "
    "PRODUCT="BI_PRODUCT" "
    "VERSION="BI_VERSION" "
    "COMMIT="BI_COMMIT" "
    "BUILD_EPOCH="BI_BUILD_EPOCH" "
    "TRIPLE="BI_TRIPLE" "
    "TOOLCHAIN="BI_TOOLCHAIN"\r\n";

  console_puts(ST, banner);
  serial_puts(banner);

  // give humans a moment
  ST->BootServices->Stall(1000000);

  // warm reboot; with -no-reboot QEMU exits and CI can grep serial
  ST->RuntimeServices->ResetSystem(EfiResetWarm, EFI_SUCCESS, 0, NULL);
  for(;;){} // never return to firmware
}
