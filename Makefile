UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
	PLATFORM := darwin
endif
ifeq ($(UNAME),Linux)
	PLATFORM := linux
endif


ifeq ($(PLATFORM), darwin)
	BOOT2_DEPENDS := boot2.s tools/bin/x86_64-linux-gnu-ld
	LD := tools/bin/x86_64-linux-gnu-ld
endif
ifeq ($(PLATFORM), linux)
	BOOT2_DEPENDS := boot2.s
	LD := ld
endif

hd.img: boot1.bin boot2.bin
	cat boot1.bin boot2.bin > hd.img

boot1.bin: boot1.s
	nasm -f bin -o boot1.bin boot1.s

boot2.bin: $(BOOT2_DEPENDS)
	nasm -f bin -o boot2.bin boot2.s

# Custom binutils for OS X
tools/bin/x86_64-linux-gnu-ld:
	sh scripts/fetch_binutils.sh


.PHONY: run
run: hd.img
	qemu-system-x86_64 -monitor stdio -cpu SandyBridge hd.img

.PHONY: clean

clean:
	rm -f *.bin hd.img
