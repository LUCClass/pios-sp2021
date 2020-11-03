

CC := aarch64-none-elf-gcc
LD := aarch64-none-elf-ld
CONFIGS := -DCONFIG_HEAP_SIZE=4096

CFLAGS := -O0 -ffreestanding -fno-pie -fno-stack-protector -g3 -Wall $(CONFIGS)


ODIR = obj
SDIR = src

OBJS = \
	boot.o \
	kernel_main.o

OBJ = $(patsubst %,$(ODIR)/%,$(OBJS))

$(ODIR)/%.o: $(SDIR)/%.c
	$(CC) $(CFLAGS) -c -g -o $@ $^

$(ODIR)/%.o: $(SDIR)/%.s
	$(CC) $(CFLAGS) -c -g -o $@ $^


all: bin img

bin: $(OBJ)
	$(LD) obj/* -Tkernel.ld -o kernel8.img
	size kernel8.img

clean:
	rm -f obj/*
	rm -f disk.img
	rm -f rootfs.img
	rm -f kernel8.img

debug:
	qemu-system-aarch64 -machine raspi3 -kernel kernel8.img -hda disk.img -S -s -k en-us &
	TERM=xterm aarch64-none-elf-gdb -x gdb_init_prot_mode.txt

run:
	qemu-system-aarch64 -machine raspi3 -kernel kernel8.img -hda disk.img -k en-us

disassemble:
	objdump -D kernel8.img

rootfs.img:
	dd if=/dev/zero of=rootfs.img bs=1M count=16
	mkfs.fat -F12 rootfs.img
	sudo mount rootfs.img /mnt/disk
	sudo mkdir -p /mnt/disk/boot/firmware
	sudo mkdir /mnt/disk/bin
	sudo mkdir /mnt/disk/etc
	sudo umount /mnt/disk

img: rootfs.img
	rm -f disk.img
#	test -s rootfs.img || { dd if=/dev/zero of=rootfs.img bs=1024 count=64k; mkfs.fat -F12 rootfs.img; } # Make rootfs image
	dd if=/dev/zero of=disk.img count=256k bs=512 # Make big disk image (64MB) filled with zeros
	# Copies rootfs image to the first partition
	dd if=rootfs.img of=disk.img seek=2048 conv=notrunc
	# Repartition the disk to occupy the whole image
	./partition.sh disk.img
	# Create a loopback device at offset 1M in the disk.img. This is the start of the partition we created
	sudo losetup /dev/loop1 disk.img -o 1048576
	# Mount the loopback device
	sudo mount /dev/loop1 /mnt/disk
	# Copy kernel image to rootfs
	sudo cp kernel8.img /mnt/disk/boot/
	# Unmount the loopback device
	sudo umount /dev/loop1
	# Unbind the loopback device
	sudo losetup -d /dev/loop1

mountroot:
	sudo test -s /dev/loop1 || { sudo losetup /dev/loop1 disk.img -o 1048576; }
	sudo mount /dev/loop1 /mnt/disk

umountroot:
	sudo umount /dev/loop1 || { echo "/dev/loop1 not mounted"; }
	sudo losetup -d /dev/loop1


