#!/bin/bash
set -eo pipefail

# ─── Argument parsing ─────────────────────────────────────────────────────────
RESUME=false
RESUME_FROM=0
PACK_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --resume)
      RESUME=true
      ;;
    --resume-from=*)
      RESUME=true
      RESUME_FROM="${arg#--resume-from=}"
      # Strip leading zeros for numeric comparison, keep at least "0"
      RESUME_FROM=$(( 10#${RESUME_FROM} ))
      ;;
    --pack-only)
      PACK_ONLY=true
      ;;
    --help|-h)
      cat << 'HELP'
Usage: sudo ./build-iso.sh [OPTIONS]

  (no options)           Full clean build — wipes chroot and starts fresh
  --resume               Keep existing chroot; re-run all provisioning phases
  --resume-from=N        Keep existing chroot; skip phases before N
                           e.g. --resume-from=03  resumes from phase 03
                           e.g. --resume-from=7   resumes from phase 07
  --pack-only            Skip provisioning entirely; pack existing chroot into
                           squashfs + ISO (useful for re-signing or re-branding)

Examples:
  sudo ./build-iso.sh                    # fresh full build
  sudo ./build-iso.sh --resume           # re-run everything on existing chroot
  sudo ./build-iso.sh --resume-from=04   # skip 00-03, resume from 04 onward
  sudo ./build-iso.sh --pack-only        # just repack squashfs → ISO

HELP
      exit 0
      ;;
    *)
      echo "ERROR: Unknown option: $arg  (try --help)"
      exit 1
      ;;
  esac
done

# ─── Header ───────────────────────────────────────────────────────────────────
echo "=== TelcoSec-Chisel ISO Builder ==="
if $PACK_ONLY; then
  echo "    Mode: pack-only (repack existing chroot)"
elif $RESUME && [ "$RESUME_FROM" -gt 0 ]; then
  echo "    Mode: resume from phase $(printf '%02d' $RESUME_FROM)"
elif $RESUME; then
  echo "    Mode: resume (keep chroot, re-run all phases)"
else
  echo "    Mode: full clean build"
fi
BUILD_START=$(date +%s)

# ─── Root check ───────────────────────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: Run as root (sudo ./build-iso.sh)"
  exit 1
fi

# ─── Prerequisite check ───────────────────────────────────────────────────────
echo "--> Checking prerequisites..."
MISSING=()
for tool in debootstrap mksquashfs grub-mkrescue xorriso mformat; do
  command -v "$tool" >/dev/null 2>&1 || MISSING+=("$tool")
done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ERROR: Missing required tools: ${MISSING[*]}"
  echo "Install with: apt-get install debootstrap squashfs-tools grub-pc-bin grub-efi-amd64-bin xorriso mtools"
  exit 1
fi

# ─── Work directory ───────────────────────────────────────────────────────────
# 9p/drvfs/NTFS mounts don't support POSIX special files needed by debootstrap.
FS_TYPE=$(df -T . | awk 'NR==2 {print $2}')
if [[ "$FS_TYPE" =~ ^(9p|drvfs|vboxsf|fuse|cifs|nfs|vfat|ntfs|msdos)$ ]]; then
  echo "--> Non-POSIX filesystem ($FS_TYPE) — redirecting build to /var/tmp/live-iso-work"
  WORKDIR="/var/tmp/live-iso-work"
else
  WORKDIR="live-iso-work"
fi

ROOTFS="$WORKDIR/chroot"
IMAGE_NAME="telcosec-chisel-live.iso"

# ─── Mount cleanup ────────────────────────────────────────────────────────────
cleanup() {
  rm -f "$ROOTFS/usr/sbin/policy-rc.d" "$ROOTFS/usr/local/sbin/udevadm" 2>/dev/null || true
  chroot "$ROOTFS" dpkg-divert --local --rename --remove /usr/bin/udevadm 2>/dev/null || true
  umount -lf "$ROOTFS/dev/pts" 2>/dev/null || true
  umount -lf "$ROOTFS/dev"     2>/dev/null || true
  umount -lf "$ROOTFS/sys"     2>/dev/null || true
  umount -lf "$ROOTFS/proc"    2>/dev/null || true
}
trap cleanup EXIT

# ─── Chroot setup ─────────────────────────────────────────────────────────────
if $PACK_ONLY; then
  # ── pack-only: existing chroot must exist ───────────────────────────────────
  if [ ! -d "$ROOTFS" ]; then
    echo "ERROR: --pack-only requires an existing chroot at $ROOTFS"
    echo "       Run without flags to create one first."
    exit 1
  fi
  echo "--> Using existing chroot at $ROOTFS (pack-only mode)"

elif $RESUME; then
  # ── resume: keep existing chroot ────────────────────────────────────────────
  if [ ! -d "$ROOTFS" ]; then
    echo "ERROR: --resume requires an existing chroot at $ROOTFS"
    echo "       Run without flags to create one first."
    exit 1
  fi
  echo "--> Resuming with existing chroot at $ROOTFS"

  # Tear down any lingering mounts from a previous interrupted run
  cleanup

  # ── Re-apply service suppression (removed at end of each run) ───────────────
  echo "--> Re-applying chroot service suppression..."
  cat > "$ROOTFS/usr/sbin/policy-rc.d" << 'POLICY'
#!/bin/sh
exit 101
POLICY
  chmod +x "$ROOTFS/usr/sbin/policy-rc.d"

  chroot "$ROOTFS" dpkg-divert --local --rename --add /usr/bin/udevadm 2>/dev/null || true
  cat > "$ROOTFS/usr/bin/udevadm" << 'UDEVADM'
#!/bin/sh
exit 0
UDEVADM
  chmod +x "$ROOTFS/usr/bin/udevadm"
  mkdir -p "$ROOTFS/usr/local/sbin"
  cp "$ROOTFS/usr/bin/udevadm" "$ROOTFS/usr/local/sbin/udevadm"

  # Re-copy builder assets (scripts may have changed since last run)
  echo "--> Re-syncing builder assets into chroot..."
  cp -r builder/scripts   "$ROOTFS/tmp/scripts"
  cp -r builder/calamares "$ROOTFS/tmp/calamares-config"
  cp -r builder/docs      "$ROOTFS/tmp/docs"
  cp -r builder/udev      "$ROOTFS/tmp/udev"
  cp -r builder/security  "$ROOTFS/tmp/security"
  cp -r builder/menu      "$ROOTFS/tmp/menu"
  cp -r builder/wireshark "$ROOTFS/tmp/wireshark"
  cp -r builder/boot      "$ROOTFS/tmp/boot"

  # Re-mount virtual filesystems
  echo "--> Mounting virtual filesystems..."
  mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev"
  mount -t proc  /proc "$ROOTFS/proc"
  mount -t sysfs /sys  "$ROOTFS/sys"
  mount --bind   /dev  "$ROOTFS/dev"
  mount --bind   /dev/pts "$ROOTFS/dev/pts"

else
  # ── Full clean build ─────────────────────────────────────────────────────────
  cleanup  # clear any leftover mounts from a previous run

  if [ -d "$ROOTFS" ]; then
    echo "--> Removing old chroot..."
    rm -rf "$ROOTFS"
  fi
  mkdir -p "$ROOTFS"

  # Debootstrap
  echo "--> Bootstrapping Ubuntu 24.04 Noble..."
  debootstrap \
    --arch=amd64 \
    --include=ca-certificates,locales \
    noble "$ROOTFS" http://archive.ubuntu.com/ubuntu/

  # APT sources
  echo "--> Configuring APT sources..."
  cat > "$ROOTFS/etc/apt/sources.list" << 'SOURCES'
deb http://archive.ubuntu.com/ubuntu noble           main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-updates   main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu noble-backports main restricted universe multiverse
SOURCES

  # Basic chroot environment
  echo "--> Preparing chroot environment..."
  echo "telcosec-chisel" > "$ROOTFS/etc/hostname"
  cat > "$ROOTFS/etc/hosts" << 'HOSTS'
127.0.0.1   localhost
127.0.1.1   telcosec-chisel
::1         localhost ip6-localhost ip6-loopback
HOSTS
  cp /etc/resolv.conf "$ROOTFS/etc/resolv.conf" 2>/dev/null || true

  # Locale generation
  # debootstrap includes the locales package but doesn't generate any locale
  # files. Package postinstalls (kismet, etc.) fail with "Cannot set LC_ALL"
  # until at least one locale exists.
  echo "en_US.UTF-8 UTF-8" > "$ROOTFS/etc/locale.gen"
  chroot "$ROOTFS" locale-gen
  chroot "$ROOTFS" update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

  # Chroot service suppression
  # Hardware package postinstalls call udevadm/invoke-rc.d which fail inside
  # a chroot. Suppress them for the entire provisioning phase.
  cat > "$ROOTFS/usr/sbin/policy-rc.d" << 'POLICY'
#!/bin/sh
exit 101
POLICY
  chmod +x "$ROOTFS/usr/sbin/policy-rc.d"

  # Use dpkg-divert so the no-op at /usr/bin/udevadm survives udev package
  # installation. Hardware postinstalls call udevadm via absolute path.
  mkdir -p "$ROOTFS/usr/bin"
  chroot "$ROOTFS" dpkg-divert --local --rename --add /usr/bin/udevadm 2>/dev/null || true
  cat > "$ROOTFS/usr/bin/udevadm" << 'UDEVADM'
#!/bin/sh
exit 0
UDEVADM
  chmod +x "$ROOTFS/usr/bin/udevadm"
  mkdir -p "$ROOTFS/usr/local/sbin"
  cp "$ROOTFS/usr/bin/udevadm" "$ROOTFS/usr/local/sbin/udevadm"

  # Copy builder assets
  echo "--> Copying builder assets..."
  cp -r builder/scripts   "$ROOTFS/tmp/scripts"
  cp -r builder/calamares "$ROOTFS/tmp/calamares-config"
  cp -r builder/docs      "$ROOTFS/tmp/docs"
  cp -r builder/udev      "$ROOTFS/tmp/udev"
  cp -r builder/security  "$ROOTFS/tmp/security"
  cp -r builder/menu      "$ROOTFS/tmp/menu"
  cp -r builder/wireshark "$ROOTFS/tmp/wireshark"
  cp -r builder/boot      "$ROOTFS/tmp/boot"

  # Mount virtual filesystems
  echo "--> Mounting virtual filesystems..."
  mkdir -p "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/dev"
  mount -t proc  /proc "$ROOTFS/proc"
  mount -t sysfs /sys  "$ROOTFS/sys"
  mount --bind   /dev  "$ROOTFS/dev"
  mount --bind   /dev/pts "$ROOTFS/dev/pts"
fi

# ─── Provisioning ─────────────────────────────────────────────────────────────
if ! $PACK_ONLY; then
  echo "--> Running provisioning scripts..."

  _phase() {
    local num="$1"; local label="$2"; shift 2
    if $RESUME && [ "$num" -lt "$RESUME_FROM" ]; then
      printf '\n┌─ %-50s [skipped]\n' "$label"
      return 0
    fi
    local t0; t0=$(date +%s)
    printf '\n┌─ %-50s\n' "$label"
    "$@"
    printf '└─ done in %dm%02ds\n' \
      $(( ($(date +%s)-t0) / 60 )) $(( ($(date +%s)-t0) % 60 ))
  }

  chroot_run() {
    chroot "$ROOTFS" /bin/bash -e "/tmp/scripts/$1"
  }

  _phase  0 "00 · Consolidated package install"    chroot "$ROOTFS" /bin/bash -e /tmp/scripts/00-install-all-packages.sh
  _phase  1 "01 · Base system + desktop"           chroot_run 01-install-base.sh
  _phase  2 "02 · SDR drivers + conda env"         chroot_run 02-install-sdr.sh
  _phase  3 "03 · Core network (srsRAN/Open5GS)"   chroot_run 03-install-core-network.sh
  _phase  4 "04 · Security tools"                  chroot_run 04-install-tools.sh
  _phase  5 "06 · UE analysis + baseband"          chroot_run 06-install-ue-analysis.sh
  _phase  6 "05 · Desktop customization"           chroot_run 05-desktop-customization.sh
  _phase  7 "07 · Calamares installer"             chroot_run 07-install-installer.sh
  _phase  8 "08 · System optimization"             chroot_run 08-system-optimization.sh
  _phase  9 "09 · 5Ghoul helpers"                  chroot_run 09-install-5ghoul.sh
  _phase 10 "10 · Advanced telecom tools"          chroot_run 10-install-telecom-advanced.sh
  _phase 11 "11 · Device flash tools"              chroot_run 11-install-device-tools.sh

  # Remove chroot service suppression
  rm -f "$ROOTFS/usr/sbin/policy-rc.d" "$ROOTFS/usr/local/sbin/udevadm"
  chroot "$ROOTFS" dpkg-divert --local --rename --remove /usr/bin/udevadm 2>/dev/null || true

  # Cleanup inside chroot to reduce squashfs size
  echo ""
  echo "--> Cleaning up chroot..."
  chroot "$ROOTFS" /bin/bash -e << 'CLEANUP'
export DEBIAN_FRONTEND=noninteractive
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /root/.cache/pip /home/telcosec/.cache/pip
if [ -x /opt/telcosec/miniconda/bin/conda ]; then
  /opt/telcosec/miniconda/bin/conda clean -afy || true
fi
find /opt/telcosec/src -name '.git'       -type d -exec rm -rf {} + 2>/dev/null || true
find /opt/telcosec     -maxdepth 2 -name '.git' -type d -exec rm -rf {} + 2>/dev/null || true
find /opt/telcosec/src -name '*.o'        -delete 2>/dev/null || true
find /opt/telcosec/src -name 'CMakeFiles' -type d -exec rm -rf {} + 2>/dev/null || true
find /usr/share/doc -mindepth 1 -maxdepth 1 ! -name 'telcosec' -exec rm -rf {} +
rm -rf /usr/share/man/*
find /var/log -type f \( -name '*.log' -o -name '*.gz' \) -delete 2>/dev/null || true
rm -rf /tmp/scripts /tmp/calamares-config /tmp/docs
rm -rf /tmp/udev /tmp/security /tmp/menu /tmp/wireshark /tmp/boot
rm -f  /tmp/.packages-installed
rm -rf /tmp/*
CLEANUP
fi

# ─── Unmount before packing ───────────────────────────────────────────────────
cleanup
trap - EXIT

# ─── Squashfs ─────────────────────────────────────────────────────────────────
echo "--> Packing filesystem into squashfs (zstd-15)..."
mkdir -p "$WORKDIR/image/casper"
mksquashfs "$ROOTFS" "$WORKDIR/image/casper/filesystem.squashfs" \
  -comp zstd -Xcompression-level 15 \
  -b 1M \
  -processors "$(nproc)" \
  -no-exports \
  -noappend

# filesystem.size required by casper/live-boot for install size estimation
printf '%s' "$(du -sx --block-size=1 "$ROOTFS" | cut -f1)" \
  > "$WORKDIR/image/casper/filesystem.size"

# ─── Kernel + initrd ──────────────────────────────────────────────────────────
echo "--> Copying kernel and initrd..."
vmlinuz=$(find "$ROOTFS/boot/" -name "vmlinuz-*"   -type f | sort -V | tail -1)
initrd=$(find  "$ROOTFS/boot/" -name "initrd.img-*" -type f | sort -V | tail -1)
if [ -z "$vmlinuz" ] || [ -z "$initrd" ]; then
  echo "ERROR: kernel or initrd not found in $ROOTFS/boot/"
  exit 1
fi
cp "$vmlinuz" "$WORKDIR/image/casper/vmlinuz"
cp "$initrd"  "$WORKDIR/image/casper/initrd"

# ─── GRUB config ──────────────────────────────────────────────────────────────
echo "--> Generating GRUB boot menu..."
mkdir -p "$WORKDIR/image/boot/grub"
cat > "$WORKDIR/image/boot/grub/grub.cfg" << 'GRUB'
set default=0
set timeout=10

insmod all_video
insmod font
if loadfont /boot/grub/fonts/unicode.pf2 ; then
  set gfxmode=auto
  insmod gfxterm
  terminal_output gfxterm
fi

menuentry "Try TelcoSec-Chisel (Live)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=telcosec user-fullname="TelcoSec Researcher" hostname=telcosec-chisel quiet splash ---
    initrd /casper/initrd
}

menuentry "Install TelcoSec-Chisel" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=telcosec user-fullname="TelcoSec Researcher" hostname=telcosec-chisel quiet splash systemd.run=/etc/skel/Desktop/install-telcosec.desktop ---
    initrd /casper/initrd
}

menuentry "Try TelcoSec-Chisel (Safe Graphics)" {
    set gfxpayload=keep
    linux /casper/vmlinuz boot=casper username=telcosec user-fullname="TelcoSec Researcher" hostname=telcosec-chisel nomodeset quiet splash ---
    initrd /casper/initrd
}
GRUB

# ─── Build ISO ────────────────────────────────────────────────────────────────
echo "--> Building ISO with grub-mkrescue..."
grub-mkrescue -o "$IMAGE_NAME" "$WORKDIR/image/" -- -iso-level 3

# ─── Summary ──────────────────────────────────────────────────────────────────
ELAPSED=$(( $(date +%s) - BUILD_START ))
ISO_SIZE=$(du -sh "$IMAGE_NAME" | cut -f1)
printf '\n╔══════════════════════════════════════════════════════╗\n'
printf '║  %-52s║\n' "Build complete: $IMAGE_NAME"
printf '║  %-52s║\n' "ISO size:       $ISO_SIZE"
printf '║  %-52s║\n' "Total time:     $(( ELAPSED/60 ))m$(( ELAPSED%60 ))s"
printf '╚══════════════════════════════════════════════════════╝\n'
