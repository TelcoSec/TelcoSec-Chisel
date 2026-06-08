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


# MongoDB official repository (required by open5gs)
mkdir -p /usr/share/keyrings
wget -qO- https://pgp.mongodb.com/server-8.0.asc | gpg --dearmor > /usr/share/keyrings/mongodb-server-8.0.gpg
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
  xfce4 xfce4-goodies lightdm lightdm-gtk-greeter \
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
  librtlsdr-dev libfftw3-double3 libfftw3-dev libfftw3-bin \
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
  libosmocore-dev libmd-dev librocksdb-dev \
  unzip \
  qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils \
  bison flex libpcap-dev libgcrypt20-dev \
  qtbase5-dev qttools5-dev qtmultimedia5-dev libqt5svg5-dev libc-ares-dev \
  libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-2.0-0 \
  libcurl4-openssl-dev \
  libelf-dev libffi-dev libdwarf-dev libwiretap-dev wireshark-dev python3-pycparser \
  protobuf-compiler protobuf-c-compiler libprotoc-dev libprotobuf-dev libprotobuf-c-dev libjsoncpp-dev \
  gdb-multiarch libcapstone-dev gcc-mipsel-linux-gnu gcc-arm-none-eabi \
  scons g++ make \
  dfu-util autoconf-archive \
  libtalloc-dev libgnutls28-dev liburing-dev \
  `# osmo-simtrace2 — not available as pre-built deb; compiled from source in 06-install-ue-analysis.sh` \
  \
  `# === Calamares installer (07-install-installer.sh) ===` \
  calamares \
  qml-module-qtquick-controls qml-module-qtquick-controls2 \
  qml-module-qtquick-dialogs qml-module-qtquick-layouts \
  qml-module-qtquick-window2 \
  upower os-prober python3-jsonschema \
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
if ! getent group wireshark >/dev/null; then
  groupadd -r wireshark
fi

# ─── 6. Clang alternatives (OAI build requires clang-15 as default) ─────────

update-alternatives --install /usr/bin/clang   clang   /usr/bin/clang-15   100 || true
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-15 100 || true
update-alternatives --install /usr/bin/lld     lld     /usr/bin/lld-15     100 || true

# ─── 7. Hand typing-extensions ownership to pip ─────────────────────────────
# Ubuntu 24.04 installs typing-extensions via apt without a pip RECORD file.
# Any subsequent pip install that tries to upgrade it aborts with
# "Cannot uninstall … RECORD file not found". Force-reinstalling it now
# gives pip a proper RECORD file so later installs can upgrade it freely.
pip3 install --break-system-packages --force-reinstall --no-deps \
  typing-extensions || true

# ─── 8. Mark phase 0 complete ───────────────────────────────────────────────

touch /tmp/.packages-installed
echo "=== [Phase 0] All packages installed successfully ==="
