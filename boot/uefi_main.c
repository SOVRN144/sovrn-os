#include <efi.h>
#include <efilib.h>
#include "banner.h"

/* Minimal COM1 (0x3F8) serial: init + puts */
static inline UINT8 inb(UINT16 p){ UINT8 v; __asm__ volatile("inb %1,%0":"=a"(v):"Nd"(p)); return v; }
static inline void  outb(UINT16 p, UINT8 v){ __asm__ volatile("outb %0,%1"::"a"(v),"Nd"(p)); }

static void serial_init(void){
    UINT16 b = 0x3F8;
    outb(b+1, 0x00);      // IER = 0
    outb(b+3, 0x80);      // LCR: DLAB=1
    outb(b+0, 0x01);      // DLL = 1  (115200 baud)
    outb(b+1, 0x00);      // DLM = 0
    outb(b+3, 0x03);      // LCR: 8N1, DLAB=0
    outb(b+2, 0xC7);      // FCR: enable FIFO, clear
    outb(b+4, 0x0B);      // MCR: DTR | RTS | OUT2
}

static void serial_putc(char c){
    UINT16 b = 0x3F8;
    while((inb(b+5) & 0x20) == 0) {}  // wait for THR empty
    outb(b+0, (UINT8)c);
}

static void serial_puts(const char *s){ while(*s) serial_putc(*s++); }

EFI_STATUS efi_main(EFI_HANDLE image, EFI_SYSTEM_TABLE *st){
    InitializeLib(image, st);

    // Console banner (UEFI text)
    Print(L"SOVRN ENGINE ONLINE PRODUCT=%a VERSION=%a COMMIT=%a BUILD_EPOCH=%a TRIPLE=%a TOOLCHAIN=%a\n",
          PRODUCT, VERSION, COMMIT, BUILD_EPOCH, TRIPLE, TOOLCHAIN);

    // Serial mirror
    serial_init();
    serial_puts("SOVRN ENGINE ONLINE PRODUCT=");
    serial_puts(PRODUCT);
    serial_puts(" VERSION=");
    serial_puts(VERSION);
    serial_puts(" COMMIT=");
    serial_puts(COMMIT);
    serial_puts(" BUILD_EPOCH=");
    serial_puts(BUILD_EPOCH);
    serial_puts(" TRIPLE=");
    serial_puts(TRIPLE);
    serial_puts(" TOOLCHAIN=");
    serial_puts(TOOLCHAIN);
    serial_puts("\n");

    return EFI_SUCCESS;
}
