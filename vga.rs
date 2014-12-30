use core::prelude::*;

const VIDEO_MEMORY: int = 0xB8000;

pub fn clear_screen() {
    for x in range(0i, 80 * 25) {
        unsafe {
            *((VIDEO_MEMORY + x * 2) as *mut u16) = 0x1F20;
        }
    }
}

pub fn print(message: &str) {
    let mut i = 0i;

    for b in message.bytes() {
        unsafe {
            *((VIDEO_MEMORY + i) as *mut u8) = b
        }

        i += 2;
    }
}

// Should size be a uint? FAT32 probably says what size should be.
pub fn print_memory(addr: uint, size: int) {
    for i in range(0i, size) {
        unsafe {
            *((VIDEO_MEMORY + i * 2) as *mut u8) = *((addr + i as uint) as *const u8);
        }
    }
}
