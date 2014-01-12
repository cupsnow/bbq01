qemu-system-x86_64 -m 2G -enable-kvm -show-cursor -usbdevice tablet \
  -hda tmp.img -virtfs local,./tmp2,mount_tag=tmp2 \
  -cdrom ~/dc/05_pkg/os/SW_DVD5_Win_Pro_7w_SP1_64BIT_English_MLF_X17-28603.ISO

