#!/bin/bash
# $Id$

echo "with -nographic"
echo "C-a      escape"
echo "C-a h    print this help"
echo "C-a x    exit emulator"
echo .

qemu-system-arm -m 256 -M versatilepb -nographic \
  -kernel package/linux/arch/arm/boot/uImage \
  -append 'root=/dev/ram console=ttyAMA0'
