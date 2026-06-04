#!/bin/bash
set -e

echo "=== Installing UE Analysis, Baseband & SIMtrace Tools ==="

# Skip apt operations — handled by 00-install-all-packages.sh
if [ ! -f /tmp/.packages-installed ]; then
  echo "WARNING: Running standalone (packages not pre-installed)"
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    pcscd pcsc-tools libpcsclite-dev \
    python3-pyscard python3-pip python3-venv python3-dev \
    libosmocore-dev libmd-dev librocksdb-dev \
    git wget unzip cmake pkg-config build-essential gnupg autoconf automake libtool \
    qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils \
    libglib2.0-dev bison flex libpcap-dev libgcrypt20-dev \
    qtbase5-dev qttools5-dev qtmultimedia5-dev libqt5svg5-dev libc-ares-dev \
    libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-2.0-0 \
    libelf-dev libffi-dev libdwarf-dev libwiretap-dev wireshark-dev python3-pycparser \
    protobuf-compiler protobuf-c-compiler libprotoc-dev libprotobuf-dev libprotobuf-c-dev libjsoncpp-dev \
    gdb-multiarch libcapstone-dev gcc-mipsel-linux-gnu gcc-arm-none-eabi \
    scons g++ make dfu-util
fi

# Create tools root directory
sudo mkdir -p /opt/telcosec
sudo chown -R telcosec:telcosec /opt/telcosec

# ─── Clone all repos in parallel ────────────────────────────────────────────
echo "Cloning all UE analysis repositories in parallel..."
cd /opt/telcosec

(git clone --depth 1 https://github.com/FirmWire/FirmWire.git firmwire) &
PID_FIRMWIRE=$!

(git clone --depth 1 https://github.com/mobile-insight/mobileinsight-core.git mobileinsight-core) &
PID_MOBILEINSIGHT=$!

(git clone --depth 1 https://github.com/P1sec/QCSuper.git qcsuper) &
PID_QCSUPER=$!

(git clone --depth 1 https://github.com/forth32/balongflash.git balong-flash) &
PID_BALONG_FLASH=$!

(git clone --depth 1 https://github.com/forth32/balong-nvtool.git balongtool) &
PID_BALONGTOOL=$!

(git clone --depth 1 https://github.com/bkerler/mtkclient.git mtkclient) &
PID_MTK=$!

(git clone --depth 1 https://github.com/osmocom/pysim.git pysim) &
PID_PYSIM=$!

(git clone --depth 1 https://github.com/estkme-group/lpac.git lpac) &
PID_LPAC=$!

(git clone --depth 1 https://github.com/osmocom/simtrace2.git simtrace2) &
PID_SIMTRACE2=$!

# Wait for all clones to complete
echo "Waiting for all git clones to finish..."
wait $PID_FIRMWIRE $PID_MOBILEINSIGHT $PID_QCSUPER $PID_BALONG_FLASH $PID_BALONGTOOL $PID_MTK $PID_PYSIM $PID_LPAC $PID_SIMTRACE2
echo "All repositories cloned successfully."

# Download SIMtrace 2 firmware binaries into the newly cloned directory
echo "Downloading SIMtrace 2 firmware binaries..."
sudo mkdir -p /opt/telcosec/simtrace2/firmware
sudo wget -qO /opt/telcosec/simtrace2/firmware/simtrace-trace-dfu.bin https://ftp.osmocom.org/binaries/simtrace2/firmware/latest/simtrace-trace-dfu-latest.bin || true
sudo wget -qO /opt/telcosec/simtrace2/firmware/simtrace-cardem-dfu.bin https://ftp.osmocom.org/binaries/simtrace2/firmware/latest/simtrace-cardem-dfu-latest.bin || true
sudo chmod 644 /opt/telcosec/simtrace2/firmware/*.bin || true


# ─── Build/install sequentially ─────────────────────────────────────────────

# FirmWire (Samsung Shannon & MediaTek baseband emulation/fuzzing)
echo "Installing FirmWire..."
cd /opt/telcosec/firmwire
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install "Cython<3.0.0" setuptools wheel
./venv/bin/pip install --no-build-isolation rocksdb
./venv/bin/pip install -r requirements.txt
./venv/bin/python setup.py install

# MobileInsight (Qualcomm/MediaTek over-the-air protocol parser)
echo "Installing MobileInsight..."
cd /opt/telcosec/mobileinsight-core
# Patch qt5-default package out of the installer since it is deprecated in newer Ubuntu versions
sed -i 's/qt5-default/qtbase5-dev/g' install-ubuntu.sh
# Run the installation
sudo ./install-ubuntu.sh

# QCSuper (Qualcomm DIAG port traffic capture and Wireshark dissection)
echo "Installing QCSuper..."
cd /opt/telcosec/qcsuper
sudo pip3 install -r requirements.txt --break-system-packages

# Balong-Flash & Balongtool (Huawei Balong modem flashing and engineering)
echo "Compiling Huawei Balong Flashing Tools..."
cd /opt/telcosec/balong-flash
make

cd /opt/telcosec/balongtool
make

# MTKClient (MediaTek BootROM bypass, flashing and partitioning)
echo "Installing MediaTek client (mtkclient)..."
cd /opt/telcosec/mtkclient
sudo pip3 install -r requirements.txt --break-system-packages
python3 setup.py build
sudo python3 setup.py install --break-system-packages

# pySim (SIM/USIM smartcard programming and operations)
echo "Installing Osmocom pySim smartcard utility..."
cd /opt/telcosec/pysim
sudo pip3 install -r requirements.txt --break-system-packages
python3 setup.py build
sudo python3 setup.py install --break-system-packages

# lpac (eSIM Local Profile Assistant tool for profile downloads & management)
echo "Compiling and installing lpac eSIM profile manager..."
cd /opt/telcosec/lpac
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
sudo cp lpac /usr/local/bin/
sudo chmod 755 /usr/local/bin/lpac

# SIMtrace 2 host software (simtrace2-list, simtrace2-sniff, simtrace2-cardem-pcsc)
echo "Compiling and installing SIMtrace 2 host utilities..."
cd /opt/telcosec/simtrace2/host
autoreconf -fi
./configure
make -j$(nproc)
sudo make install
sudo ldconfig

# Clean up build objects and update ownership
cd /opt/telcosec
sudo chown -R telcosec:telcosec /opt/telcosec

echo "=== All Baseband, SIM, and UE Analysis Tools Installed Successfully ==="
