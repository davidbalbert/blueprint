UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
	PLATFORM := darwin
endif
ifeq ($(UNAME),Linux)
	PLATFORM := linux
endif


ifeq ($(PLATFORM), darwin)
	CUSTOM_LD := tools/bin/x86_64-linux-gnu-ld
	LD := tools/bin/x86_64-linux-gnu-ld
endif
ifeq ($(PLATFORM), linux)
	CUSTOM_LD := ""
	LD := ld
endif

hd.img: boot1.bin kernel.bin
	cat boot1.bin kernel.bin > hd.img

boot1.bin: boot1.s
	nasm -f bin -o boot1.bin boot1.s

kernel.bin: boot2.o linker.ld $(CUSTOM_LD)
	$(LD) -T linker.ld

boot2.o: boot2.s
	nasm -f elf64 boot2.s



# Custom binutils for OS X
tools/bin/x86_64-linux-gnu-ld:
	sh scripts/fetch_binutils.sh

.PHONY: run
run: hd.img
	qemu-system-x86_64 -monitor stdio -cpu SandyBridge hd.img

.PHONY: clean

clean:
	rm -f *.o *.bin hd.img
