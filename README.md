# TelcoSec-Chisel

**TelcoSec-Chisel** is a comprehensive, open-source Linux distribution tailored specifically for telecommunications security researchers, baseband analysts, and radio frequency penetration testers. Built on top of Ubuntu 24.04 LTS (Noble Numbat) with a lightweight XFCE desktop environment, TelcoSec-Chisel delivers out-of-the-box support for Software Defined Radio (SDR) hardware, baseband firmware emulation, and SIM card auditing.

---

## 🚀 Key Domains & Pre-Loaded Tools

TelcoSec-Chisel organizes security auditing capabilities into dedicated submenus within the application manager:

### 1. 📡 Software Defined Radio (SDR)
Radio hardware drivers are sandboxed inside a dedicated Conda virtual environment to ensure library isolation and avoid interference with system-wide Python dependencies.
*   **Drivers (Source-Compiled)**: UHD (USRP), HackRF, BladeRF, LimeSDR, and RTL-SDR.
*   **Abstraction Layer**: SoapySDR compiled from source.
*   **DSP Framework**: GNU Radio 3.10 and GQRX spectrum analyzer.
*   **GSM Auditing & Calibration**: `gr-gsm` tools (`grgsm_livemon`, `grgsm_scanner`) for air-interface sniffing and decoding, and `kalibrate-rtl` (`kal`) for RTL-SDR frequency offset calibration against GSM base stations.

### 2. 📱 Baseband Emulation & UE Analysis
Tools for auditing proprietary baseband microcode and analyzing diagnostic logs from User Equipment (UE):
*   **FirmWire**: An open-source baseband emulation and fuzzing platform supporting Samsung Shannon and MediaTek MTK baseband images.
*   **MobileInsight**: A runtime protocol analyzer to capture and parse signaling messages directly from Qualcomm and MediaTek diagnostic interfaces.
*   **QCSuper**: Qualcomm diagnostic protocol logger for capturing air-interface packets directly to PCAP files.
*   **MTKClient**: BROM bypass, partitioning, flashing, and dumping tool for MediaTek chipsets.
*   **Balong-Flash & Balongtool**: Huawei Balong modem flasher and firmware modifier compiled from source.

### 3. 💳 SIM Card Auditing (SIMtrace)
Dedicated smartcard interface inspection toolchain:
*   **Osmocom SIMtrace 2**: Host utilities (`simtrace2-sniff`, `simtrace2-rext`) and PCSC daemon interfaces to capture ISO 7816 communication between modems and SIM cards.
*   **Osmocom pySim**: An interactive smartcard shell (`pySim-shell`) to read, edit, and configure SIM/USIM card profiles.
*   **Smartcard Stack**: Complete PC/SC daemon (`pcscd`) and smartcard readers suite.

### 4. 🔗 Radio Access Network (RAN) & Core Signaling
*   **srsRAN**: 4G and 5G software radio RAN simulator for executing local virtual cells.
*   **Wireshark & TShark**: Configured with custom column profiles displaying GSMTAP channels, 5G NAS message types, GTP TEIDs, MAP MSISDN, MAP Opcode, and Diameter Command Codes natively in the packet pane.
*   **SIPVicious**: SIP auditing scanner for VoIP and IMS signaling infrastructure.
*   **sctpscan**: Cloned, compiled, and installed the SCTP port scanner to discover SIGTRAN/M3UA, Diameter, and S1AP/NGAP endpoints.
*   **SigPloit**: Cloned the SS7/Diameter/GTP signaling exploitation framework to audit telecom networks.
*   **Diafuzzer**: Cloned Orange's Diameter protocol fuzzer to stress test core S6a, Gx, and Gy interfaces.
*   **Scapy**: Integrated with built-in modules for crafting raw M3UA, TCAP, MAP, and Diameter signaling packets.

---

## ⚡ OS Customizations & Optimizations

*   **Non-Root Hardware Access**: Custom udev rules (`/etc/udev/rules.d/50-telcosec-hw.rules`) grant users in the `plugdev` group direct access to HackRF, USRP, LimeSDR, and SIMtrace 2 USB interfaces.
*   **Real-time Scheduling**: Configured PAM security limits (`/etc/security/limits.d/99-realtime.conf`) and a `realtime` system group, enabling threads to request low-latency scheduling (priority 99) and lock physical memory to prevent RF sample drops.
*   **SCTP Stack Tuning**: Pre-loads the `sctp` kernel module at boot and configures `/etc/sysctl.d/99-sctp-tuning.conf` to optimize socket memory buffers, increase queue capacities, reduce RTO floor limits to 200ms, and lower retransmission bounds to prevent scanner hangs.
*   **Pre-configured Firefox**: Preloaded with a custom-styled local documentation start page (`/usr/share/doc/telcosec/index.html`) explaining how to run baseband and signaling utilities. The bookmarks toolbar includes direct links to official TelcoSec properties.
*   **Calamares Installer**: Booting the Live ISO loads a fully functional live environment, and includes a double-clickable desktop shortcut to install the OS permanently to disk.

---

## 💿 Live Boot Credentials

When booting the Live ISO, the system is configured to autologin. If prompted, the default live user credentials are:
*   **Username**: `telcosec`
*   **Password**: `telcosec`

---

## 🛠️ Building the Live ISO (Developers)

Developers can compile the bootable ISO file locally on an Ubuntu/Debian host (or inside a WSL2 container):

### Prerequisites
Install the required builder packages on the host machine:
```bash
sudo apt-get update
sudo apt-get install -y debootstrap squashfs-tools grub-pc-bin grub-efi-amd64-bin xorriso mtools
```

### Build Command
Compile the live image:
```bash
sudo ./build-iso.sh
```
This builds the rootfs, compiles the SDR drivers, installs the target baseband utilities, and outputs `telcosec-chisel-live.iso`.

---

## 🌐 Community & Resources

Join the TelcoSec ecosystem for updates and documentation:
*   **Community Hub**: [community.telcosec.net](https://community.telcosec.net/)
*   **Main Website**: [www.telcosec.net](https://www.telcosec.net/)
*   **Academy**: [academy.telcosec.net](https://academy.telcosec.net/)
*   **Research Blog**: [blog.telcosec.net](https://blog.telcosec.net/)
*   **Official Discord**: [Discord Link](https://discord.gg/RykzXTQFXF)