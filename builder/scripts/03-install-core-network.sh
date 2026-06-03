#!/bin/bash
set -e

echo "=== Installing Core Network Stack (Open5GS + srsRAN + OAI build deps) ==="

# Open5GS PPA (5G SA core: AMF, SMF, UPF, NRF, AUSF, UDM, PCF, NSSF, BSF, UDR)
sudo add-apt-repository -y ppa:open5gs/latest
sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  open5gs \
  srsran

# OpenAirInterface 5G NR build dependencies
# (OAI is the gNB used by 5Ghoul; srsRAN stays for standalone use cases)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
  libbladerf2 libbladerf-dev bladerf

# Promote clang-15 as the default clang/clang++ (OAI build requires it)
sudo update-alternatives --install /usr/bin/clang   clang   /usr/bin/clang-15   100 || true
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-15 100 || true
sudo update-alternatives --install /usr/bin/lld     lld     /usr/bin/lld-15     100 || true

# IP forwarding required by Open5GS UPF for UE internet routing
cat << 'EOF' | sudo tee /etc/sysctl.d/99-open5gs.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF

# Disable all Open5GS NFs from auto-starting; they are started manually for testing
for svc in open5gs-amfd open5gs-smfd open5gs-upfd open5gs-nrfd \
           open5gs-ausfd open5gs-udmd open5gs-pcfd open5gs-nssfd \
           open5gs-bsfd open5gs-udrd; do
  sudo systemctl disable "$svc" 2>/dev/null || true
done

# Configure Open5GS for 5Ghoul test PLMN (MCC 001, MNC 01)
# 5Ghoul uses a programmable SIM with IMSI prefix 00101 by default
if [ -d /etc/open5gs ]; then
  # Patch every YAML file that references the default PLMN
  sudo find /etc/open5gs -name "*.yaml" -exec \
    sed -i \
      -e 's/mcc: 999/mcc: 001/g' \
      -e 's/mnc: 70/mnc: 01/g' \
      -e 's/mcc: 901/mcc: 001/g' \
      -e 's/mnc: 70/mnc: 01/g' \
    {} \; || true
  echo "Open5GS PLMN patched to MCC=001, MNC=01"
fi

echo "=== Core network stack installed ==="
