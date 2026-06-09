<template>
  <div>
    <BootOverlay />
    <div class="sidebar-overlay" :class="{ active: sidebarOpen }" @click="sidebarOpen = false" id="sidebarOverlay"></div>
    <div class="layout-container">
      <AppSidebar :active-section="activeSection" :open="sidebarOpen" @navigate="navigate" @toggle-theme="toggleTheme" />

      <button class="mobile-nav-toggle" id="mobileToggle" @click="sidebarOpen = !sidebarOpen">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="3" y1="12" x2="21" y2="12"></line>
          <line x1="3" y1="6" x2="21" y2="6"></line>
          <line x1="3" y1="18" x2="21" y2="18"></line>
        </svg>
      </button>

      <main class="main-content">

        <!-- SECTION: OVERVIEW -->
        <section id="overview" class="content-section" :class="{ active: activeSection === 'overview' }" v-show="activeSection === 'overview'">
          <div class="section-header" data-label="// Overview :: TelcoSec-Chisel v1.1.0">
            <h1>TelcoSec-Chisel — Telecom Security Linux Distribution</h1>
            <p class="subtitle">Bootable live OS for 5G/4G security research, SDR analysis, and baseband auditing</p>
            <SpectrumCanvas />
          </div>

          <p>
            <strong>TelcoSec-Chisel</strong> is a free, bootable live Linux distribution purpose-built for cellular security researchers, Software Defined Radio (SDR) engineers, and hardware pentesters. Based on <strong>Ubuntu 24.04 LTS (Noble Numbat)</strong> with a low-overhead XFCE desktop, it ships with 25+ pre-configured tools covering SDR drivers, 5G core simulation, baseband emulation, SIM auditing, and telecom protocol fuzzing — ready to use without installation.
          </p>

          <!-- Academy Banner Promotion -->
          <div class="academy-banner">
            <div class="academy-banner-content">
              <span class="academy-badge">RECOMMENDED TRAINING</span>
              <h2>TelcoSec Academy Certification Program</h2>
              <p>Accelerate your career in telecom security. Access interactive sandbox labs, practice 5G Standalone core network hacking, simulate baseband firmware fuzzing, and earn the Certified Telecom Security Practitioner (CTSP) credential.</p>
              <a href="https://app.telcosec.net/" class="academy-btn" target="_blank">Access Live Labs at app.telcosec.net &rarr;</a>
            </div>
            <div class="academy-banner-icon">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
                <path d="M12 8v4"></path>
                <path d="M12 16h.01"></path>
              </svg>
            </div>
          </div>

          <AppCallout type="info" title="Live Boot Credentials">
            When booting the ISO image on bare metal or virtual environments, the system defaults to graphical autologin. If prompted for passwords:
            <br><strong>Username:</strong> <code class="inline-code">telcosec</code>
            <br><strong>Password:</strong> <code class="inline-code">telcosec</code>
          </AppCallout>

          <h2>Key Platform Capabilities</h2>
          <div class="grid-2">
            <div class="card">
              <div class="card-title">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--accent-teal);"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                SDR Sandbox
              </div>
              <p class="card-desc">Radio drivers (UHD, HackRF, BladeRF, LimeSDR) are compiled from source and sandboxed in a dedicated Conda virtual environment, preserving system Python integrity.</p>
            </div>
            <div class="card">
              <div class="card-title">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--accent-teal);"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                Baseband Emulation
              </div>
              <p class="card-desc">Audit baseband firmware binaries using FirmWire. QCSuper parses diagnostic logs directly from active test UE devices connected via Qualcomm DIAG USB.</p>
            </div>
            <div class="card">
              <div class="card-title">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--accent-teal);"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                SIM &amp; eSIM Utilities
              </div>
              <p class="card-desc">Audit SIM interfaces using Osmocom SIMtrace 2 and pySim-shell. Manage profiles on eSIM chips using the lpac Local Profile Assistant (LPA).</p>
            </div>
            <div class="card">
              <div class="card-title">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--accent-teal);"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                Signaling Scanners
              </div>
              <p class="card-desc">Audit SIGTRAN, Diameter, SIP/VoIP, and GTP cores with Diafuzzer, SigPloit, SIPVicious, and custom Wireshark protocol dissecting profiles.</p>
            </div>
          </div>

          <!-- FAQ -->
          <h2>Frequently Asked Questions</h2>
          <div class="faq-list">

            <details class="faq-item">
              <summary class="faq-question">What is TelcoSec-Chisel?</summary>
              <div class="faq-answer">
                TelcoSec-Chisel is a free, bootable live Linux distribution based on Ubuntu 24.04 LTS with an XFCE desktop, purpose-built for telecommunications security research. It includes 25+ pre-configured tools for Software Defined Radio (SDR) analysis, baseband firmware auditing, SIM and eSIM inspection, and 5G/4G core network penetration testing — no installation required.
              </div>
            </details>

            <details class="faq-item">
              <summary class="faq-question">What SDR hardware does TelcoSec-Chisel support?</summary>
              <div class="faq-answer">
                Drivers compiled from source for the Ettus Research <strong>USRP B210</strong>, Great Scott Gadgets <strong>HackRF One</strong>, Nuand <strong>BladeRF 2.0 micro xA4</strong>, <strong>LimeSDR</strong>, and <strong>RTL-SDR</strong> dongles. All SDR drivers and GNU Radio are sandboxed in a Conda environment named <code class="inline-code">telcosec-sdr</code> to prevent system Python conflicts.
              </div>
            </details>

            <details class="faq-item">
              <summary class="faq-question">Can I run TelcoSec-Chisel in a virtual machine?</summary>
              <div class="faq-answer">
                Most analysis and protocol tools work in a VM. However, SDR tools that stream high-bandwidth samples — particularly the <strong>5Ghoul 5G NR fuzzer</strong> — require bare metal installation with native USB 3.0 passthrough for reliable operation. Running inside VirtualBox or VMware will cause USB overrun errors.
              </div>
            </details>

            <details class="faq-item">
              <summary class="faq-question">How do I install 5Ghoul for 5G NR fuzzing?</summary>
              <div class="faq-answer">
                All build dependencies are pre-installed. Run <code class="inline-code">sudo 5ghoul-install</code> for a USRP B210, or <code class="inline-code">sudo 5ghoul-install --radio BLADERF</code> for a BladeRF A4. The installer clones the repository, applies radio patches, and compiles OpenAirInterface. Allow 20–60 minutes for compilation. See the <strong>5Ghoul Fuzzing</strong> guide in this documentation for the full workflow.
              </div>
            </details>

            <details class="faq-item">
              <summary class="faq-question">What telecom protocol tools are included?</summary>
              <div class="faq-answer">
                <strong>Protocol scanners:</strong> sctpscan (SCTP/S1AP/NGAP/Diameter), SIPVicious (SIP/VoIP). <strong>Exploitation:</strong> SigPloit (SS7/Diameter/GTP), Diafuzzer (Diameter). <strong>Packet analysis:</strong> Wireshark with custom GSMTAP, 5G NAS, Diameter, and GTP column profiles; Scapy with M3UA, TCAP, and MAP modules. <strong>Core network:</strong> Open5GS (5G SA), srsRAN (4G/5G RAN simulator).
              </div>
            </details>

            <details class="faq-item">
              <summary class="faq-question">What are the default live boot credentials?</summary>
              <div class="faq-answer">
                Username: <code class="inline-code">telcosec</code> — Password: <code class="inline-code">telcosec</code>. The system is configured for graphical autologin; you will only be prompted if autologin has been disabled.
              </div>
            </details>

          </div>

          <h2>Quick Links</h2>
          <div class="grid-3" style="margin-top: 10px;">
            <a href="https://community.telcosec.net/" class="card highlight-teal" target="_blank">
              <div class="card-title" style="color: var(--accent-teal);">Community Hub</div>
              <p class="card-desc" style="font-size: 0.85rem;">Discuss protocols, SDR designs, and share telemetry audits with other security analysts.</p>
            </a>
            <a href="https://app.telcosec.net/" class="card highlight-teal" target="_blank">
              <div class="card-title" style="color: var(--accent-teal);">Academy</div>
              <p class="card-desc" style="font-size: 0.85rem;">Master telecom penetration testing from basic GSM up to 5G Standalone core exploits.</p>
            </a>
            <a href="https://blog.telcosec.net/" class="card highlight-teal" target="_blank">
              <div class="card-title" style="color: var(--accent-teal);">Research Blog</div>
              <p class="card-desc" style="font-size: 0.85rem;">In-depth writeups on baseband vulnerabilities, IMS fuzzing, and rogue gNB simulations.</p>
            </a>
          </div>
        </section>

        <!-- SECTION: FEATURES / OS OPTIMIZATIONS -->
        <section id="features" class="content-section" :class="{ active: activeSection === 'features' }" v-show="activeSection === 'features'">
          <div class="section-header" data-label="// Kernel &amp; OS Tuning">
            <h2>OS Customizations &amp; Kernel Tuning for Telecom Security</h2>
            <p class="subtitle">Real-time scheduling, SCTP stack tuning, and low-latency USB for SDR and signaling tools</p>
          </div>

          <p>
            Telecom software suites (like srsRAN, OAI, or SigPloit) place extreme demands on kernel timers, socket memory buffers, and transceiver streaming rates. TelcoSec-Chisel applies specific kernel and PAM optimizations by default.
          </p>

          <h3>1. Real-time Scheduling (PAM &amp; Groups)</h3>
          <p>
            Software Defined Radios require consistent scheduling intervals to avoid sample drops (under/overruns). Under standard Linux settings, non-root users cannot request real-time execution priority.
          </p>
          <TerminalBlock title="/etc/security/limits.d/99-realtime.conf" :code="`# Enable real-time scheduling priority up to 99 and unlimited locked memory\n@realtime       -       rtprio          99\n@realtime       -       memlock         unlimited`" />
          <p>
            The default user <code class="inline-code">telcosec</code> belongs to the system <code class="inline-code">realtime</code> group, enabling GNU Radio and srsRAN threads to lock samples into physical RAM and run at scheduling priority 99.
          </p>

          <h3>2. Kernel SCTP Stack Optimizations</h3>
          <p>
            SCTP (Stream Control Transmission Protocol) is the transport layer backbone of telecom networks (SS7/M3UA, Diameter over SCTP, S1AP, and NGAP). Standard OS kernels are optimized for TCP/UDP. TelcoSec-Chisel preloads the kernel SCTP module and tunes socket limits in <code class="inline-code">/etc/sysctl.d/99-sctp-tuning.conf</code>:
          </p>
          <TerminalBlock title="SCTP sysctl parameters" :code="`# Increase buffer limits for telecom signaling\nnet.sctp.sctp_mem = 94500000 915000000 927000000\nnet.sctp.sctp_rmem = 4096 87380 8388608\nnet.sctp.sctp_wmem = 4096 16384 8388608\n\n# Tuning retransmission timeouts (prevent scanner hangs)\nnet.sctp.rto_min = 200\nnet.sctp.rto_max = 800\nnet.sctp.association_max_retrans = 4\nnet.sctp.path_max_retrans = 2`" />

          <h3>3. Low-Latency USB &amp; GRUB Configurations</h3>
          <p>
            To run high-bandwidth 5G NR Rogue Base Stations, USB polling jitter must be eliminated. The system deploys udev rules to turn off autosuspend delay on USRP B210 and HackRF hardware:
          </p>
          <TerminalBlock title="/etc/udev/rules.d/51-usb-latency.rules" :code='`ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2514", ATTR{power/autosuspend_delay_ms}="0"\nACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2514", ATTR{power/control}="on"\nACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1d50", ATTR{power/control}="on"`' />
          <p>
            Additionally, GRUB configs disable CPU mitigations (<code class="inline-code">mitigations=off</code>) and set the clocksource to TSC for stable timing on bare metal installations.
          </p>
        </section>

        <!-- SECTION: TOOLS -->
        <section id="tools" class="content-section" :class="{ active: activeSection === 'tools' }" v-show="activeSection === 'tools'">
          <div class="section-header" data-label="// Tool Catalog :: 25+ Instruments">
            <h2>Tools Directory — 25+ Pre-installed Telecom Security Tools</h2>
            <p class="subtitle">Complete catalog of SDR, baseband, SIM, RAN, and signaling tools pre-installed in TelcoSec-Chisel</p>
          </div>

          <div class="directory-controls">
            <div class="search-wrapper" id="searchWrapper">
              <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
              </svg>
              <input
                ref="searchInput"
                type="text"
                id="toolSearch"
                class="search-input"
                placeholder="Search tools by name, command, or details..."
                v-model="searchQuery"
              >
              <div class="search-shortcut" id="searchShortcut" v-show="!searchQuery">
                <kbd>/</kbd>
              </div>
              <button
                v-show="searchQuery"
                class="search-clear-btn"
                aria-label="Clear Search"
                @click="searchQuery = ''"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </button>
            </div>
            <div class="filter-tags">
              <button
                v-for="f in filters"
                :key="f.id"
                class="filter-btn"
                :class="{ active: activeFilter === f.id }"
                @click="activeFilter = f.id"
              >
                {{ f.label }} ({{ filterCount(f.id) }})
              </button>
            </div>
          </div>

          <div class="grid-2">
            <div v-if="filteredTools.length === 0" style="grid-column:1/-1; text-align:center; padding:40px; color:var(--text-muted);">
              <p>No tools match your query.</p>
            </div>
            <div v-for="tool in filteredTools" :key="tool.name" class="card highlight-teal">
              <div class="card-title">
                {{ tool.name }}
                <span class="tag" :class="tagClass(tool.category)">{{ tagLabel(tool.category) }}</span>
              </div>
              <p class="card-desc" style="margin-bottom:15px;">{{ tool.desc }}</p>
              <div style="font-size:0.8rem;color:var(--text-muted);margin-bottom:6px;">
                <strong>Location:</strong> <code class="inline-code" style="color:var(--text-secondary);">{{ tool.path }}</code>
              </div>
              <TerminalBlock :code="tool.cmd" />
            </div>
          </div>
        </section>

        <!-- SECTION: DRIVERS -->
        <section id="drivers" class="content-section" :class="{ active: activeSection === 'drivers' }" v-show="activeSection === 'drivers'">
          <div class="section-header" data-label="// Hardware :: RF Transceiver Access">
            <h2>SDR Drivers &amp; Hardware Access — USRP, HackRF, BladeRF, LimeSDR, RTL-SDR</h2>
            <p class="subtitle">Non-root USB access for SDR transceivers and smartcard readers via custom udev rules</p>
          </div>

          <p>
            Traditional security environments force you to run RF interfaces as root to access raw USB descriptors. TelcoSec-Chisel utilizes custom udev permissions, allowing members of the standard `plugdev` group to read and write directly to transceivers.
          </p>

          <h3>1. Non-Root Hardware Access Rules</h3>
          <p>
            The file <code class="inline-code">/etc/udev/rules.d/50-telcosec-hw.rules</code> maps USB product and vendor codes, assigning ownership group to `plugdev` and opening permissions:
          </p>
          <TerminalBlock title="udev Vendor / Product Maps" :code='`# RTL-SDR Dongles\nSUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2832", MODE:="0666", GROUP:="plugdev"\n# HackRF One\nATTR{idVendor}=="1d50", ATTR{idProduct}=="6089", SYMLINK+="hackrf-%k", MODE:="660", GROUP:="plugdev"\n# Ettus USRP B-Series\nATTRS{idVendor}=="2514", ATTRS{idProduct}=="0002", MODE:="0660", GROUP:="plugdev"\n# Osmocom SIMtrace 2 sniffer\nATTRS{idVendor}=="1d50", ATTRS{idProduct}=="60e3", MODE:="0660", GROUP:="plugdev"`' />

          <h3>2. Software Defined Radio (SDR) Drivers Sandbox</h3>
          <p>
            GNU Radio and hardware transceiver drivers are isolated in a custom Conda environment named <code class="inline-code">telcosec-sdr</code>. This prevents host apt-package scripts or pip executions from breaking driver configurations.
          </p>
          <p>
            To execute commands that require UHD, HackRF, LimeSDR, or SoapySDR bindings, activate the virtual environment:
          </p>
          <TerminalBlock title="Activate Conda Environment" :code="`# Activate sandbox\nconda activate telcosec-sdr\n\n# Verify SoapySDR driver bindings are visible\nSoapySDRUtil --find`" />

          <h3>3. Smartcard PC/SC Readers (SIM Auditing)</h3>
          <p>
            Auditing physical smartcards requires communicating with USB smartcard adapters. TelcoSec-Chisel preconfigures the standard PC/SC daemon (<code class="inline-code">pcscd</code>). Insert your card reader (e.g. Omnikey, ACS) and run:
          </p>
          <TerminalBlock title="Query Smartcard Readers" :code="`# Check daemon state\nsudo systemctl status pcscd\n\n# List connected card readers and cards\npcsc_scan`" />
        </section>

        <!-- SECTION: FUZZER -->
        <section id="fuzzer" class="content-section" :class="{ active: activeSection === 'fuzzer' }" v-show="activeSection === 'fuzzer'">
          <div class="section-header" data-label="// 5Ghoul :: 5G NR Baseband Fuzzer">
            <h2>5Ghoul — 5G NR Baseband Fuzzer Setup Guide</h2>
            <p class="subtitle">Install, configure, and run the 5Ghoul fuzzer against 5G NR UE modems using USRP B210 or BladeRF A4</p>
          </div>

          <p>
            <strong>5Ghoul</strong> is a 5G NR baseband fuzzer. It uses an OpenAirInterface (OAI) rogue base station implementation to transmit malformed RRC, NAS, and MAC messages over the air, uncovering vulnerabilities in smartphones, baseband modems, and IoT modules.
          </p>

          <AppCallout type="warning" title="Compile Deferred to First Run">
            To avoid inflating the ISO size and build times (compiling OAI libraries takes over 30 minutes), the framework dependencies are pre-installed in the OS, but the cloning and compiling steps are deferred to first execution. Do not run 5Ghoul inside a Virtual Machine; it requires native USB 3.0 throughput to stream RF.
          </AppCallout>

          <h3>Deploying 5Ghoul on your Live System</h3>
          <div class="steps-container">
            <div class="step-item">
              <div class="step-badge">1</div>
              <div class="step-title">Execute the Installer</div>
              <div class="step-content">
                Run the installer helper. Provide the radio backend parameter to target either your <strong>USRP B210</strong> (default) or a <strong>BladeRF micro A4</strong>.
                <TerminalBlock title="Compile for Hardware" :code="`# Option A: Compile for USRP B210\nsudo 5ghoul-install\n\n# Option B: Compile for BladeRF A4 (performs patch translations)\nsudo 5ghoul-install --radio BLADERF`" />
              </div>
            </div>

            <div class="step-item">
              <div class="step-badge">2</div>
              <div class="step-title">Start the Core Network</div>
              <div class="step-content">
                5Ghoul simulates the radio interfaces, but requires an active mobile core database to process cellular attachment. Launch Open5GS services and add the default test credentials to the network subscriber database:
                <TerminalBlock title="Setup 5G Core Subscriber" :code="`# Start local 5G SA core functions\nsudo open5gs-start\n\n# Register test subscriber profile\nsudo 5ghoul-add-subscriber`" />
              </div>
            </div>

            <div class="step-item">
              <div class="step-badge">3</div>
              <div class="step-title">Run the Fuzzer</div>
              <div class="step-content">
                Connect your SDR to a USB 3.0 port on the host, place the test smartphone inside an RF shield box connected via coaxial cable, and boot the fuzzer.
                <TerminalBlock title="Launch Fuzzer Engine" :code="`# Run NAS fuzzer suite\nsudo 5ghoul-run --Attack.Name=NAS_5GS_Fuzz --UE.IMSI=001011234567890`" />
              </div>
            </div>
          </div>
        </section>

        <!-- SECTION: BUILDER -->
        <section id="builder" class="content-section" :class="{ active: activeSection === 'builder' }" v-show="activeSection === 'builder'">
          <div class="section-header" data-label="// ISO Build Pipeline :: Ubuntu 24.04">
            <h2>Developer Guide — Building the TelcoSec-Chisel Live ISO</h2>
            <p class="subtitle">Build the bootable Ubuntu 24.04 ISO from source on any Ubuntu/Debian host or WSL2</p>
          </div>

          <p>
            TelcoSec-Chisel uses an automated bash orchestration build chain to bootstrap, configure, and output bootable XFCE live desktop images.
          </p>

          <h3>1. Setup Compilation Host</h3>
          <p>
            The build environment must be run on a native Ubuntu or Debian host machine (or inside a WSL2 container with systemd enabled). You need approximately 20 GB of free storage.
          </p>
          <TerminalBlock title="Install Host Dependencies" :code="`# Update and install build packages\nsudo apt-get update\nsudo apt-get install -y debootstrap squashfs-tools grub-pc-bin grub-efi-amd64-bin xorriso mtools zstd`" />

          <h3>2. Run the Build Pipeline</h3>
          <p>
            Clone this repository, review configurations inside <code class="inline-code">builder/</code>, and execute the master build script.
          </p>
          <TerminalBlock title="Compile Live ISO" :code="`# Execute compilation\nsudo ./build-iso.sh`" />

          <h3>3. Pipeline Phase Execution Order</h3>
          <p>
            The orchestrator bootstraps a minimal chroot container and runs provisioning scripts sequentially. Do not alter their index prefixes, as each step relies on outputs of the previous scripts:
          </p>
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 0.95rem;">
            <thead>
              <tr style="border-bottom: 2px solid var(--border-color); text-align: left;">
                <th style="padding: 12px; color: #ffffff;">Script File</th>
                <th style="padding: 12px; color: #ffffff;">Provisioning Operation</th>
              </tr>
            </thead>
            <tbody>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">00-install-all-packages.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Pre-downloads all apt packages to speed up provisioning.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">01-install-base.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Installs XFCE, LightDM, Firefox, base compilers, and sets live boot user.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">02-install-sdr.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Creates Conda environment; compiles UHD, HackRF, and BladeRF SDR drivers.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">03-install-core-network.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Compiles and sets up the srsRAN simulation suite.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">04-install-tools.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Deploys Wireshark, SigPloit, Diafuzzer, SIPVicious, Scapy, softphones, and dictionaries.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">05-desktop-customization.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Sets desktop custom wallpapers, icons, Firefox bookmarks toolbar, and start documentation page.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">06-install-ue-analysis.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Deploys FirmWire baseband QEMU environment, QCSuper, and card programming scripts.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">07-install-installer.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Integrates the Calamares installer engine with customized TelcoSec branding graphics.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">08-system-optimization.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Injects the low-latency udev configs, SCTP limits, CPU isolation limits, and CA certificates.</td>
              </tr>
              <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 12px; font-family: monospace; color: var(--accent-teal);">09-install-5ghoul.sh</td>
                <td style="padding: 12px; color: var(--text-secondary);">Deploys the 5Ghoul ogstun virtual network adapters and compilation frameworks.</td>
              </tr>
            </tbody>
          </table>
        </section>

        <!-- SECTION: PROJECTS -->
        <section id="projects" class="content-section" :class="{ active: activeSection === 'projects' }" v-show="activeSection === 'projects'">
          <div class="section-header" data-label="// Research Ecosystem :: Open Source">
            <h2>TelcoSec Open-Source Projects &amp; Research Ecosystem</h2>
            <p class="subtitle">Tools, labs, vulnerability databases, and community resources for telecom security professionals</p>
          </div>

          <p>
            TelcoSec is an open-source research collective developing security auditing platforms, simulation nodes, and vulnerability databases for mobile telecom networks. Explore our core open source projects included in the distribution:
          </p>

          <h3>Core Repositories</h3>
          <div class="grid-2">
            <div class="card highlight-teal">
              <div class="card-title">
                SctpX
                <span class="tag tag-ran">Rust</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                A high-performance, multi-threaded SCTP protocol scanner and interface auditing framework written in Rust. Designed specifically to map cellular core signaling surfaces (SIGTRAN, M3UA, S1AP, NGAP, Diameter) and audit link capacity.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Repository:</strong> <a href="https://github.com/TelcoSec/SctpX" target="_blank">github.com/TelcoSec/SctpX</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                TelcoSec-Chisel
                <span class="tag tag-sys">Shell / Config</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                The official build ecosystem for compiling this custom XFCE Debian/Ubuntu live ISO. Contains baseband configurations, customized system-wide Wireshark columns, real-time udev configs, and kernel tuners.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Repository:</strong> <a href="https://github.com/TelcoSec/TelcoSec-Chisel" target="_blank">github.com/TelcoSec/TelcoSec-Chisel</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                TelcoSec Wordlists
                <span class="tag tag-sim">Data</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Telecom-specific brute-force wordlists containing carrier APN tables, SIP registration credentials, IMSI prefixes, baseband debug mode console commands, and default router panels.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Repository:</strong> <a href="https://github.com/TelcoSec/TelcoSec-Wordlists" target="_blank">github.com/TelcoSec/TelcoSec-Wordlists</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Downstream Security Patches
                <span class="tag tag-ue">Forks</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Optimized downstream forks of critical security tools such as FirmWire (modified QEMU fuzzers), lpac (enhanced eSIM LPA profiles), and QCSuper (Noble Numbat USB descriptor fixes).
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Repositories:</strong> <a href="https://github.com/TelcoSec" target="_blank">github.com/TelcoSec</a>
              </div>
            </div>
          </div>

          <h3 style="margin-top: 40px;">Platforms &amp; Research Ecosystem</h3>
          <div class="grid-2">
            <div class="card highlight-teal">
              <div class="card-title">
                TelcoSec Labs
                <span class="tag tag-ue">Environments</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Open-source network lab topologies, Docker-based test setups (Open5GS, srsRAN, Kamailio), and experimental codebases for protocol testing and fuzzing.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Repository:</strong> <a href="https://github.com/TelcoSec-Labs" target="_blank">github.com/TelcoSec-Labs</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Vulnerability Database (VulnDB)
                <span class="tag tag-sys">Research</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                A curated CVE and hardware vulnerability database tracking baseband memory leaks, IMS signaling bypasses, and air interface flaws in production equipment.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Platform:</strong> <a href="https://vulndb.telcosec.net/" target="_blank">vulndb.telcosec.net</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Telecom Calculators
                <span class="tag tag-sim">Tools</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Web-based engineering calculators for telecom protocols, enabling calculations for ARFCN/EARFCN/NR-ARFCN, IMSI check-digits, diameter AVPs, and network planning.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Platform:</strong> <a href="https://calculators.telcosec.net/" target="_blank">calculators.telcosec.net</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Capture The Flag (CTF) Portal
                <span class="tag tag-ran">Training</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Structured security challenges focusing on mobile networking, SIGTRAN packet analysis, baseband firmware decompilation, and GSM air capture decoding.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Platform:</strong> <a href="https://ctf.telcosec.net/" target="_blank">ctf.telcosec.net</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                3GPP Specification Tracker
                <span class="tag tag-ran">Standards</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                A tracker mapping standards modifications, security releases, and technical reports across releases 15 to 18 of the 3GPP standards body.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Platform:</strong> <a href="https://3gpp.telcosec.net/" target="_blank">3gpp.telcosec.net</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Research Library
                <span class="tag tag-sys">Docs</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                A curated collection of baseband security research papers, RAN exploit walkthroughs, and technical specifications for telecom consultants.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Platform:</strong> <a href="https://library.telcosec.net/" target="_blank">library.telcosec.net</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Portable BTS Blueprints
                <span class="tag tag-ran">Hardware</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Blueprints, hardware bill of materials (BOM), and software setup instructions for deploying portable SDR-based base stations and over-the-air test labs.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Platform:</strong> <a href="https://portable-bts.telcosec.net/" target="_blank">portable-bts.telcosec.net</a>
              </div>
            </div>

            <div class="card highlight-teal">
              <div class="card-title">
                Technical Newsletter (Substack)
                <span class="tag tag-sys">Advisories</span>
              </div>
              <p class="card-desc" style="margin-bottom: 15px;">
                Monthly research notes, telecom security advisories, vulnerability disclosures, and CTF writeups straight to your inbox.
              </p>
              <div style="font-size: 0.85rem; color: var(--text-muted);">
                <strong>Subscribe:</strong> <a href="https://telcosec.substack.com/" target="_blank">telcosec.substack.com</a>
              </div>
            </div>
          </div>

          <h3>Community &amp; Collaboration Channels</h3>
          <div class="grid-3" style="margin-top: 10px;">
            <a href="https://discord.gg/RykzXTQFXF" class="card highlight-teal" target="_blank">
              <div class="card-title" style="color: var(--accent-teal);">Discord Chat</div>
              <p class="card-desc" style="font-size: 0.85rem;">Join telecom security discussions, help threads, and share radio captures in real time.</p>
            </a>
            <a href="https://www.linkedin.com/company/telco-sec" class="card highlight-teal" target="_blank">
              <div class="card-title" style="color: var(--accent-teal);">LinkedIn Updates</div>
              <p class="card-desc" style="font-size: 0.85rem;">Follow the official TelcoSec company page for announcements and event listings.</p>
            </a>
            <a href="https://www.youtube.com/@Telecom-Security" class="card highlight-teal" target="_blank">
              <div class="card-title" style="color: var(--accent-teal);">YouTube Channel</div>
              <p class="card-desc" style="font-size: 0.85rem;">Video tutorials, lab walkthroughs, conference presentations, and hardware reviews.</p>
            </a>
          </div>
        </section>

      </main>
    </div>
  </div>
</template>
<script setup>
import { toolsCatalog } from '~/data/tools.js'

// SEO metadata
useHead({
  title: 'TelcoSec-Chisel — 5G/4G Telecom Security Linux Distribution',
  meta: [
    { name: 'description', content: 'Free bootable Linux OS for 5G and 4G telecom security research. Ships with GNU Radio, FirmWire, srsRAN, Open5GS, SIMtrace 2, and 25+ tools for SDR analysis, baseband auditing, and cellular protocol penetration testing.' },
    { name: 'keywords', content: 'telecom security linux, 5G security research, 4G LTE penetration testing, SDR security, baseband analysis, FirmWire, GNU Radio, srsRAN, Open5GS, SIMtrace, HackRF, USRP, BladeRF, TelcoSec-Chisel' },
    { name: 'author', content: 'TelcoSec' },
    { name: 'robots', content: 'index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1' },
    { name: 'theme-color', content: '#00ffd5' },
    { property: 'og:type', content: 'website' },
    { property: 'og:site_name', content: 'TelcoSec' },
    { property: 'og:url', content: 'https://telcosec.github.io/TelcoSec-Chisel/' },
    { property: 'og:title', content: 'TelcoSec-Chisel — 5G/4G Telecom Security Linux Distribution' },
    { property: 'og:description', content: 'Free bootable Linux OS for 5G and 4G telecom security research. Ships with GNU Radio, FirmWire, srsRAN, Open5GS, SIMtrace 2, and 25+ tools for SDR analysis, baseband auditing, and cellular protocol penetration testing.' },
    { property: 'og:image', content: 'https://raw.githubusercontent.com/TelcoSec/TelcoSec-Chisel/main/assets/repo_cover.png' },
    { property: 'og:image:width', content: '1280' },
    { property: 'og:image:height', content: '640' },
    { property: 'og:image:alt', content: 'TelcoSec-Chisel — Telecom Security Linux Distribution' },
    { property: 'og:locale', content: 'en_US' },
    { name: 'twitter:card', content: 'summary_large_image' },
    { name: 'twitter:site', content: '@TelcoSec' },
    { name: 'twitter:creator', content: '@TelcoSec' },
    { name: 'twitter:url', content: 'https://telcosec.github.io/TelcoSec-Chisel/' },
    { name: 'twitter:title', content: 'TelcoSec-Chisel — 5G/4G Telecom Security Linux Distribution' },
    { name: 'twitter:description', content: 'Free bootable Linux OS for 5G and 4G telecom security research. Ships with GNU Radio, FirmWire, srsRAN, Open5GS, SIMtrace 2, and 25+ tools for SDR analysis, baseband auditing, and cellular protocol penetration testing.' },
    { name: 'twitter:image', content: 'https://raw.githubusercontent.com/TelcoSec/TelcoSec-Chisel/main/assets/repo_cover.png' }
  ],
  link: [
    { rel: 'canonical', href: 'https://telcosec.github.io/TelcoSec-Chisel/' },
    { rel: 'icon', type: 'image/svg+xml', href: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%2300ffd5' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'/%3E%3Cpath d='M12 8v4'/%3E%3Cpath d='M12 16h.01'/%3E%3C/svg%3E" }
  ],
  script: [
    {
      type: 'application/ld+json',
      children: JSON.stringify([
        {
          "@context": "https://schema.org",
          "@type": "SoftwareApplication",
          "name": "TelcoSec-Chisel",
          "applicationCategory": "SecurityApplication",
          "applicationSubCategory": "Telecommunications Security, Software Defined Radio, Baseband Analysis",
          "operatingSystem": "Linux (Ubuntu 24.04 LTS)",
          "description": "TelcoSec-Chisel is a free, bootable live Linux distribution purpose-built for 5G and 4G telecom security research. It ships with 25+ pre-configured tools including GNU Radio, FirmWire baseband emulation, srsRAN, Open5GS, SIMtrace 2, QCSuper, Wireshark, and the 5Ghoul 5G NR fuzzer.",
          "url": "https://telcosec.github.io/TelcoSec-Chisel/",
          "downloadUrl": "https://github.com/TelcoSec/TelcoSec-Chisel/releases",
          "softwareVersion": "1.1.0",
          "releaseNotes": "https://github.com/TelcoSec/TelcoSec-Chisel/releases",
          "screenshot": "https://raw.githubusercontent.com/TelcoSec/TelcoSec-Chisel/main/assets/repo_cover.png",
          "featureList": [
            "SDR drivers for USRP B210, HackRF One, BladeRF, LimeSDR, and RTL-SDR compiled from source",
            "Baseband firmware emulation with FirmWire (Samsung Shannon and MediaTek MTK)",
            "5G NR fuzzing with 5Ghoul over OAI rogue gNodeB",
            "SIM and eSIM auditing with pySim-shell, SIMtrace 2, and lpac LPA",
            "5G SA core network with Open5GS and MongoDB",
            "4G/5G RAN simulation with srsRAN",
            "SS7, Diameter, GTP, and SIP protocol exploitation tools",
            "Custom Wireshark dissector profiles for GSMTAP, 5G NAS, Diameter, and GTP",
            "SCTP kernel tuning and real-time scheduling for SDR stability",
            "Calamares live-to-disk installer"
          ],
          "license": "https://github.com/TelcoSec/TelcoSec-Chisel/blob/main/LICENSE",
          "offers": {
            "@type": "Offer",
            "price": "0",
            "priceCurrency": "USD",
            "availability": "https://schema.org/InStock"
          },
          "publisher": {
            "@type": "Organization",
            "name": "TelcoSec",
            "url": "https://telcosec.net/",
            "sameAs": [
              "https://github.com/TelcoSec",
              "https://www.linkedin.com/company/telco-sec",
              "https://www.youtube.com/@Telecom-Security"
            ]
          }
        },
        {
          "@context": "https://schema.org",
          "@type": "WebSite",
          "name": "TelcoSec-Chisel Documentation",
          "url": "https://telcosec.github.io/TelcoSec-Chisel/",
          "description": "Official documentation for TelcoSec-Chisel — a free Linux distribution for 5G/4G telecom security research.",
          "publisher": {
            "@type": "Organization",
            "name": "TelcoSec",
            "url": "https://telcosec.net/"
          },
          "potentialAction": {
            "@type": "SearchAction",
            "target": "https://telcosec.github.io/TelcoSec-Chisel/#tools?q={search_term_string}",
            "query-input": "required name=search_term_string"
          }
        },
        {
          "@context": "https://schema.org",
          "@type": "FAQPage",
          "mainEntity": [
            {
              "@type": "Question",
              "name": "What is TelcoSec-Chisel?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "TelcoSec-Chisel is a free, bootable live Linux distribution based on Ubuntu 24.04 LTS (Noble Numbat) with an XFCE desktop, purpose-built for telecommunications security research. It includes over 25 pre-configured tools for Software Defined Radio (SDR) analysis, baseband firmware auditing, SIM and eSIM inspection, and 5G/4G core network penetration testing."
              }
            },
            {
              "@type": "Question",
              "name": "What SDR hardware does TelcoSec-Chisel support?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "TelcoSec-Chisel includes drivers compiled from source for the Ettus Research USRP B210, Great Scott Gadgets HackRF One, Nuand BladeRF 2.0 micro xA4, LimeSDR, and RTL-SDR dongles. All radio drivers and GNU Radio are isolated in a Conda virtual environment named telcosec-sdr to prevent dependency conflicts."
              }
            },
            {
              "@type": "Question",
              "name": "What are the default login credentials for TelcoSec-Chisel?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "The default live boot credentials are username: telcosec and password: telcosec. The system is configured for graphical autologin, so you will only be prompted if autologin is disabled."
              }
            },
            {
              "@type": "Question",
              "name": "How do I build the TelcoSec-Chisel ISO?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "Run 'sudo ./build-iso.sh' on an Ubuntu or Debian host after installing: debootstrap, squashfs-tools, grub-pc-bin, grub-efi-amd64-bin, xorriso, and mtools. The build requires approximately 20 GB of free disk space and takes 30 to 60 minutes. On Windows, you can build inside WSL2."
              }
            },
            {
              "@type": "Question",
              "name": "Can I run TelcoSec-Chisel in a virtual machine?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "Most analysis tools work in a VM. However, SDR tools requiring native USB 3.0 passthrough — particularly when running the 5Ghoul 5G NR fuzzer — need bare metal installation for reliable operation due to USB latency requirements."
              }
            },
            {
              "@type": "Question",
              "name": "How do I install 5Ghoul on TelcoSec-Chisel?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "Run 'sudo 5ghoul-install' for a USRP B210, or 'sudo 5ghoul-install --radio BLADERF' for a BladeRF A4. The installer clones the 5Ghoul repository, applies radio-specific patches, and compiles OpenAirInterface. This takes 20–60 minutes on first run. All build dependencies are pre-installed in the ISO."
              }
            },
            {
              "@type": "Question",
              "name": "What telecom protocol analysis tools are included?",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "TelcoSec-Chisel includes: Wireshark with custom GSMTAP/5G NAS/Diameter/GTP dissector profiles, SigPloit (SS7/Diameter/GTP exploitation), Diafuzzer (Diameter fuzzer by Orange), SIPVicious (SIP/VoIP scanner), sctpscan (SCTP port scanner for SIGTRAN/S1AP/NGAP), and Scapy with built-in modules for M3UA, TCAP, MAP, and Diameter packet crafting."
              }
            }
          ]
        }
      ])
    }
  ]
})

// Section navigation
const VALID_SECTIONS = ['overview', 'features', 'tools', 'drivers', 'fuzzer', 'builder', 'projects']
const activeSection = ref('overview')
const sidebarOpen = ref(false)

function navigate(section) {
  if (!VALID_SECTIONS.includes(section)) section = 'overview'
  activeSection.value = section
  if (import.meta.client) {
    history.pushState(null, '', '#' + section)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
  sidebarOpen.value = false
}

onMounted(() => {
  const hash = window.location.hash.slice(1)
  if (hash) navigate(hash)
  window.addEventListener('popstate', () => navigate(window.location.hash.slice(1) || 'overview'))
  if (localStorage.getItem('theme') === 'light') document.body.classList.add('light-theme')
})

// Theme
function toggleTheme() {
  const isLight = document.body.classList.toggle('light-theme')
  localStorage.setItem('theme', isLight ? 'light' : 'dark')
}

// Tools directory
const activeFilter = ref('all')
const searchQuery = ref('')
const filters = [
  { id: 'all',     label: 'All Tools' },
  { id: 'sdr',     label: 'SDR' },
  { id: 'gsm',     label: 'GSM / 2G' },
  { id: 'lte',     label: 'LTE / 4G' },
  { id: '5g',      label: '5G NR' },
  { id: 'ue',      label: 'Baseband & UE' },
  { id: 'sim',     label: 'SIM / eSIM' },
  { id: 'ran',     label: 'RAN & Signaling' },
  { id: 'device',  label: 'Device Tools' },
  { id: 'network', label: 'Network' },
  { id: 'voip',    label: 'VoIP' },
  { id: 'tetra',   label: 'TETRA' },
  { id: 'sys',     label: 'System' }
]
const filteredTools = computed(() => toolsCatalog.filter(t => {
  const matchCat = activeFilter.value === 'all' || t.category === activeFilter.value
  const q = searchQuery.value.toLowerCase()
  const matchSearch = !q || t.name.toLowerCase().includes(q) || t.desc.toLowerCase().includes(q) || t.cmd.toLowerCase().includes(q)
  return matchCat && matchSearch
}))
function filterCount(id) {
  if (id === 'all') return toolsCatalog.length
  return toolsCatalog.filter(t => t.category === id).length
}

// Keyboard shortcut for search
const searchInput = ref(null)
onMounted(() => {
  document.addEventListener('keydown', (e) => {
    const tag = document.activeElement.tagName.toLowerCase()
    if ((e.key === '/' || ((e.ctrlKey || e.metaKey) && e.key === 'k')) && tag !== 'input' && tag !== 'textarea') {
      e.preventDefault()
      searchInput.value?.focus()
      navigate('tools')
    }
  })
})

// Tag helpers
function tagClass(cat) {
  return {
    sdr:     'tag-sdr',
    gsm:     'tag-gsm',
    lte:     'tag-lte',
    '5g':    'tag-5g',
    ue:      'tag-ue',
    sim:     'tag-sim',
    ran:     'tag-ran',
    device:  'tag-device',
    network: 'tag-network',
    voip:    'tag-voip',
    tetra:   'tag-tetra',
    sys:     'tag-sys'
  }[cat] || ''
}
function tagLabel(cat) {
  return {
    sdr:     'SDR',
    gsm:     'GSM / 2G',
    lte:     'LTE / 4G',
    '5g':    '5G NR',
    ue:      'UE & Baseband',
    sim:     'SIM / Smartcard',
    ran:     'RAN & Signaling',
    device:  'Device Tools',
    network: 'Network',
    voip:    'VoIP',
    tetra:   'TETRA & PMR',
    sys:     'System'
  }[cat] || cat
}
</script>
