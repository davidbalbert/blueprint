OUTPUT_FORMAT(binary)

SECTIONS
{
    . = 0x7E00;
    .text : {
        *(.text)
    }

    .data : {
        *(.data)
        FILL(0x00);
        . = ALIGN(512);
    }
}
