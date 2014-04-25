QEMU="qemu-system-x86_64 -machine q35"
MEM="-m 2G"
# KVM=-enable-kvm 
CURSOR="-show-cursor -usbdevice tablet"
DISK="tool/usr/vm/win.img"
CDROM="-cdrom /home/joelai/Documents/os/SW_DVD5_Win_Pro_7w_SP1_64BIT_English_MLF_X17-28603.ISO"

$QEMU $MEM $KVM $CURSOR $DISK $CDROM

