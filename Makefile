boot1.bin: boot1.s
	nasm -f bin -o boot1.bin boot1.s

.PHONY: run
run: boot1.bin
	qemu-system-x86_64 -monitor stdio -cpu SandyBridge boot1.bin

.PHONY: clean

clean:
	rm -f boot1.bin
