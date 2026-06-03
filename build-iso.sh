#!/bin/bash
set -e

echo "=== Building TelcoSec-Chisel Live ISO ==="
echo "Note: This script requires root privileges and must be run on an Ubuntu/Debian host."

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./build-iso.sh)"
  exit 1
fi

WORKDIR="live-iso-work"
ROOTFS="$WORKDIR/chroot"
IMAGE_NAME="telcosec-chisel-live.iso"

mkdir -p $ROOTFS

echo "--> Bootstrapping base Ubuntu system..."
debootstrap --arch=amd64 noble $ROOTFS http://archive.ubuntu.com/ubuntu/

echo "--> Configuring APT repositories inside chroot..."
cat << 'EOF' > $ROOTFS/etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
EOF

# Setup cleanup trap for mounts
cleanup() {
  echo "--> Cleaning up mounts..."
  umount -lf $ROOTFS/dev/pts || true
  umount -lf $ROOTFS/dev || true
  umount -lf $ROOTFS/sys || true
  umount -lf $ROOTFS/proc || true
}
trap cleanup EXIT

echo "--> Copying builder scripts into chroot..."
cp -r builder/scripts $ROOTFS/tmp/scripts
cp -r builder/calamares $ROOTFS/tmp/calamares-config
cp -r builder/docs $ROOTFS/tmp/docs
cp -r builder/udev $ROOTFS/tmp/udev
cp -r builder/security $ROOTFS/tmp/security
cp -r builder/menu $ROOTFS/tmp/menu
cp -r builder/wireshark $ROOTFS/tmp/wireshark
cp -r builder/boot $ROOTFS/tmp/boot

echo "--> Mounting virtual filesystems for chroot..."
mkdir -p $ROOTFS/proc $ROOTFS/sys $ROOTFS/dev
mount -t proc /proc $ROOTFS/proc
mount -t sysfs /sys $ROOTFS/sys
mount --bind /dev $ROOTFS/dev
mount --bind /dev/pts $ROOTFS/dev/pts

echo "--> Executing provisioning scripts inside chroot..."
chroot $ROOTFS /bin/bash -ec "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y sudo
  bash /tmp/scripts/01-install-base.sh
  bash /tmp/scripts/02-install-sdr.sh
  bash /tmp/scripts/03-install-core-network.sh
  bash /tmp/scripts/04-install-tools.sh
  bash /tmp/scripts/06-install-ue-analysis.sh
  bash /tmp/scripts/05-desktop-customization.sh
  bash /tmp/scripts/07-install-installer.sh
  bash /tmp/scripts/08-system-optimization.sh
  bash /tmp/scripts/09-install-5ghoul.sh
  apt-get clean
  rm -rf /tmp/scripts
  rm -rf /tmp/calamares-config
  rm -rf /tmp/docs
  rm -rf /tmp/udev /tmp/security /tmp/menu /tmp/wireshark /tmp/boot
"

# Trigger cleanup immediately before packing to free mounts
cleanup
trap - EXIT

echo "--> Packing filesystem into squashfs..."
mkdir -p $WORKDIR/image/casper
mksquashfs $ROOTFS $WORKDIR/image/casper/filesystem.squashfs -comp xz

echo "--> Copying kernel and initrd..."
vmlinuz_file=$(find $ROOTFS/boot/ -name "vmlinuz-*" -type f | sort -V | tail -n 1)
initrd_file=$(find $ROOTFS/boot/ -name "initrd.img-*" -type f | sort -V | tail -n 1)
if [ -z "$vmlinuz_file" ] || [ -z "$initrd_file" ]; then
  echo "ERROR: Kernel or initrd not found in chroot /boot directory!"
  exit 1
fi
cp "$vmlinuz_file" $WORKDIR/image/casper/vmlinuz
cp "$initrd_file" $WORKDIR/image/casper/initrd

echo "--> Generating GRUB boot menu..."
mkdir -p $WORKDIR/image/boot/grub
cat << 'EOF' > $WORKDIR/image/boot/grub/grub.cfg
set default=0
set timeout=10

insmod all_video
insmod font
if loadfont /boot/grub/fonts/unicode.pf2 ; then
  set gfxmode=auto
  insmod gfxterm
  terminal_output gfxterm
fi

menuentry "Try TelcoSec-Chisel without installing" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=telcosec user-fullname="TelcoSec Researcher" hostname=telcosec-chisel quiet splash ---
    initrd /casper/initrd
}

menuentry "Install TelcoSec-Chisel (Directly run Calamares)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=telcosec user-fullname="TelcoSec Researcher" hostname=telcosec-chisel quiet splash systemd.run=/etc/skel/Desktop/install-telcosec.desktop ---
    initrd /casper/initrd
}

menuentry "Try TelcoSec-Chisel (Safe Graphics mode)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=telcosec user-fullname="TelcoSec Researcher" hostname=telcosec-chisel nomodeset quiet splash ---
    initrd /casper/initrd
}
EOF

echo "--> Generating ISO using grub-mkrescue..."
grub-mkrescue -o $IMAGE_NAME $WORKDIR/image/

echo "=== Build Complete: $IMAGE_NAME ==="
