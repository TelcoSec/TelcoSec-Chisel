#!/bin/bash
set -e

echo "=== Installing Security Tools ==="

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  wireshark tshark \
  nmap \
  lksctp-tools \
  sipsak \
  python3-pip python3-venv

# Install SIPVicious
pip3 install sipvicious --break-system-packages

# Give Wireshark dumpcap network capture capabilities for non-root users
echo "wireshark-common wireshark-common/install-syscap boolean true" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common
sudo usermod -a -G wireshark telcosec
