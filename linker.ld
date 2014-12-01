OUTPUT_FORMAT(binary)

INPUT(boot2.o)
OUTPUT(kernel.bin)

SECTIONS
{
    .text 0x7E00 : {
        *(.text)
    }

    .data : {
        *(.data)
        FILL(0x00);
        . = ALIGN(512);
    }
}
