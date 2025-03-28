MEMORY
{
    ROM (0x0000-0x7FFF) : ORIGIN = 0x0000, LENGTH = 32K
    RAM (0xC000-0xDFFF) : ORIGIN = 0xC000, LENGTH = 8K
    WRAM (0xD000-0xDFFF) : ORIGIN = 0xD000, LENGTH = 8K
    VRAM (0x8000-0x9FFF) : ORIGIN = 0x8000, LENGTH = 8K
}

SECTIONS
{
    .text : {
        *(.text)
    } > ROM

    .data : {
        *(.data)
    } > RAM

    .bss : {
        *(.bss)
    } > WRAM
}