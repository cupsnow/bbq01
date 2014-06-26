#!/bin/bash
# $Id$

echo "with -nographic"
echo "C-a      escape"
echo "C-a h    print this help"
echo "C-a x    exit emulator"
echo .

board="-m 256 -M versatilepb -serial mon:stdio" # -serial stdio # -nographic
kernel="-kernel package/linux/arch/arm/boot/uImage"
disk="-drive file=release/rootfs.img,media=disk"
bootargs="-append 'root=/dev/ram console=ttyAMA0'"

eval "qemu-system-arm $board $kernel $disk $bootargs"
