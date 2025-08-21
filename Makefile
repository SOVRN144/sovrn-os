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

all: kernel.bin $(OUT)/BUILDINFO $(OUT)/BANNER.txt boot/mbr.bin

$(OUT)/BUILDINFO: scripts/buildinfo.sh
	mkdir -p $(OUT)
	./scripts/buildinfo.sh > $(OUT)/BUILDINFO

$(OUT)/BANNER.txt: $(OUT)/BUILDINFO scripts/mkbanner.sh
	mkdir -p $(OUT)
	./scripts/mkbanner.sh

boot/mbr.bin: scripts/mkmbr.sh
	./scripts/mkmbr.sh

kernel.o: kernel/stub.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.bin: kernel.o
	$(CC) -o $@ $^ $(LDFLAGS)
	./scripts/size_gate.sh $@ 524288

# --- ISO build ---
ISO := iso/sovrn.iso

.PHONY: iso
iso: $(ISO)

$(ISO): boot/BOOTX64.EFI boot/mbr.bin scripts/mkiso.sh
	mkdir -p iso
	bash scripts/mkiso.sh

clean:
	rm -f kernel.o kernel.bin
	rm -rf $(OUT) iso
	rm -f boot/mbr.bin
