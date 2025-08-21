CROSS ?= x86_64-elf-
HAS_CROSS := $(shell command -v $(CROSS)gcc 2>/dev/null)
OS := $(shell uname)
OUT := out

# Toolchain + link mode
ifeq ($(HAS_CROSS),)
  CC := cc
  STATIC :=
  ifeq ($(OS),Darwin)
    ENTRY := _main
    NO_PIE := -Wl,-no_pie
  else
    ENTRY := main
    NO_PIE :=
  endif
else
  CC := $(CROSS)gcc
  STATIC := -static
  ENTRY := main
  NO_PIE :=
endif

CFLAGS  := -ffreestanding -Os -nostdlib -ffile-prefix-map=$(PWD)=. -Wall -Wextra
LDFLAGS := $(STATIC) -nostdlib -Wl,-e,$(ENTRY) $(NO_PIE)

all: boot/BOOTX64.EFI kernel.bin $(OUT)/BUILDINFO $(OUT)/BANNER.txt

$(OUT)/BUILDINFO: scripts/buildinfo.sh
	mkdir -p $(OUT)
	./scripts/buildinfo.sh > $(OUT)/BUILDINFO

$(OUT)/BANNER.txt: $(OUT)/BUILDINFO scripts/mkbanner.sh
	mkdir -p $(OUT)
	./scripts/mkbanner.sh

boot/banner.h: $(OUT)/BANNER.txt scripts/gen_banner_h.sh
	./scripts/gen_banner_h.sh

boot/BOOTX64.EFI: boot/efi_main.c boot/banner.h scripts/build_efi.sh
	./scripts/build_efi.sh
	./scripts/size_gate.sh boot/BOOTX64.EFI 524288

kernel.o: kernel/stub.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.bin: kernel.o
	$(CC) -o $@ $^ $(LDFLAGS)
	./scripts/size_gate.sh $@ 524288

# --- ISO build ---
ISO := iso/sovrn.iso

.PHONY: iso
iso: $(ISO)

$(ISO): boot/BOOTX64.EFI scripts/mkiso.sh
	mkdir -p iso
	bash scripts/mkiso.sh

clean:
	rm -f kernel.o kernel.bin
	rm -rf $(OUT) iso
	rm -f boot/BOOTX64.EFI boot/banner.h
