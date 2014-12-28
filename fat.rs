// Functions for reading data off a FAT32 formatted active primary partition.

use core::prelude::*;

use util;
use ata;

struct Partition {
    active: u8,
    start_head: u8,
    start_sector_and_cylinder: u16,
    system_id: u8,
    end_head: u8,
    end_sector_and_cylinder: u16,
    lba_start: u32,
    lba_size: u32,
}

impl Partition {
    fn is_unused(&self) -> bool {
        self.system_id == 0
    }

    fn is_active(&self) -> bool {
        self.active == 0x80
    }
}

fn get_partition_table() -> &'static [Partition, ..4] {
    unsafe {
        &*((0x7c00i + 0x1be) as *const [Partition, ..4])
    }
}

fn active_partition(table: &[Partition, ..4]) -> &Partition {
    let opt = table.iter().find(|e| !e.is_unused() && e.is_active());

    match opt {
        Some(p) => p,
        None => {
            util::die("No active partition");
        },
    }
}

pub fn file_size(path: &str) -> uint {
    0
}

pub fn read_file(path: &str, destination: uint) {
    let partition_table = get_partition_table();

    let active_partition = active_partition(partition_table);

}
