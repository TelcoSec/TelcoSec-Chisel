# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

TelcoSec-Chisel is a **live Linux ISO builder** for telecommunications security research. It produces a bootable Ubuntu 24.04 LTS (XFCE) image pre-loaded with SDR drivers, baseband analysis tools, SIM auditing utilities, and telecom protocol scanners. The output is `telcosec-chisel-live.iso`, which boots directly or installs via the bundled Calamares installer.

Live boot credentials: `telcosec:telcosec`

## Build Command

```bash
sudo ./build-iso.sh
```

Requires a Ubuntu/Debian host with these packages: `debootstrap squashfs-tools grub-pc-bin grub-efi-amd64-bin xorriso mtools`. Needs ~10–20 GB free disk space. Takes 30–60 minutes. Output is `telcosec-chisel-live.iso` in the repo root.

CI/CD runs automatically via `.github/workflows/release.yml` — pushes to `main` trigger a build; tags matching `v*.*.*` also create a GitHub Release with the ISO attached.

## Architecture

The build is orchestrated by `build-iso.sh`, which:
1. Bootstraps a minimal Ubuntu 24.04 chroot via `debootstrap`
2. Mounts virtual filesystems (`proc`, `sys`, `dev`) into the chroot
3. Copies all files from `builder/` into the chroot
4. Executes 8 provisioning scripts **in order** inside the chroot
5. Packs the chroot into a squashfs (XZ), extracts the kernel and initrd, generates a GRUB menu, and runs `grub-mkrescue`

### Provisioning Scripts (`builder/scripts/`)

Scripts run sequentially — each depends on the previous completing cleanly:

| Script | What it installs |
|--------|-----------------|
| `01-install-base.sh` | XFCE desktop, Firefox, build tools, NetworkManager, default `telcosec` user |
| `02-install-sdr.sh` | Conda env with SoapySDR, HackRF, UHD/USRP, GNU Radio, GQRX, gr-gsm, kalibrate-rtl |
| `03-install-core-network.sh` | srsRAN (4G/5G RAN/core simulator) |
| `04-install-tools.sh` | Wireshark, nmap, sctpscan, SIPVicious, SigPloit, Diafuzzer, Scapy |
| `05-desktop-customization.sh` | Firefox policies, wallpaper, MOTD, bash prompt, local docs, desktop shortcuts |
| `06-install-ue-analysis.sh` | FirmWire, MobileInsight, QCSuper, MTKClient, Balong-Flash, pySim, SIMtrace 2 |
| `07-install-installer.sh` | Calamares GUI installer with TelcoSec branding |
| `08-system-optimization.sh` | udev rules, PAM real-time limits, XFCE menu, Wireshark profiles, SCTP tuning, boot theme |

### Supporting Directories (`builder/`)

- `calamares/` — Calamares installer config (`settings.conf`, module configs in `modules/`, branding assets in `branding/telcosec/`)
- `menu/` — XFCE application menu: `telcosec.menu` defines submenus; `applications/` holds 13 `.desktop` launchers; `directories/` holds category definitions
- `udev/50-telcosec-hw.rules` — USB access rules for HackRF, USRP, LimeSDR, RTL-SDR, SIMtrace 2
- `security/99-realtime.conf` — PAM limits for real-time scheduling (required for SDR stability)
- `security/99-sctp-tuning.conf` — Kernel SCTP parameters for SIGTRAN/telecom scanning
- `wireshark/` — Custom preferences profile and Lua dissector plugins
- `boot/grub-theme.conf` — GRUB visual theme
- `docs/index.html` — Local documentation page deployed to `/usr/share/doc/telcosec/`

## Key Constraints

- Scripts run **inside a chroot** — they cannot reference host paths or host-installed tools. Any tool or file needed at runtime must be installed by a script or copied from `builder/`.
- SDR tools live in a **Conda environment** (isolated from system Python) to avoid dependency conflicts with telecom analysis tools.
- Script numbering (`01-` through `08-`) encodes execution order. `build-iso.sh` copies and runs them in this order; do not reorder without reviewing dependencies.
- The Calamares installer is configured as a **live-only** tool; its `.desktop` file is hidden from the standard menu and only appears on the live session desktop.
