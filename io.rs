// Functions that wrap IO port instructions
// See: http://wiki.osdev.org/I/O_Ports

#[inline(always)]
pub fn outb(port: u16, value: u8) {
    unsafe {
        asm!("out dx, al" :: "{dx}"(port), "{al}"(value) :: "intel", "volatile");
    }
}

#[inline(always)]
pub fn inb(port: u16) -> u8 {
    let res: u8;

    unsafe {
        asm!("in al, dx" : "={al}"(res) : "{dx}"(port) :: "intel", "volatile");
    }

    res
}

#[inline(always)]
pub fn insw(port: u16) -> u16 {
    let res: u16;

    unsafe {
        asm!("in ax, dx" : "={ax}"(res) : "{dx}"(port) :: "intel", "volatile");
    }

    res
}
