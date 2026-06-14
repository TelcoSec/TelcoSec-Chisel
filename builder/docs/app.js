// TelcoSec-Chisel Documentation Application Logic

// Complete catalog of pre-installed tools on TelcoSec-Chisel
const toolsCatalog = [
    {
        name: "GNU Radio 3.10",
        category: "sdr",
        desc: "The primary digital signal processing (DSP) framework and graphical flowchart design suite for SDR transceiver implementation.",
        path: "Conda env (telcosec-sdr)",
        cmd: "conda activate telcosec-sdr && gnuradio-companion"
    },
    {
        name: "SoapySDR",
        category: "sdr",
        desc: "A vendor-neutral SDR hardware abstraction layer and API, allowing software built against it to work with a wide range of transceivers.",
        path: "Conda env (telcosec-sdr)",
        cmd: "SoapySDRUtil --info"
    },
    {
        name: "UHD (USRP Hardware Driver)",
        category: "sdr",
        desc: "Official device driver and interface software for Ettus Research USRP software-defined radios (B210, X310, etc.), compiled from source.",
        path: "Conda env (telcosec-sdr)",
        cmd: "uhd_usrp_probe --args=\"type=b200\""
    },
    {
        name: "HackRF Host Tools",
        category: "sdr",
        desc: "Command-line configuration and operation tools for the Great Scott Gadgets HackRF One, including firmware flashers and receiver utilities.",
        path: "Conda env (telcosec-sdr)",
        cmd: "hackrf_info"
    },
    {
        name: "gr-gsm Tools",
        category: "sdr",
        desc: "Gnu Radio blocks and scripts for receiving, decoding, and analyzing the GSM air interface (2G). Includes live channel monitoring.",
        path: "Conda env (telcosec-sdr)",
        cmd: "grgsm_livemon"
    },
    {
        name: "Kalibrate RTL (kal)",
        category: "sdr",
        desc: "Scans for GSM base stations and uses their broadcasts to calibrate the local oscillator frequency offset on RTL-SDR dongles.",
        path: "Conda env (telcosec-sdr)",
        cmd: "kal -s GSM900"
    },
    {
        name: "FirmWire Emulation",
        category: "ue",
        desc: "A baseband firmware emulation and fuzzing platform. Emulates Samsung Shannon and MediaTek modems under QEMU, enabling analysis of baseband OTA packets.",
        path: "/opt/telcosec/firmwire/",
        cmd: "/opt/telcosec/firmwire/venv/bin/firmwire --help"
    },
    {
        name: "QCSuper",
        category: "ue",
        desc: "Qualcomm diagnostic protocol log parser that generates PCAP files from baseband OTA messages sniffed from a phone connected via USB.",
        path: "System-wide (pip: qcsuper)",
        cmd: "qcsuper --help"
    },
    {
        name: "MTKClient",
        category: "ue",
        desc: "A powerful dump, flash, partition editor, and bootloader/BROM bypass tool for MediaTek (MTK) chipset devices.",
        path: "System-wide python",
        cmd: "mtk --help"
    },
    {
        name: "Balong-Flash & Balongtool",
        category: "ue",
        desc: "Firmware compilation, modification, and direct USB flasher utilities targeting Huawei Balong-based LTE modems and routers.",
        path: "/usr/local/bin/",
        cmd: "balong-flash --help"
    },
    {
        name: "Osmocom SIMtrace 2 Host",
        category: "sim",
        desc: "Host-side companion daemon and sniffer utilities to inspect smartcard ISO-7816 communication between SIM readers and actual handsets.",
        path: "System-wide binaries",
        cmd: "simtrace2-list"
    },
    {
        name: "Osmocom pySim",
        category: "sim",
        desc: "An interactive smartcard management shell and scripting library capable of reading, writing, and configuring USIM/SIM credentials.",
        path: "/opt/telcosec/pysim/",
        cmd: "pySim-shell.py --help"
    },
    {
        name: "lpac (eSIM LPA)",
        category: "sim",
        desc: "An independent Local Profile Assistant (LPA) for eSIM profiles, implementing GSMA SGP.22 specifications over PC/SC readers.",
        path: "/usr/local/bin/lpac",
        cmd: "lpac profile list"
    },
    {
        name: "PCSC Daemon (pcscd)",
        category: "sim",
        desc: "Smartcard interface daemon facilitating reader communication between hardware card slot readers and software tools.",
        path: "System service",
        cmd: "systemctl status pcscd"
    },
    {
        name: "srsRAN 4G/5G Simulator",
        category: "ran",
        desc: "Full open-source SDR-based 4G/5G mobile network simulator implementing gNodeB, eNodeB, and User Equipment (UE). Suitable for virtual cell testing.",
        path: "System-wide",
        cmd: "srsenb --help"
    },
    {
        name: "Wireshark & TShark",
        category: "ran",
        desc: "World-class packet sniffer customized with layout profiles displaying GSMTAP, 5G NAS, Diameter codes, and GTP headers.",
        path: "System desktop application",
        cmd: "wireshark"
    },
    {
        name: "SIPVicious",
        category: "ran",
        desc: "Audit toolset for SIP-based VoIP systems. Designed to scan target networks, brute-force extensions, and audit registration systems.",
        path: "System-wide python",
        cmd: "svmap --help"
    },
    {
        name: "sctpscan",
        category: "ran",
        desc: "A fast SCTP port scanner to map host capabilities and discover ports running S1AP, NGAP, Diameter, or M3UA SIGTRAN protocols.",
        path: "/usr/local/bin/sctpscan",
        cmd: "sctpscan --help"
    },
    {
        name: "SigPloit",
        category: "ran",
        desc: "Signaling exploitation framework targeting SS7, Diameter, and GTP protocols to audit core telecom networks for routing vulnerabilities.",
        path: "/opt/telcosec/sigploit/",
        cmd: "python2 /opt/telcosec/sigploit/sigploit.py"
    },
    {
        name: "Diafuzzer",
        category: "ran",
        desc: "Diameter protocol fuzzer written by Orange Security, designed to test core interfaces (S6a, Gx, Gy) for vulnerability to malformed requests.",
        path: "/opt/telcosec/diafuzzer/",
        cmd: "python3 /opt/telcosec/diafuzzer/diafuzzer.py --help"
    },
    {
        name: "Scapy (with SS7/Diameter modules)",
        category: "ran",
        desc: "Interactive packet manipulation program extended to support construction of custom MAP, TCAP, M3UA, and Diameter network frames.",
        path: "System-wide python",
        cmd: "scapy"
    },
    {
        name: "5Ghoul Fuzzer Wrapper",
        category: "ran",
        desc: "Custom launcher wrapper that simplifies executing the 5Ghoul fuzzer, automatically patching configurations for BladeRF and USRP transceivers.",
        path: "/usr/local/bin/5ghoul-run",
        cmd: "sudo 5ghoul-run --Attack.Name=NAS_5GS_Fuzz"
    },
    {
        name: "Open5GS Core Network",
        category: "ran",
        desc: "A complete open-source implementation of 4G EPC and 5G Core Network functions (AMF, SMF, UPF, UDM, HSS) built with high performance in C.",
        path: "System services",
        cmd: "systemctl status open5gs-amfd"
    },
    {
        name: "Docker & Docker Compose",
        category: "sys",
        desc: "Containerization engine pre-configured for non-root management. Used to spin up large-scale core network elements quickly.",
        path: "System services",
        cmd: "docker ps"
    },
    {
        name: "Telecom Wordlists",
        category: "sys",
        desc: "Bundled telecom-specific wordlist collection covering carrier APNs, VoIP/SIP credentials, RAN element passwords, SIM OTA test keys, hardware defaults, PLMNs/IMSI prefixes, and protocol-level lists for 5G NAS, GTP, SS7, Diameter, SMS, and USSD. Includes telcosec-apn-permutator and telcosec-imsi-generator helper scripts on PATH.",
        path: "/usr/share/wordlists/telecom/",
        cmd: "ls -lR /usr/share/wordlists/telecom/"
    }
];

document.addEventListener("DOMContentLoaded", () => {
    // ── Sidebar views navigation ────────────────────────────────────────────
    const navLinks = document.querySelectorAll(".nav-link");
    const sections = document.querySelectorAll(".content-section");
    const sidebar = document.querySelector(".sidebar");
    const mobileToggle = document.getElementById("mobileToggle");
    const sidebarOverlay = document.getElementById("sidebarOverlay");

    const VALID_SECTIONS = ["overview", "features", "tools", "drivers", "fuzzer", "builder", "projects"];

    function activateSection(target) {
        if (!VALID_SECTIONS.includes(target)) target = "overview";

        navLinks.forEach(l => {
            if (l.getAttribute("data-target") === target) {
                l.classList.add("active");
            } else {
                l.classList.remove("active");
            }
        });

        sections.forEach(sec => {
            if (sec.id === target) {
                sec.classList.add("active");
            } else {
                sec.classList.remove("active");
            }
        });

        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    // Activate section from URL hash on initial load
    const initialHash = window.location.hash.slice(1);
    if (initialHash) activateSection(initialHash);

    // Handle browser back / forward navigation
    window.addEventListener("popstate", () => {
        activateSection(window.location.hash.slice(1) || "overview");
    });

    navLinks.forEach(link => {
        link.addEventListener("click", (e) => {
            e.preventDefault();
            const target = link.getAttribute("data-target");

            // Update URL hash without triggering a page scroll
            history.pushState(null, "", "#" + target);
            activateSection(target);

            // Close sidebar on mobile after clicking
            if (sidebar.classList.contains("open")) {
                sidebar.classList.remove("open");
                if (sidebarOverlay) sidebarOverlay.classList.remove("active");
                mobileToggle.innerHTML = `
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                `;
            }
        });
    });

    // ── Mobile sidebar toggle ───────────────────────────────────────────────
    if (mobileToggle) {
        mobileToggle.addEventListener("click", () => {
            const isOpen = sidebar.classList.toggle("open");
            if (sidebarOverlay) sidebarOverlay.classList.toggle("active", isOpen);
            if (isOpen) {
                mobileToggle.innerHTML = `
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="18" y1="6" x2="6" y2="18"></line>
                        <line x1="6" y1="6" x2="18" y2="18"></line>
                    </svg>
                `;
            } else {
                mobileToggle.innerHTML = `
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                `;
            }
        });
    }

    if (sidebarOverlay) {
        sidebarOverlay.addEventListener("click", () => {
            sidebar.classList.remove("open");
            sidebarOverlay.classList.remove("active");
            if (mobileToggle) {
                mobileToggle.innerHTML = `
                    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="3" y1="12" x2="21" y2="12"></line>
                        <line x1="3" y1="6" x2="21" y2="6"></line>
                        <line x1="3" y1="18" x2="21" y2="18"></line>
                    </svg>
                `;
            }
        });
    }

    // ── Update filter buttons with tool counts ──────────────────────────────
    function updateFilterCounts() {
        const counts = { all: toolsCatalog.length, sdr: 0, ue: 0, sim: 0, ran: 0, sys: 0 };
        toolsCatalog.forEach(tool => {
            if (counts[tool.category] !== undefined) {
                counts[tool.category]++;
            }
        });
        
        const filterBtnsList = document.querySelectorAll(".filter-btn");
        filterBtnsList.forEach(btn => {
            const filter = btn.getAttribute("data-filter");
            const label = btn.textContent.split(" (")[0]; // Clean label
            if (counts[filter] !== undefined) {
                btn.textContent = `${label} (${counts[filter]})`;
            }
        });
    }

    // Initialize filter counts
    updateFilterCounts();

    // ── Tools directory implementation ──────────────────────────────────────
    const toolsGrid = document.getElementById("toolsGrid");
    const searchInput = document.getElementById("toolSearch");
    const filterBtns = document.querySelectorAll(".filter-btn");
    
    let activeFilter = "all";
    let searchQuery = "";

    function renderTools() {
        if (!toolsGrid) return;
        toolsGrid.innerHTML = "";

        const filteredTools = toolsCatalog.filter(tool => {
            const matchesCategory = activeFilter === "all" || tool.category === activeFilter;
            const matchesSearch = tool.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                                  tool.desc.toLowerCase().includes(searchQuery.toLowerCase()) ||
                                  tool.cmd.toLowerCase().includes(searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
        });

        if (filteredTools.length === 0) {
            toolsGrid.innerHTML = `
                <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: var(--text-muted);">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" style="margin-bottom: 15px;">
                        <circle cx="11" cy="11" r="8"></circle>
                        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                    </svg>
                    <p>No tools match your query: "${searchQuery}"</p>
                </div>
            `;
            return;
        }

        filteredTools.forEach(tool => {
            const card = document.createElement("div");
            card.className = "card highlight-teal";

            let catTag = "";
            switch(tool.category) {
                case "sdr": catTag = '<span class="tag tag-sdr">SDR</span>'; break;
                case "ue": catTag = '<span class="tag tag-ue">UE & Baseband</span>'; break;
                case "sim": catTag = '<span class="tag tag-sim">SIM/Smartcard</span>'; break;
                case "ran": catTag = '<span class="tag tag-ran">RAN & Signaling</span>'; break;
                case "sys": catTag = '<span class="tag tag-sys">System & Hardening</span>'; break;
            }

            card.innerHTML = `
                <div class="card-title">
                    ${tool.name}
                    ${catTag}
                </div>
                <p class="card-desc" style="margin-bottom: 15px;">${tool.desc}</p>
                <div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 6px;">
                    <strong>Location:</strong> <code class="inline-code" style="color: var(--text-secondary);">${tool.path}</code>
                </div>
                <div class="terminal-block" style="margin: 10px 0 0 0;">
                    <div class="terminal-body" style="padding: 10px 15px;">
                        <code>$ ${tool.cmd}</code>
                        <button class="terminal-copy-btn" onclick="copyCommand(this, '${tool.cmd.replace(/'/g, "\\'")}')" style="top: 5px; right: 10px; padding: 3px 6px;">Copy</button>
                    </div>
                </div>
            `;

            toolsGrid.appendChild(card);
        });
    }

    if (searchInput) {
        const searchShortcut = document.getElementById("searchShortcut");
        const searchClearBtn = document.getElementById("searchClearBtn");

        // Handle shortcuts (/)
        document.addEventListener("keydown", (e) => {
            const activeTag = document.activeElement.tagName.toLowerCase();
            const isInputActive = activeTag === "input" || activeTag === "textarea";
            
            // '/' or 'Ctrl+K' focuses search input
            if ((e.key === "/" || ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k")) && !isInputActive) {
                e.preventDefault();
                searchInput.focus();
            }
        });

        // Hide shortcut overlay on focus
        searchInput.addEventListener("focus", () => {
            if (searchShortcut) searchShortcut.style.opacity = "0";
        });

        // Show shortcut overlay on blur if empty
        searchInput.addEventListener("blur", () => {
            if (searchShortcut && !searchInput.value) {
                searchShortcut.style.opacity = "1";
            }
        });

        searchInput.addEventListener("input", (e) => {
            searchQuery = e.target.value;
            if (searchClearBtn) {
                searchClearBtn.style.display = searchQuery ? "flex" : "none";
            }
            if (searchShortcut) {
                searchShortcut.style.opacity = searchQuery ? "0" : "1";
            }
            renderTools();
        });

        if (searchClearBtn) {
            searchClearBtn.addEventListener("click", () => {
                searchInput.value = "";
                searchQuery = "";
                searchClearBtn.style.display = "none";
                if (searchShortcut) searchShortcut.style.opacity = "1";
                searchInput.focus();
                renderTools();
            });
        }
    }

    filterBtns.forEach(btn => {
        btn.addEventListener("click", () => {
            filterBtns.forEach(b => b.classList.remove("active"));
            btn.classList.add("active");
            activeFilter = btn.getAttribute("data-filter");
            renderTools();
        });
    });

    // ── Theme toggle switch implementation ───────────────────────────────
    const themeToggleBtn = document.getElementById("themeToggleBtn");
    
    // Check local storage for theme preference
    const savedTheme = localStorage.getItem("theme");
    if (savedTheme === "light") {
        document.body.classList.add("light-theme");
    }

    if (themeToggleBtn) {
        themeToggleBtn.addEventListener("click", () => {
            const isLight = document.body.classList.toggle("light-theme");
            localStorage.setItem("theme", isLight ? "light" : "dark");
        });
    }

    // Initial render of tools
    renderTools();

    // ── Boot overlay (CRT scan sweep) ────────────────────────────────────────
    const bootOverlay = document.getElementById("bootOverlay");
    if (bootOverlay) {
        setTimeout(() => {
            bootOverlay.classList.add("done");
            bootOverlay.addEventListener("animationend", () => bootOverlay.remove(), { once: true });
        }, 920);
    }

    // ── Spectrum analyzer canvas ──────────────────────────────────────────────
    initSpectrum();
});

// ── Spectrum canvas — live amber frequency bars in the overview hero ─────────
function initSpectrum() {
    const canvas = document.getElementById("spectrumCanvas");
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    const COUNT = 42;
    const BAR_W = 3;
    const GAP = 2;
    const TOTAL_W = COUNT * (BAR_W + GAP);

    canvas.width = TOTAL_W;

    function resize() {
        const h = canvas.parentElement ? canvas.parentElement.offsetHeight : 140;
        canvas.height = Math.max(h, 80);
    }
    resize();
    window.addEventListener("resize", resize);

    const bars = Array.from({ length: COUNT }, () => ({
        h: Math.random() * 0.55 + 0.08,
        target: Math.random() * 0.55 + 0.08,
        speed: Math.random() * 0.035 + 0.012,
        jitter: Math.random() * 0.18 + 0.04
    }));

    function draw() {
        const H = canvas.height;
        ctx.clearRect(0, 0, canvas.width, H);

        bars.forEach((bar, i) => {
            bar.h += (bar.target - bar.h) * bar.speed;

            if (Math.random() < 0.018) {
                bar.target = Math.random() * 0.78 + 0.05;
                bar.speed = Math.random() * 0.04 + 0.01;
            }

            const jitter = (Math.random() - 0.5) * bar.jitter;
            const barH = Math.max(3, (bar.h + jitter) * H);
            const x = i * (BAR_W + GAP);
            const y = H - barH;

            const grad = ctx.createLinearGradient(0, H, 0, y);
            grad.addColorStop(0, "rgba(232, 146, 30, 0.95)");
            grad.addColorStop(0.55, "rgba(245, 170, 53, 0.72)");
            grad.addColorStop(1, "rgba(255, 210, 100, 0.35)");

            ctx.fillStyle = grad;
            ctx.fillRect(x, y, BAR_W, barH);

            // Peak pixel
            ctx.fillStyle = "rgba(255, 230, 160, 0.88)";
            ctx.fillRect(x, y, BAR_W, 1);
        });

        requestAnimationFrame(draw);
    }

    draw();
}

// Clipboard helper function (globally available)
window.copyCommand = function(button, command) {
    navigator.clipboard.writeText(command).then(() => {
        const originalText = button.textContent;
        button.textContent = "Copied!";
        button.style.borderColor = "var(--accent-teal)";
        button.style.color = "var(--accent-teal)";
        
        setTimeout(() => {
            button.textContent = originalText;
            button.style.borderColor = "var(--border-color)";
            button.style.color = "var(--text-secondary)";
        }, 1500);
    }).catch(err => {
        console.error('Could not copy command to clipboard: ', err);
    });
};
