#!/bin/bash
set -e

# =============================================================================
# 00-install-all-packages.sh
# Consolidated APT package installation for TelcoSec-Chisel ISO build.
# Combines all PPAs, third-party repos, and apt-get install calls from
# scripts 01–09 into a single transaction to eliminate redundant index
# downloads and dependency resolution cycles.
# =============================================================================

echo "=== [Phase 0] Consolidated Package Installation ==="

export DEBIAN_FRONTEND=noninteractive

# ─── 1. Add all third-party repositories first ──────────────────────────────

echo "  Adding third-party repositories..."

# Prerequisites for add-apt-repository
apt-get install -y software-properties-common curl wget gnupg

# Firefox PPA (native .deb, not snap)
add-apt-repository -y ppa:mozillateam/ppa
cat << 'EOF' > /etc/apt/preferences.d/99mozillateam
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

# Open5GS PPA (5G SA core network)
add-apt-repository -y ppa:open5gs/latest

# Osmocom latest repo (SIMtrace2, osmo-*)
# Using the official Osmocom key and downloads URL (migrated from opensuse OBS)
wget -qO /tmp/osmocom-key https://obs.osmocom.org/projects/osmocom/public_key
install -Dm644 /tmp/osmocom-key /usr/share/osmocom-keyring/osmocom.asc
rm -f /tmp/osmocom-key
echo "deb [signed-by=/usr/share/osmocom-keyring/osmocom.asc] https://downloads.osmocom.org/packages/osmocom:/latest/xUbuntu_24.04/ ./" \
  > /etc/apt/sources.list.d/osmocom-latest.list

# MongoDB official repository (required by open5gs)
wget -qO /tmp/mongodb-key https://www.mongodb.org/static/pgp/server-8.0.asc
install -Dm644 /tmp/mongodb-key /usr/share/keyrings/mongodb-server-8.0.gpg
rm -f /tmp/mongodb-key
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
  > /etc/apt/sources.list.d/mongodb-org-8.0.list

# ─── 2. Single apt-get update ───────────────────────────────────────────────

echo "  Updating package index (single pass)..."
apt-get update

# ─── 3. System upgrade ──────────────────────────────────────────────────────

echo "  Upgrading base system..."
apt-get upgrade -y

# ─── 4. Consolidated package install ────────────────────────────────────────
# Every package from scripts 01–09, deduplicated and sorted by category.

echo "  Installing all packages (single transaction)..."

apt-get install -y \
  \
  `# === Live boot infrastructure (must precede kernel) ===` \
  casper initramfs-tools \
  \
  `# === Kernel ===` \
  linux-image-generic \
  \
  `# === Desktop environment (01-install-base.sh) ===` \
  xfce4 xfce4-goodies lightdm \
  network-manager-gnome \
  terminator firefox \
  \
  `# === Core system tools (01-install-base.sh) ===` \
  git vim nano htop \
  build-essential cmake pkg-config \
  ufw openssh-server \
  docker.io docker-compose-v2 \
  sudo \
  \
  `# === SDR build deps (02-install-sdr.sh) ===` \
  wget libusb-1.0-0-dev \
  \
  `# === SDR global packages (02-install-sdr.sh) ===` \
  gnuradio gnuradio-dev gqrx-sdr gr-osmosdr gr-gsm \
  librtlsdr-dev librtlsdr0 libfftw3-double3 libfftw3-dev libfftw3-bin \
  autoconf automake libtool \
  \
  `# === Core network stack (03-install-core-network.sh) ===` \
  mongodb-org open5gs \
  cmake ninja-build \
  clang-15 lld-15 lldb-15 \
  libfftw3-dev liblapacke-dev libblas-dev liblapack-dev \
  libsctp-dev lksctp-tools \
  libzmq3-dev libczmq-dev \
  libjson-c-dev \
  libglib2.0-dev \
  libconfig-dev \
  libyaml-cpp-dev \
  libboost-all-dev \
  libssl-dev \
  libmbedtls-dev \
  libnuma-dev \
  libdpdk-dev dpdk dpdk-dev \
  python3-yaml \
  libbladerf2 libbladerf-dev bladerf \
  \
  `# === Security tools (04-install-tools.sh) ===` \
  wireshark tshark \
  nmap \
  libglib2.0-dev libsctp-dev \
  sipsak \
  python3-pip python3-venv \
  wireguard twinkle baresip \
  \
  `# === UE analysis & baseband deps (06-install-ue-analysis.sh) ===` \
  pcscd pcsc-tools libpcsclite-dev \
  python3-pyscard python3-dev \
  libosmocore-dev \
  unzip \
  qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils \
  bison flex libpcap-dev libgcrypt20-dev \
  qtbase5-dev qttools5-dev qtmultimedia5-dev libqt5svg5-dev libc-ares-dev \
  libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-2.0-0 \
  libelf-dev libffi-dev libdwarf-dev libwiretap-dev wireshark-dev python3-pycparser \
  protobuf-compiler protobuf-c-compiler libprotoc-dev libprotobuf-dev libprotobuf-c-dev libjsoncpp-dev \
  gdb-multiarch libcapstone-dev gcc-mipsel-linux-gnu gcc-arm-none-eabi \
  scons g++ make \
  dfu-util \
  `# osmo-simtrace2 — not available as pre-built deb; compiled from source in 06-install-ue-analysis.sh` \
  \
  `# === Calamares installer (07-install-installer.sh) ===` \
  calamares calamares-settings-ubuntu-common \
  qml-module-qtquick-controls qml-module-qtquick-controls2 \
  qml-module-qtquick-dialogs qml-module-qtquick-layouts \
  qml-module-qtquick-window2 \
  upower os-prober \
  \
  `# === 5Ghoul build toolchain (09-install-5ghoul.sh) ===` \
  git-lfs \
  meson ccache \
  python3-numpy python3-pandas python3-scapy \
  nodejs npm \
  libqt5websockets5-dev \
  \
  `# === 5Ghoul fuzzer runtime (09-install-5ghoul.sh) ===` \
  libsnappy-dev \
  liblua5.2-dev \
  libnl-3-dev libnl-route-3-dev libnl-genl-3-dev \
  libnghttp2-dev \
  libnss3-dev \
  libtbb-dev \
  libdouble-conversion-dev \
  libdwarf-dev libelf-dev libiberty-dev \
  libunwind-dev \
  libgflags-dev \
  libevent-dev \
  libfmt-dev \
  libasan6 libubsan1

# ─── 5. Wireshark non-interactive config ─────────────────────────────────────

echo "wireshark-common wireshark-common/install-syscap boolean true" | debconf-set-selections
dpkg-reconfigure wireshark-common

# ─── 6. Clang alternatives (OAI build requires clang-15 as default) ─────────

update-alternatives --install /usr/bin/clang   clang   /usr/bin/clang-15   100 || true
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-15 100 || true
update-alternatives --install /usr/bin/lld     lld     /usr/bin/lld-15     100 || true

# ─── 7. Mark phase 0 complete ───────────────────────────────────────────────

touch /tmp/.packages-installed
echo "=== [Phase 0] All packages installed successfully ==="
