OUTPUT_FORMAT(binary)

INPUT(boot2.o)
OUTPUT(boot2.bin)

SECTIONS
{
    .text 0x7E00 : {
        boot2.o (.text)
    }

    .data : {
        *(.data)
        FILL(0x00);
        . = ALIGN(512);
    }
}
