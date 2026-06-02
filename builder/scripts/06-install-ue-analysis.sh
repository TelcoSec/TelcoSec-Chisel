#!/bin/bash
set -e

echo "=== Installing UE Analysis, Baseband & SIMtrace Tools ==="

# 1. Install System Dependencies for Baseband, SIM, and firmware analysis
echo "Installing base system dependencies..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  pcscd pcsc-tools libpcsclite-dev \
  python3-pyscard python3-pip python3-venv python3-dev \
  libosmocore-dev \
  git wget unzip cmake pkg-config build-essential gnupg \
  qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils \
  libglib2.0-dev bison flex libpcap-dev libgcrypt20-dev \
  qtbase5-dev qttools5-dev qtmultimedia5-dev libqt5svg5-dev libc-ares-dev \
  libsdl2-mixer-2.0-0 libsdl2-image-2.0-0 libsdl2-2.0-0 \
  libelf-dev libffi-dev libdwarf-dev libwiretap-dev wireshark-dev python3-pycparser \
  protobuf-compiler protobuf-c-compiler libprotoc-dev libprotobuf-dev libprotobuf-c-dev libjsoncpp-dev \
  gdb-multiarch libcapstone-dev gcc-mipsel-linux-gnu gcc-arm-none-eabi \
  scons g++ make

# 2. Osmocom SIMtrace 2 (Host software & PCSC daemon)
echo "Installing Osmocom SIMtrace 2..."
# Adding the Osmocom latest repository for simtrace2 using modern key import
wget -qO - https://download.opensuse.org/repositories/network:/osmocom:/latest/xUbuntu_24.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/osmocom-latest.gpg > /dev/null
echo "deb https://download.opensuse.org/repositories/network:/osmocom:/latest/xUbuntu_24.04/ ./" | sudo tee /etc/apt/sources.list.d/osmocom-latest.list
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y osmo-simtrace2 pcscd-osmo-simtrace2

# Create tools root directory
sudo mkdir -p /opt/telcosec
sudo chown -R telcosec:telcosec /opt/telcosec

# 3. FirmWire (Samsung Shannon & MediaTek baseband emulation/fuzzing)
echo "Installing FirmWire..."
cd /opt/telcosec
git clone https://github.com/FirmWire/FirmWire.git firmwire
cd firmwire
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt
./venv/bin/python setup.py install

# 4. MobileInsight (Qualcomm/MediaTek over-the-air protocol parser)
echo "Installing MobileInsight..."
cd /opt/telcosec
git clone https://github.com/mobile-insight/mobileinsight-core.git mobileinsight-core
cd mobileinsight-core
# Patch qt5-default package out of the installer since it is deprecated in newer Ubuntu versions
sed -i 's/qt5-default/qtbase5-dev/g' install-ubuntu.sh
# Run the installation
sudo ./install-ubuntu.sh

# 5. QCSuper (Qualcomm DIAG port traffic capture and Wireshark dissection)
echo "Installing QCSuper..."
cd /opt/telcosec
git clone https://github.com/P1sec/QCSuper.git qcsuper
cd qcsuper
sudo pip3 install -r requirements.txt --break-system-packages

# 6. Balong-Flash & Balongtool (Huawei Balong modem flashing and engineering)
echo "Compiling Huawei Balong Flashing Tools..."
cd /opt/telcosec
git clone https://github.com/forth32/balong-flash.git balong-flash
cd balong-flash
make

cd /opt/telcosec
git clone https://github.com/forth32/balongtool.git balongtool
cd balongtool
make

# 7. MTKClient (MediaTek BootROM bypass, flashing and partitioning)
echo "Installing MediaTek client (mtkclient)..."
cd /opt/telcosec
git clone https://github.com/bkerler/mtkclient.git mtkclient
cd mtkclient
sudo pip3 install -r requirements.txt --break-system-packages
python3 setup.py build
sudo python3 setup.py install --break-system-packages

# 8. pySim (SIM/USIM smartcard programming and operations)
echo "Installing Osmocom pySim smartcard utility..."
cd /opt/telcosec
git clone https://github.com/osmocom/pysim.git pysim
cd pysim
sudo pip3 install -r requirements.txt --break-system-packages
python3 setup.py build
sudo python3 setup.py install --break-system-packages

# Clean up build objects and update ownership
cd /opt/telcosec
sudo chown -R telcosec:telcosec /opt/telcosec

echo "=== All Baseband, SIM, and UE Analysis Tools Installed Successfully ==="
