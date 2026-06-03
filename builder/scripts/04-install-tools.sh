#!/bin/bash
set -e

echo "=== Installing Security Tools ==="

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  wireshark tshark \
  nmap \
  lksctp-tools libsctp-dev libglib2.0-dev \
  sipsak \
  python3-pip python3-venv \
  wireguard twinkle baresip

# Install SIPVicious and Scapy
pip3 install sipvicious scapy --break-system-packages

# Compile and Install sctpscan
echo "Compiling and installing sctpscan..."
sudo mkdir -p /opt/telcosec
sudo git clone --depth 1 https://github.com/philpraxis/sctpscan.git /opt/telcosec/sctpscan || true
cd /opt/telcosec/sctpscan
gcc -O2 sctpscan.c -o sctpscan $(pkg-config --cflags --libs glib-2.0)
sudo cp sctpscan /usr/local/bin/
sudo chmod 755 /usr/local/bin/sctpscan
sudo chown -R telcosec:telcosec /opt/telcosec/sctpscan
cd -

# Install SigPloit (SS7/Diameter/GTP Exploitation Framework)
echo "Installing SigPloit..."
sudo git clone --depth 1 https://github.com/SigPloiter/SigPloit.git /opt/telcosec/sigploit || true
sudo chown -R telcosec:telcosec /opt/telcosec/sigploit

# Install Diafuzzer (Orange Diameter Fuzzer)
echo "Installing Diafuzzer..."
sudo git clone --depth 1 https://github.com/Orange-OpenSource/diafuzzer.git /opt/telcosec/diafuzzer || true
if [ -f /opt/telcosec/diafuzzer/requirements.txt ]; then
  pip3 install -r /opt/telcosec/diafuzzer/requirements.txt --break-system-packages || true
fi
sudo chown -R telcosec:telcosec /opt/telcosec/diafuzzer

# Give Wireshark dumpcap network capture capabilities for non-root users
echo "wireshark-common wireshark-common/install-syscap boolean true" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common
sudo usermod -a -G wireshark telcosec

# Install telecom-specific wordlists
echo "Creating dedicated telecom wordlists directory..."
sudo mkdir -p /usr/share/wordlists/telecom

# 1. SIP Usernames Wordlist
cat << 'EOF' | sudo tee /usr/share/wordlists/telecom/sip-usernames.txt
admin
operator
100
101
102
103
104
105
200
201
500
1000
1001
2000
3000
8000
9000
asterisk
phone
test
EOF

# 2. SIP Passwords Wordlist
cat << 'EOF' | sudo tee /usr/share/wordlists/telecom/sip-passwords.txt
1234
12345
123456
0000
1111
password
admin
100
101
1000
2000
pass1234
asterisk
test
EOF

# 3. Default Telecom Device Credentials
cat << 'EOF' | sudo tee /usr/share/wordlists/telecom/telecom-default-credentials.txt
# Format: <vendor/system>:<username>:<password>
asterisk:admin:amp111
freepbx:admin:admin
cisco:cisco:cisco
cisco:admin:admin
huawei:admin:admin
huawei:root:admin
zte:admin:admin
zte:telecomadmin:nE7jA%5m
nokia:admin:admin
nokia:root:root
nokia:usr:pwd
open5gs:admin:open5gs
srsran:admin:srsran
EOF

# 4. Standard Carrier Access Point Names (APN)
cat << 'EOF' | sudo tee /usr/share/wordlists/telecom/apns.txt
internet
wap
mms
ims
lte
hologram
super
broadband
web
vzwinternet
epc.tmobile.com
fast.t-mobile.com
phone
EOF

sudo chmod -R 644 /usr/share/wordlists/telecom/*.txt
