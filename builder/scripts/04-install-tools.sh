#!/bin/bash
set -e

echo "=== Installing Security Tools ==="

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  wireshark tshark \
  nmap \
  lksctp-tools libsctp-dev libglib2.0-dev \
  sipsak \
  python3-pip python3-venv

# Install SIPVicious and Scapy
pip3 install sipvicious scapy --break-system-packages

# Compile and Install sctpscan
echo "Compiling and installing sctpscan..."
sudo mkdir -p /opt/telcosec
sudo git clone https://github.com/philpraxis/sctpscan.git /opt/telcosec/sctpscan || true
cd /opt/telcosec/sctpscan
gcc -O2 sctpscan.c -o sctpscan $(pkg-config --cflags --libs glib-2.0)
sudo cp sctpscan /usr/local/bin/
sudo chmod 755 /usr/local/bin/sctpscan
sudo chown -R telcosec:telcosec /opt/telcosec/sctpscan
cd -

# Install SigPloit (SS7/Diameter/GTP Exploitation Framework)
echo "Installing SigPloit..."
sudo git clone https://github.com/SigPloiter/SigPloit.git /opt/telcosec/sigploit || true
sudo chown -R telcosec:telcosec /opt/telcosec/sigploit

# Install Diafuzzer (Orange Diameter Fuzzer)
echo "Installing Diafuzzer..."
sudo git clone https://github.com/Orange-OpenSource/diafuzzer.git /opt/telcosec/diafuzzer || true
if [ -f /opt/telcosec/diafuzzer/requirements.txt ]; then
  pip3 install -r /opt/telcosec/diafuzzer/requirements.txt --break-system-packages || true
fi
sudo chown -R telcosec:telcosec /opt/telcosec/diafuzzer

# Give Wireshark dumpcap network capture capabilities for non-root users
echo "wireshark-common wireshark-common/install-syscap boolean true" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common
sudo usermod -a -G wireshark telcosec
