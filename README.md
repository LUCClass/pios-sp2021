
# Rasbperry Pi OS

This is a shell for a custom bare metal operating system on the Raspberry Pi. It is intended to be run inside `qemu` on the Raspberry Pi 3 target (when this doc was written, there was no Pi 4 target).


## The Boot Process

On most ARM systems, we use `u-boot` to load the OS. The Pi does not do that---it has a weird boot process.

1. On power up, the ARM CPU is held in reset while the GPU loads and begins executing a hard-coded bootloader. 
2. The GPU bootloader loads some firmware files out of the first partition of the SD card. One of the files on the SD card is the Linux kernel, and it must be called `kernel8.img`. The Linux kernel has a special Raspberry Pi-specific header that tells the GPU bootloader where it should be placed in memory.
3. After the GPU bootloader is done loading the kernel into main memory, it brings the ARM CPU out of reset, and the ARM begins running the kernel.




This shell code in this repository creates `kernel8.img` that consists of a Linux kernel header at the beginning followed by our code. Even though we are not writing the Linux kernel, we still use the same header so our OS can be loaded by the Pi's bootloader. The Linux kernel header is a data structure that tells the Raspberry Pi bootloader where to load our OS image in memory and where to start executing code inside the OS image. The kernel header is located at the top of `boot.s`, and you can find a document that explains the header format [here](https://www.kernel.org/doc/Documentation/arm64/booting.txt). We use a special linker script (`kernel.ld`) to force the kernel header to be located at the beginning of our binary file.


## Features of the Makefile

The Makefile in this repo has a bunch of useful recipes that you can use:

1. `make` or `make bin` builds the kernel binary `kernel8.img` along with `kernel8.elf`. Both are binary files that contain the compiled code of our operating system. The difference is that `kernel8.img` can be loaded by the Pi bootloader, and `kernel8.elf` is in a standard format that is recognized by tools like `gdb`.
2. `make disassemble | less` disassembles the kernel binary. Useful if you need to see where functions or variables are located in memory.
3. `make debug` runs the kernel in qemu while allowing you to step through it line-by-line in gdb.
4. `make run` runs your kernel in qemu with no debugger.
5. `make clean` removes all compiled object files.


