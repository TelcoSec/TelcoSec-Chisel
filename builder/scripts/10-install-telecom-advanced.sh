#!/bin/bash
set -e

echo "=== Installing Advanced Telecom Tools ==="

TELCOSEC_OPT=/opt/telcosec
mkdir -p "$TELCOSEC_OPT"

# Test PLMN constants (ITU-T standard test network)
MCC=001
MNC=01

# ─── Global PLMN config ──────────────────────────────────────────────────────
mkdir -p /etc/telcosec
cat > /etc/telcosec/plmn.conf << EOF
# TelcoSec test PLMN configuration (ITU-T test network 001-01)
MCC=${MCC}
MNC=${MNC}
PLMN=${MCC}${MNC}
TAC=0x0001
EOF

# ─── A. UERANSIM (5G UE/gNB simulator) ─────────────────────────────────────
echo "  Installing UERANSIM..."
git clone --depth 1 https://github.com/aligungr/UERANSIM "${TELCOSEC_OPT}/ueransim" || \
  (cd "${TELCOSEC_OPT}/ueransim" && git pull) || true

if [ -d "${TELCOSEC_OPT}/ueransim" ]; then
  cd "${TELCOSEC_OPT}/ueransim"
  cmake -DCMAKE_BUILD_TYPE=Release . 2>&1 | tail -3
  make -j"$(nproc)" 2>&1 | tail -5
  ln -sf "${TELCOSEC_OPT}/ueransim/build/nr-gnb" /usr/local/bin/nr-gnb
  ln -sf "${TELCOSEC_OPT}/ueransim/build/nr-ue"  /usr/local/bin/nr-ue
  ln -sf "${TELCOSEC_OPT}/ueransim/build/nr-cli" /usr/local/bin/nr-cli

  # Deploy test PLMN config templates
  mkdir -p /etc/telcosec/ueransim
  cp config/open5gs-gnb.yaml /etc/telcosec/ueransim/gnb.yaml   2>/dev/null || true
  cp config/open5gs-ue.yaml  /etc/telcosec/ueransim/ue.yaml    2>/dev/null || true
  # Patch MCC/MNC into configs
  sed -i "s/mcc: '999'/mcc: '${MCC}'/g; s/mcc: 999/mcc: ${MCC}/g" \
    /etc/telcosec/ueransim/*.yaml 2>/dev/null || true
  sed -i "s/mnc: '70'/mnc: '${MNC}'/g;  s/mnc: 70/mnc: ${MNC}/g" \
    /etc/telcosec/ueransim/*.yaml 2>/dev/null || true
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/ueransim" /etc/telcosec/ueransim
  cd /
fi

# ─── B. SCAT (Diag protocol / Samsung/Qualcomm log decoder) ─────────────────
echo "  Installing SCAT..."
pip3 install scat --break-system-packages 2>/dev/null || \
  git clone --depth 1 https://github.com/fgsect/scat "${TELCOSEC_OPT}/scat" || true
if [ -d "${TELCOSEC_OPT}/scat" ]; then
  pip3 install -e "${TELCOSEC_OPT}/scat" --break-system-packages 2>/dev/null || true
fi

# ─── C. Osmocom tools (GSM/2G BTS stack) ────────────────────────────────────
echo "  Installing Osmocom tools..."
# Repo already added in 00-install-all-packages.sh
apt-get update -qq 2>/dev/null || true
apt-get install -y --no-install-recommends \
  osmo-bts-virtual osmo-bts-trx \
  osmo-trx-common \
  osmo-hlr osmo-msc osmo-bsc osmo-sgsn \
  osmocom-utils \
  2>/dev/null || echo "  WARNING: Some Osmocom packages unavailable — check Osmocom APT repo"

# ─── D. Kalibrate-GSM (GSM frequency calibration) ──────────────────────────
echo "  Installing Kalibrate-GSM..."
git clone --depth 1 https://github.com/steve-m/kalibrate-gsm "${TELCOSEC_OPT}/kalibrate-gsm" || \
  (cd "${TELCOSEC_OPT}/kalibrate-gsm" && git pull) || true
if [ -d "${TELCOSEC_OPT}/kalibrate-gsm" ]; then
  cd "${TELCOSEC_OPT}/kalibrate-gsm"
  ./bootstrap.sh 2>/dev/null || autoreconf -fi
  ./configure && make -j"$(nproc)"
  cp src/kal /usr/local/bin/kal-gsm 2>/dev/null || true
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/kalibrate-gsm"
  cd /
fi

# ─── E. Modmobmap (cell mapping via AT commands) ────────────────────────────
echo "  Installing Modmobmap..."
git clone --depth 1 https://github.com/S3cur1ty-fr/modmobmap "${TELCOSEC_OPT}/modmobmap" || \
  (cd "${TELCOSEC_OPT}/modmobmap" && git pull) || true
if [ -d "${TELCOSEC_OPT}/modmobmap" ]; then
  pip3 install -r "${TELCOSEC_OPT}/modmobmap/requirements.txt" \
    --break-system-packages 2>/dev/null || true
  cat > /usr/local/bin/modmobmap << 'SCRIPT'
#!/bin/bash
python3 /opt/telcosec/modmobmap/modmobmap.py "$@"
SCRIPT
  chmod +x /usr/local/bin/modmobmap
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/modmobmap"
fi

# ─── F. SIMTester (Java SIM card security testing) ──────────────────────────
echo "  Installing SIMTester..."
git clone --depth 1 https://github.com/srlabs/SIMtester "${TELCOSEC_OPT}/simtester" || \
  (cd "${TELCOSEC_OPT}/simtester" && git pull) || true
if [ -d "${TELCOSEC_OPT}/simtester" ] && command -v mvn &>/dev/null; then
  cd "${TELCOSEC_OPT}/simtester"
  mvn package -DskipTests -q 2>&1 | tail -5 || true
  JAR=$(find . -name "SIMtester*.jar" -not -path "*/original*" 2>/dev/null | head -1)
  if [ -n "$JAR" ]; then
    cat > /usr/local/bin/simtester << EOF
#!/bin/bash
exec java -jar ${TELCOSEC_OPT}/simtester/${JAR} "\$@"
EOF
    chmod +x /usr/local/bin/simtester
  fi
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/simtester"
  cd /
fi

# ─── G. YateBTS + Yate (GSM/UMTS BTS with BladeRF support) ─────────────────
echo "  Installing YateBTS (deferred compile — providing installer helper)..."
# YateBTS is a large autotools build. Like 5Ghoul, compile at first run.
git clone --depth 1 https://github.com/yatebts/yatebts "${TELCOSEC_OPT}/yatebts" 2>/dev/null || true

cat > /usr/local/bin/yatebts-install << 'SCRIPT'
#!/bin/bash
set -e
echo "=== YateBTS Full Install (BladeRF optimized) ==="
cd /opt/telcosec/yatebts

# Install Yate first
if [ ! -d /opt/telcosec/yate ]; then
  apt-get install -y yate yate-dev 2>/dev/null || \
    git clone --depth 1 https://github.com/YateTEL/yate /opt/telcosec/yate
  if [ -d /opt/telcosec/yate ] && [ ! -f /usr/local/bin/yate ]; then
    cd /opt/telcosec/yate
    ./autogen.sh && ./configure && make -j$(nproc) && make install
    cd -
  fi
fi

# Build YateBTS against Yate
cd /opt/telcosec/yatebts
./autogen.sh && ./configure && make -j$(nproc) && make install

# BladeRF config
mkdir -p /etc/yate
cat > /etc/yate/ybladerf.conf << EOF
[general]
; BladeRF A4 configuration for YateBTS
rx_latency=3
tx_latency=3
threads=2
loopback=none
EOF
echo "YateBTS installed. Start with: sudo yate -s -l /var/log/yate.log"
SCRIPT
chmod +x /usr/local/bin/yatebts-install
chown -R telcosec:telcosec "${TELCOSEC_OPT}/yatebts" 2>/dev/null || true

# ─── H. OpenBTS (GSM BTS, deferred compile) ─────────────────────────────────
echo "  Installing OpenBTS helper..."
git clone --depth 1 https://github.com/RangeNetworks/openbts "${TELCOSEC_OPT}/openbts" 2>/dev/null || true

cat > /usr/local/bin/openbts-install << 'SCRIPT'
#!/bin/bash
set -e
echo "=== OpenBTS Install ==="
cd /opt/telcosec/openbts
# OpenBTS requires libosip2, libexosip2, liba53
apt-get install -y libosip2-dev libexosip2-dev
./autogen.sh && ./configure && make -j$(nproc) && make install
echo "OpenBTS installed. Configure: /etc/OpenBTS/OpenBTS.conf"
SCRIPT
chmod +x /usr/local/bin/openbts-install
chown -R telcosec:telcosec "${TELCOSEC_OPT}/openbts" 2>/dev/null || true

# ─── I. srsGUI (visualization for srsRAN metrics) ───────────────────────────
echo "  Installing srsGUI..."
git clone --depth 1 https://github.com/srsran/srsgui "${TELCOSEC_OPT}/srsgui" 2>/dev/null || \
  (cd "${TELCOSEC_OPT}/srsgui" && git pull) || true
if [ -d "${TELCOSEC_OPT}/srsgui" ]; then
  cd "${TELCOSEC_OPT}/srsgui"
  mkdir -p build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -3
  make -j"$(nproc)" 2>&1 | tail -5 || true
  [ -f srsgui ] && ln -sf "${TELCOSEC_OPT}/srsgui/build/srsgui" /usr/local/bin/srsgui || true
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/srsgui"
  cd /
fi

# ─── J. LTE-CellScanner ──────────────────────────────────────────────────────
echo "  Installing LTE-CellScanner..."
git clone --depth 1 https://github.com/Evrytania/LTE-Cell-Scanner \
  "${TELCOSEC_OPT}/lte-cellscanner" 2>/dev/null || \
  (cd "${TELCOSEC_OPT}/lte-cellscanner" && git pull) || true
if [ -d "${TELCOSEC_OPT}/lte-cellscanner" ]; then
  cd "${TELCOSEC_OPT}/lte-cellscanner"
  mkdir -p build && cd build
  cmake .. 2>&1 | tail -3
  make -j"$(nproc)" 2>&1 | tail -5 || true
  [ -f src/CellSearch ] && ln -sf "${TELCOSEC_OPT}/lte-cellscanner/build/src/CellSearch" \
    /usr/local/bin/LTE-CellSearch || true
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/lte-cellscanner"
  cd /
fi

# ─── K. LTESniffer ───────────────────────────────────────────────────────────
echo "  Installing LTESniffer..."
git clone --depth 1 https://github.com/SysSec-KAIST/LTESniffer "${TELCOSEC_OPT}/ltesniffer" \
  2>/dev/null || (cd "${TELCOSEC_OPT}/ltesniffer" && git pull) || true
if [ -d "${TELCOSEC_OPT}/ltesniffer" ]; then
  cd "${TELCOSEC_OPT}/ltesniffer"
  mkdir -p build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=Release 2>&1 | tail -3
  make -j"$(nproc)" 2>&1 | tail -5 || true
  SNIFFER_BIN=$(find . -name "ltesniffer" -type f 2>/dev/null | head -1)
  [ -n "$SNIFFER_BIN" ] && \
    ln -sf "${TELCOSEC_OPT}/ltesniffer/build/${SNIFFER_BIN}" /usr/local/bin/ltesniffer || true
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/ltesniffer"
  cd /
fi

# ─── L. TetraEar / gr-tetra (TETRA protocol receiver) ───────────────────────
echo "  Installing gr-tetra (TetraEar)..."
git clone --depth 1 https://github.com/ninjachris81/gr-tetra "${TELCOSEC_OPT}/gr-tetra" \
  2>/dev/null || (cd "${TELCOSEC_OPT}/gr-tetra" && git pull) || true
if [ -d "${TELCOSEC_OPT}/gr-tetra" ]; then
  cd "${TELCOSEC_OPT}/gr-tetra"
  mkdir -p build && cd build
  cmake .. -DCMAKE_INSTALL_PREFIX=/usr 2>&1 | tail -3
  make -j"$(nproc)" 2>&1 | tail -5 && make install 2>/dev/null || true
  ldconfig
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/gr-tetra"
  cd /
fi

# ─── M. 5G GTP kernel module (gtp5g) ─────────────────────────────────────────
echo "  Installing gtp5g kernel module..."
git clone --depth 1 https://github.com/free5gc/gtp5g "${TELCOSEC_OPT}/gtp5g" \
  2>/dev/null || (cd "${TELCOSEC_OPT}/gtp5g" && git pull) || true
if [ -d "${TELCOSEC_OPT}/gtp5g" ]; then
  cd "${TELCOSEC_OPT}/gtp5g"
  make -j"$(nproc)" 2>&1 | tail -5 || true
  cat > /usr/local/bin/gtp5g-load << 'GSCRIPT'
#!/bin/bash
# Build (if needed) and load the 5G GTP kernel module
cd /opt/telcosec/gtp5g
[ -f gtp5g.ko ] || make -j$(nproc)
make install
modprobe gtp5g
echo "gtp5g module loaded: $(lsmod | grep gtp5g)"
GSCRIPT
  chmod +x /usr/local/bin/gtp5g-load
  chown -R telcosec:telcosec "${TELCOSEC_OPT}/gtp5g"
  cd /
fi

# ─── N. GTP Python toolkit ───────────────────────────────────────────────────
echo "  Installing GTP Python tools..."
pip3 install gtplib --break-system-packages 2>/dev/null || true
pip3 install python-messaging --break-system-packages 2>/dev/null || true

# ─── O. OAI UE installer helper ──────────────────────────────────────────────
echo "  Installing OAI-UE helper script..."
cat > /usr/local/bin/oai-install << 'SCRIPT'
#!/bin/bash
set -e
echo "=== OpenAirInterface UE Install ==="
git clone --depth 1 https://gitlab.eurecom.fr/oai/openairinterface5g.git /opt/telcosec/oai
cd /opt/telcosec/oai
source oaienv
./cmake_targets/build_oai.sh -I --ue 2>&1 | tee /tmp/oai-build.log
echo "OAI UE installed. Binaries in targets/bin/"
SCRIPT
chmod +x /usr/local/bin/oai-install

# ─── P. BSS management helper scripts (Nokia/Ericsson/Huawei) ────────────────
echo "  Installing BSS management scripts..."
mkdir -p "${TELCOSEC_OPT}/bss-tools"

cat > /usr/local/bin/nokia-netact-cli << 'SCRIPT'
#!/bin/bash
# Nokia NetAct CLI wrapper (SNMP + SSH)
# Usage: nokia-netact-cli <host> [community]
HOST=${1:-127.0.0.1}; COMMUNITY=${2:-public}
snmpwalk -v2c -c "$COMMUNITY" "$HOST" iso.3.6.1.2.1.1 2>/dev/null || \
  ssh -o StrictHostKeyChecking=no "netact@${HOST}" 2>/dev/null
SCRIPT

cat > /usr/local/bin/ericsson-enm-cli << 'SCRIPT'
#!/bin/bash
# Ericsson ENM CLI wrapper (SSH scripting)
# Usage: ericsson-enm-cli <host> [user]
HOST=${1:-127.0.0.1}; USER=${2:-nmsadm}
ssh -o StrictHostKeyChecking=no "${USER}@${HOST}"
SCRIPT

cat > /usr/local/bin/huawei-u2000-cli << 'SCRIPT'
#!/bin/bash
# Huawei U2000 CLI wrapper (telnet/SSH)
# Usage: huawei-u2000-cli <host> [port]
HOST=${1:-127.0.0.1}; PORT=${2:-22}
ssh -p "$PORT" -o StrictHostKeyChecking=no "mscuser@${HOST}" 2>/dev/null || \
  telnet "$HOST" "$PORT"
SCRIPT

chmod +x /usr/local/bin/nokia-netact-cli \
         /usr/local/bin/ericsson-enm-cli \
         /usr/local/bin/huawei-u2000-cli
chown -R telcosec:telcosec "${TELCOSEC_OPT}/bss-tools"

# ─── Q. Open5GS test PLMN patch ──────────────────────────────────────────────
echo "  Patching Open5GS to use test PLMN ${MCC}/${MNC}..."
for CFG in /etc/open5gs/*.yaml; do
  [ -f "$CFG" ] || continue
  # Replace default PLMNs (901/70 and 999/70) with test PLMN
  sed -i \
    -e "s/mcc: '901'/mcc: '${MCC}'/g" \
    -e "s/mnc: '70'/mnc: '${MNC}'/g"  \
    -e "s/mcc: 901/mcc: ${MCC}/g"     \
    -e "s/mnc: 70/mnc: ${MNC}/g"      \
    "$CFG" 2>/dev/null || true
done

# ─── R. srsRAN test PLMN patch ───────────────────────────────────────────────
echo "  Patching srsRAN config to use test PLMN..."
for CFG in /etc/srsran/*.conf; do
  [ -f "$CFG" ] || continue
  sed -i \
    -e "s/^mcc\s*=.*/mcc = ${MCC}/" \
    -e "s/^mnc\s*=.*/mnc = ${MNC}/" \
    "$CFG" 2>/dev/null || true
done

echo "=== Advanced Telecom Tools installation complete ==="
