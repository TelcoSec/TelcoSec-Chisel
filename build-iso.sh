#!/bin/bash
set -eo pipefail

echo "=== Building TelcoSec-Chisel Live ISO ==="
echo "Note: This script requires root privileges and must be run on an Ubuntu/Debian host."
BUILD_START=$(date +%s)

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./build-iso.sh)"
  exit 1
fi

WORKDIR="live-iso-work"
ROOTFS="$WORKDIR/chroot"
IMAGE_NAME="telcosec-chisel-live.iso"

# ─── Helper: timed script runner ────────────────────────────────────────────
run_script() {
  local script="$1"
  local name
  name=$(basename "$script")
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║  Starting: $name"
  echo "╚══════════════════════════════════════════════════════╝"
  local start
  start=$(date +%s)
  bash "$script"
  local elapsed=$(( $(date +%s) - start ))
  local mins=$(( elapsed / 60 ))
  local secs=$(( elapsed % 60 ))
  echo ">>> Finished $name in ${mins}m ${secs}s"
}

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

  # Phase 0: Consolidated package install (single apt-get update + install)
  bash /tmp/scripts/00-install-all-packages.sh

  # Phase 1-9: Configuration, compilation, and customization
  bash /tmp/scripts/01-install-base.sh
  bash /tmp/scripts/02-install-sdr.sh
  bash /tmp/scripts/03-install-core-network.sh
  bash /tmp/scripts/04-install-tools.sh
  bash /tmp/scripts/06-install-ue-analysis.sh
  bash /tmp/scripts/05-desktop-customization.sh
  bash /tmp/scripts/07-install-installer.sh
  bash /tmp/scripts/08-system-optimization.sh
  bash /tmp/scripts/09-install-5ghoul.sh

  # ─── Aggressive cleanup to minimize squashfs size ──────────────────────────
  echo '--> Running aggressive cleanup before squashfs...'

  # APT caches
  apt-get autoremove -y
  apt-get clean
  rm -rf /var/lib/apt/lists/*

  # Pip caches
  rm -rf /root/.cache/pip
  rm -rf /home/telcosec/.cache/pip

  # Conda package cache (~500 MB)
  if [ -x /opt/telcosec/miniconda/bin/conda ]; then
    /opt/telcosec/miniconda/bin/conda clean -afy || true
  fi

  # Git metadata from cloned source repos (keep the code, drop .git history)
  find /opt/telcosec/src -name '.git' -type d -exec rm -rf {} + 2>/dev/null || true
  find /opt/telcosec -maxdepth 2 -name '.git' -type d -exec rm -rf {} + 2>/dev/null || true

  # C/C++ build intermediaries (.o files, CMakeFiles dirs)
  find /opt/telcosec/src -name '*.o' -delete 2>/dev/null || true
  find /opt/telcosec/src -name 'CMakeFiles' -type d -exec rm -rf {} + 2>/dev/null || true

  # Documentation and man pages (saves ~100-200 MB)
  rm -rf /usr/share/doc/*
  rm -rf /usr/share/man/*

  # Log files
  find /var/log -type f -name '*.log' -delete 2>/dev/null || true
  find /var/log -type f -name '*.gz' -delete 2>/dev/null || true

  # Tmp files
  rm -rf /tmp/scripts
  rm -rf /tmp/calamares-config
  rm -rf /tmp/docs
  rm -rf /tmp/udev /tmp/security /tmp/menu /tmp/wireshark /tmp/boot
  rm -f /tmp/.packages-installed
  rm -rf /tmp/*
"

# Trigger cleanup immediately before packing to free mounts
cleanup
trap - EXIT

echo "--> Packing filesystem into squashfs..."
mkdir -p $WORKDIR/image/casper
mksquashfs $ROOTFS $WORKDIR/image/casper/filesystem.squashfs \
  -comp zstd -Xcompression-level 19 \
  -b 1M \
  -processors $(nproc) \
  -no-exports \
  -noappend

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

BUILD_ELAPSED=$(( $(date +%s) - BUILD_START ))
BUILD_MINS=$(( BUILD_ELAPSED / 60 ))
BUILD_SECS=$(( BUILD_ELAPSED % 60 ))
ISO_SIZE=$(du -sh "$IMAGE_NAME" | cut -f1)

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Build Complete: $IMAGE_NAME"
echo "║  ISO Size: $ISO_SIZE"
echo "║  Total Build Time: ${BUILD_MINS}m ${BUILD_SECS}s"
echo "╚══════════════════════════════════════════════════════╝"
