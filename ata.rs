// Functions for reading data off the primary hard drive using 48 bit LBA PIO mode. Reads data off
// of the primary (master) disc on the primary ATA bus.
// See: http://wiki.osdev.org/ATA_PIO_Mode

use tinyrt::prelude::*;
use tinyrt::iter;

use io;

// IO ports

const DATA: u16         = 0x1F0;
const FEATURES: u16     = 0x1F1;
const COUNT: u16        = 0x1F2;
const LOW: u16          = 0x1F3;
const MID: u16          = 0x1F4;
const HIGH: u16         = 0x1F5;
const DRIVE: u16        = 0x1F6;
const COMMAND: u16      = 0x1F7;
const STATUS: u16       = 0x1F7; // Same as COMMAND

const BYTES_PER_SECTOR: u16 = 512;

fn ready() -> bool {
    // Bit 3 (zero indexed) of the status byte is set when the drive has data to transfer.
    io::inb(STATUS) & 8 != 0
}

pub fn read(start: u64, count: u16, destination: uint) {
    // Select LBA mode (are we also selecting the primary drive?)
    io::outb(DRIVE, 0x40);

    // For performance, don't send writes to the same IO port in a row.

    io::outb(COUNT, (count >> 8) as u8);

    io::outb(LOW, (start >> 24 & 0xFF) as u8); // Byte 4 (1 indexed)
    io::outb(MID, (start >> 32 & 0xFF) as u8); // Byte 5
    io::outb(HIGH, (start >> 40 & 0xFF) as u8); // Byte 6

    io::outb(COUNT, (count & 0xFF) as u8);

    io::outb(LOW, (start & 0xFF) as u8); // Byte 1
    io::outb(MID, (start >> 8 & 0xFF) as u8); // Byte 2
    io::outb(HIGH, (start >> 16 & 0xFF) as u8); // Byte 3

    io::outb(COMMAND, 0x24); // 0x24 == READ SECTORS EXT


    // loop until we're ready
    while !ready() {};

    for offset in iter::range_step(0i, (count * BYTES_PER_SECTOR) as int, 2i) {
        let word = io::insw(DATA);
        unsafe {
            *((destination + offset as uint) as *mut u16) = word;
        }
    }
}
