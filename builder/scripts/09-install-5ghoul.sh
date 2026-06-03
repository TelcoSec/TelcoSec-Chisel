#!/bin/bash
set -e

echo "=== Installing 5Ghoul 5G NR Attack Framework Dependencies ==="
# 5Ghoul (https://github.com/asset-group/5ghoul-5g-nr-attacks) uses OpenAirInterface
# as the rogue gNB. All system deps are installed here during ISO build; the
# repo clone + compilation is deferred to first-run to keep ISO build time reasonable.
# Required hardware: USRP B210 (or compatible UHD device). No VM support.

# ── Build toolchain ──────────────────────────────────────────────────────────
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git git-lfs \
  cmake ninja-build meson \
  ccache \
  python3-pip python3-dev python3-numpy python3-pandas python3-scapy \
  nodejs npm \
  wireshark-dev \
  libqt5websockets5-dev

# ── 5Ghoul fuzzer runtime deps ───────────────────────────────────────────────
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libglib2.0-dev \
  libsnappy-dev \
  liblua5.2-dev \
  libc-ares-dev \
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
  libpcap-dev \
  libasan6 libubsan1

# ── Python tooling ───────────────────────────────────────────────────────────
sudo pip3 install --break-system-packages \
  colorlog \
  pyzmq \
  pycryptodome \
  construct \
  pyshark || true

# ── Open5GS TUN interface (ogstun) for UPF user-plane traffic ────────────────
cat << 'EOF' | sudo tee /etc/systemd/network/99-ogstun.netdev
[NetDev]
Name=ogstun
Kind=tun
EOF

cat << 'EOF' | sudo tee /etc/systemd/network/99-ogstun.network
[Match]
Name=ogstun

[Network]
Address=10.45.0.1/16
Address=2001:db8:cafe::1/48
EOF

# ── ogstun bring-up + NAT masquerade (runs at boot) ─────────────────────────
cat << 'SVCSCRIPT' | sudo tee /usr/local/bin/5ghoul-setup-net
#!/bin/bash
ip tuntap add name ogstun mode tun 2>/dev/null || true
ip addr add 10.45.0.1/16    dev ogstun 2>/dev/null || true
ip addr add 2001:db8:cafe::1/48 dev ogstun 2>/dev/null || true
ip link set ogstun up

iptables  -t nat -C POSTROUTING -s 10.45.0.0/16          ! -o ogstun -j MASQUERADE 2>/dev/null || \
  iptables  -t nat -A POSTROUTING -s 10.45.0.0/16          ! -o ogstun -j MASQUERADE
ip6tables -t nat -C POSTROUTING -s 2001:db8:cafe::/48     ! -o ogstun -j MASQUERADE 2>/dev/null || \
  ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48    ! -o ogstun -j MASQUERADE

echo "5Ghoul network interfaces ready."
SVCSCRIPT
sudo chmod +x /usr/local/bin/5ghoul-setup-net

cat << 'EOF' | sudo tee /etc/systemd/system/5ghoul-net.service
[Unit]
Description=5Ghoul ogstun Interface and NAT Setup
After=network.target
Before=open5gs-upfd.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/5ghoul-setup-net
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable 5ghoul-net.service || true

# ── Test subscriber helper ────────────────────────────────────────────────────
# Default 5Ghoul credentials: IMSI 001011234567890, K 465B5CE8B199B49FAA5F0A2EE238A6BC
# OPc E8ED289DEBA952E4283B54E88E6183CA  (matches 5Ghoul documentation)
cat << 'EOF' | sudo tee /usr/local/bin/5ghoul-add-subscriber
#!/bin/bash
echo "Adding 5Ghoul test subscriber to Open5GS..."
open5gs-dbctl add 001011234567890 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA \
  || echo "Subscriber already exists or open5gs-dbctl unavailable."
echo "IMSI : 001011234567890"
echo "K    : 465B5CE8B199B49FAA5F0A2EE238A6BC"
echo "OPc  : E8ED289DEBA952E4283B54E88E6183CA"
EOF
sudo chmod +x /usr/local/bin/5ghoul-add-subscriber

# ── First-run installer (clones repo + compiles on live system) ──────────────
cat << 'EOF' | sudo tee /usr/local/bin/5ghoul-install
#!/bin/bash
set -e
INSTALL_DIR="/opt/telcosec/5ghoul"

echo "╔══════════════════════════════════════════════════════╗"
echo "║      5Ghoul 5G NR Attack Framework Installer        ║"
echo "║  https://github.com/asset-group/5ghoul-5g-nr-attacks ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Requirements: USRP B210 connected via USB 3.0 (bare-metal only)"
echo "Build time:   20–60 min depending on CPU"
echo ""

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo 5ghoul-install"
  exit 1
fi

# Clone with shallow submodules to save bandwidth
if [ ! -d "$INSTALL_DIR/.git" ]; then
  echo "[1/4] Cloning 5Ghoul repository..."
  git clone --depth 1 --recurse-submodules --shallow-submodules \
    https://github.com/asset-group/5ghoul-5g-nr-attacks \
    "$INSTALL_DIR"
else
  echo "[1/4] Repository already cloned, updating..."
  git -C "$INSTALL_DIR" pull --recurse-submodules || true
fi

cd "$INSTALL_DIR"

echo "[2/4] Installing framework dependencies..."
bash requirements.sh dev
bash requirements.sh 5g

echo "[3/4] Compiling (this takes a while)..."
bash build.sh all

echo "[4/4] Setting permissions..."
chown -R telcosec:plugdev "$INSTALL_DIR" || true
chmod -R g+rw "$INSTALL_DIR" || true

echo ""
echo "✓ 5Ghoul installed at $INSTALL_DIR"
echo ""
echo "Quick start:"
echo "  1. sudo 5ghoul-add-subscriber      # register test UE in Open5GS"
echo "  2. Start Open5GS NFs via menu      # or: sudo systemctl start open5gs-*"
echo "  3. cd $INSTALL_DIR"
echo "  4. sudo ./build/5g_fuzzer --Attack.Name=NAS_5GS_Fuzz --UE.IMSI=001011234567890"
EOF
sudo chmod +x /usr/local/bin/5ghoul-install

# ── Fuzzer launcher wrapper ───────────────────────────────────────────────────
cat << 'EOF' | sudo tee /usr/local/bin/5ghoul-run
#!/bin/bash
INSTALL_DIR="/opt/telcosec/5ghoul"
FUZZER="$INSTALL_DIR/build/5g_fuzzer"

if [ ! -f "$FUZZER" ]; then
  echo "5Ghoul not yet built. Running installer..."
  exec xterm -fa 'Monospace' -fs 11 -T '5Ghoul Installer' -e "sudo 5ghoul-install; echo; read -rp 'Press Enter to close...'"
fi

cd "$INSTALL_DIR"
exec sudo "$FUZZER" "$@"
EOF
sudo chmod +x /usr/local/bin/5ghoul-run

# ── Open5GS start/stop helpers ───────────────────────────────────────────────
cat << 'EOF' | sudo tee /usr/local/bin/open5gs-start
#!/bin/bash
echo "Starting Open5GS 5G SA core network functions..."
for svc in open5gs-nrfd open5gs-ausfd open5gs-udmd open5gs-udrd \
           open5gs-bsfd open5gs-pcfd open5gs-nssfd open5gs-amfd \
           open5gs-smfd open5gs-upfd; do
  sudo systemctl start "$svc" 2>/dev/null && echo "  started $svc" || echo "  failed  $svc"
done
echo "Done. Check status: systemctl status 'open5gs-*'"
EOF
sudo chmod +x /usr/local/bin/open5gs-start

cat << 'EOF' | sudo tee /usr/local/bin/open5gs-stop
#!/bin/bash
echo "Stopping Open5GS..."
sudo systemctl stop open5gs-amfd open5gs-smfd open5gs-upfd open5gs-nrfd \
  open5gs-ausfd open5gs-udmd open5gs-pcfd open5gs-nssfd open5gs-bsfd open5gs-udrd 2>/dev/null || true
echo "Done."
EOF
sudo chmod +x /usr/local/bin/open5gs-stop

echo "=== 5Ghoul dependencies installed. Run 'sudo 5ghoul-install' to build. ==="
