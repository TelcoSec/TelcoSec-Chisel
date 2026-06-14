#!/bin/bash
set -e

echo "=== Customizing Desktop Environment ==="

# 1. GDM3 Autologin + Wallpaper Directory
echo "Configuring GDM3 autologin..."
sudo mkdir -p /usr/share/backgrounds/telcosec
sudo mkdir -p /etc/gdm3

cat << 'EOF' | sudo tee /etc/gdm3/custom.conf
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=telcosec

[security]

[xdmcp]

[chooser]

[debug]
EOF

# Tell casper which user is the live session user.
# Without this, casper's 10adduser hook doesn't configure LightDM autologin
# on first boot and the session never starts.
cat << 'EOF' | sudo tee /etc/casper.conf
export USERNAME=telcosec
export USERFULLNAME="TelcoSec Researcher"
export HOST=telcosec-chisel
export BUILD_SYSTEM=Ubuntu
export FLAVOUR=ubuntu
EOF

# 2. GNOME system-wide dconf configuration
echo "Writing GNOME dconf configuration..."
sudo mkdir -p /etc/dconf/db/local.d

cat << 'EOF' | sudo tee /etc/dconf/db/local.d/00-telcosec
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/telcosec/wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/telcosec/wallpaper.png'
picture-options='scaled'

[org/gnome/desktop/screensaver]
lock-enabled=false
idle-activation-enabled=false

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0
power-button-action='nothing'

[org/gnome/desktop/interface]
font-name='Sans 10'
monospace-font-name='IBM Plex Mono 11'
color-scheme='prefer-dark'
enable-animations=true

[org/gnome/desktop/wm/preferences]
button-layout=':minimize,maximize,close'
num-workspaces=4

[org/gnome/desktop/wm/keybindings]
switch-to-workspace-1=['<Super>1']
switch-to-workspace-2=['<Super>2']
switch-to-workspace-3=['<Super>3']
switch-to-workspace-4=['<Super>4']
maximize=['<Super>Up']
unmaximize=['<Super>Down']
tile-left=['<Super>Left']
tile-right=['<Super>Right']

[org/gnome/mutter]
edge-tiling=true

[org/gnome/shell]
favorite-apps=['org.gnome.Terminal.desktop', 'firefox.desktop', 'org.wireshark.Wireshark.desktop', 'org.gnome.Nautilus.desktop', 'gnuradio-companion.desktop', 'gqrx.desktop', 'open5gs-start.desktop', 'wireshark-mon.desktop']

[org/gnome/desktop/notifications]
show-banners=true
show-in-lock-screen=false
EOF

cat << 'EOF' | sudo tee /etc/dconf/db/local.d/01-telcosec-appfolders
[org/gnome/desktop/app-folders]
folder-children=['SDR', 'GSM', 'LTE', 'NR5G', 'Baseband', 'SIM', 'Core', 'Device', 'Network', 'VoIP', 'TETRA']

[org/gnome/desktop/app-folders/folders/SDR]
name='SDR & Spectrum'
categories=['TelcoSec-SDR']

[org/gnome/desktop/app-folders/folders/GSM]
name='GSM / 2G'
categories=['TelcoSec-GSM']

[org/gnome/desktop/app-folders/folders/LTE]
name='LTE / 4G'
categories=['TelcoSec-LTE']

[org/gnome/desktop/app-folders/folders/NR5G]
name='5G NR'
categories=['TelcoSec-5GNR']

[org/gnome/desktop/app-folders/folders/Baseband]
name='Baseband & Firmware'
categories=['TelcoSec-Baseband']

[org/gnome/desktop/app-folders/folders/SIM]
name='SIM & eSIM'
categories=['TelcoSec-SIM', 'TelcoSec-Tools']

[org/gnome/desktop/app-folders/folders/Core]
name='Core Signaling'
categories=['TelcoSec-Core']

[org/gnome/desktop/app-folders/folders/Device]
name='Device Tools'
categories=['TelcoSec-Device']

[org/gnome/desktop/app-folders/folders/Network]
name='Network Analysis'
categories=['TelcoSec-Network']

[org/gnome/desktop/app-folders/folders/VoIP]
name='VoIP & Messaging'
categories=['TelcoSec-VoIP']

[org/gnome/desktop/app-folders/folders/TETRA]
name='TETRA & PMR'
categories=['TelcoSec-TETRA']
EOF

# 2. Message of the Day (MOTD)
echo "Configuring MOTD..."
# Remove default Ubuntu dynamic MOTD scripts for a cleaner look
sudo rm -f /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news

# Create a custom TelcoSec ASCII Art MOTD
cat << 'EOF' | sudo tee /etc/update-motd.d/05-telcosec-logo
#!/bin/sh
echo "  _______    __           _____           "
echo " |__   __|  | |          / ____|          "
echo "    | | ___ | | ___ ___ | (___   ___  ___ "
echo "    | |/ _ \| |/ __/ _ \ \___ \ / _ \/ __|"
echo "    | |  __/| | (_| (_) |____) |  __/ (__ "
echo "    |_|\___||_|\___\___/|_____/ \___|\___|"
echo "                                          "
echo "      --- Telecom Security Platform ---   "
echo ""
EOF
sudo chmod +x /etc/update-motd.d/05-telcosec-logo

# 3. Custom Rich Bash Prompt (Optimized, Simple, Zero-Lag, Single-Line Style)
echo "Configuring Global Bash Prompt..."
cat << 'PROMPTEOF' | sudo tee /etc/profile.d/telcosec_prompt.sh
# TelcoSec simple prompt: user@host:dir $
__telcosec_ps1() {
  local EXIT="$?"
  
  # Colors mapped to ANSI standards
  local CY='\[\e[0;36m\]'      # user@host (ANSI Cyan)
  local W='\[\e[1;37m\]'       # path/directory (ANSI White)
  local R='\[\e[0m\]'          # reset
  local RED='\[\e[0;31m\]'     # error indicator (ANSI Red)
  
  # Exit status indicator for the prompt symbol ($ for user, # for root)
  local p_symbol="\$"
  if [ "$EXIT" -ne 0 ]; then
    p_symbol="${RED}${p_symbol}"
  else
    p_symbol="${CY}${p_symbol}"
  fi

  PS1="${CY}\u@\h${R}:${W}\w${R} ${p_symbol}${R} "
}
export PROMPT_COMMAND=__telcosec_ps1
PROMPTEOF
sudo chmod +x /etc/profile.d/telcosec_prompt.sh

# 4. Deploy Local Documentation & Configure Firefox Policies
echo "Deploying local documentation..."
sudo mkdir -p /usr/share/doc/telcosec/
if [ -d /tmp/docs ]; then
  sudo cp -rf /tmp/docs/. /usr/share/doc/telcosec/
  sudo find /usr/share/doc/telcosec/ -type f -exec chmod 644 {} +
fi

echo "Configuring Firefox enterprise policies..."
sudo mkdir -p /etc/firefox/policies/
cat << 'EOF' | sudo tee /etc/firefox/policies/policies.json
{
  "policies": {
    "DisableAppUpdate": true,
    "Certificates": {
      "Install": [
        "/usr/local/share/ca-certificates/telcosec-ca.crt",
        "/usr/local/share/ca-certificates/cloudflare_origin_ecc.crt",
        "/usr/local/share/ca-certificates/cloudflare_origin_rsa.crt"
      ]
    },
    "Homepage": {
      "URL": "file:///usr/share/doc/telcosec/index.html",
      "Locked": false,
      "StartPage": "homepage"
    },
    "Bookmarks": [
      {
        "Title": "TelcoSec Local Docs",
        "URL": "file:///usr/share/doc/telcosec/index.html",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Community Hub",
        "URL": "https://community.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Academy",
        "URL": "https://app.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Blog",
        "URL": "https://blog.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Tools",
        "URL": "https://tools.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Calculators",
        "URL": "https://calculators.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec CTF Portal",
        "URL": "https://ctf.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec 3GPP Tracker",
        "URL": "https://3gpp.telcosec.cloud/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Discord Chat",
        "URL": "https://discord.gg/RykzXTQFXF",
        "Placement": "toolbar"
      }
    ]
  }
}
EOF

# 5. Network: DHCP default + dedicated monitoring interface
echo "Configuring network defaults..."
sudo mkdir -p /etc/NetworkManager/conf.d
cat << 'EOF' | sudo tee /etc/NetworkManager/conf.d/telcosec.conf
[main]
dhcp=internal

[device]
wifi.scan-rand-mac-address=no
carrier-wait-timeout=2000

[connection]
ipv4.dhcp-timeout=10
ipv6.dhcp-timeout=10
ipv4.may-fail=yes
ipv6.may-fail=yes
EOF

# Configure LAN interface ens160 to use DHCP via Netplan (Ubuntu 24.04 defaults)
sudo mkdir -p /etc/netplan
cat << 'EOF' | sudo tee /etc/netplan/90-telcosec-ens160.yaml
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens160:
      dhcp4: true
      dhcp6: true
      optional: true
EOF

# Monitoring interface setup script (creates mon0 from first available wlan)
cat << 'EOF' | sudo tee /usr/local/bin/telcosec-mon-setup
#!/bin/bash
# Bring up a monitor-mode interface (mon0) from the first wireless adapter.
# Called at boot via telcosec-mon.service.
WLAN=$(iw dev 2>/dev/null | awk '/Interface/{print $2}' | grep -v '^mon' | head -1)
if [ -z "$WLAN" ]; then
  echo "telcosec-mon-setup: no wireless interface found, skipping mon0 creation"
  exit 0
fi
if ip link show mon0 &>/dev/null; then
  echo "telcosec-mon-setup: mon0 already exists"
  exit 0
fi
echo "telcosec-mon-setup: creating mon0 from ${WLAN}"
ip link set "$WLAN" down
iw dev "$WLAN" interface add mon0 type monitor 2>/dev/null || \
  airmon-ng start "$WLAN" 2>/dev/null || true
ip link set mon0 up 2>/dev/null || true
ip link set "$WLAN" up 2>/dev/null || true
EOF
sudo chmod +x /usr/local/bin/telcosec-mon-setup

# Systemd service to start mon0 at boot
cat << 'EOF' | sudo tee /etc/systemd/system/telcosec-mon.service
[Unit]
Description=TelcoSec Monitoring Interface (mon0)
After=network.target
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/telcosec-mon-setup
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable telcosec-mon.service 2>/dev/null || true

# Wireshark default capture interface → mon0
sudo mkdir -p /etc/skel/.config/wireshark
cat << 'EOF' | sudo tee /etc/skel/.config/wireshark/preferences
# TelcoSec default: capture on monitoring interface
capture.default_interface: mon0
capture.prom_mode: TRUE
gui.expert_composite_eyecandy: TRUE
EOF
if [ -d /home/telcosec ]; then
  sudo mkdir -p /home/telcosec/.config/wireshark
  sudo cp /etc/skel/.config/wireshark/preferences /home/telcosec/.config/wireshark/preferences
  sudo chown -R telcosec:telcosec /home/telcosec/.config/wireshark
fi

# 6. Terminator — default terminal, 5-split layout, 5 profiles
echo "Configuring Terminator as default terminal..."
sudo update-alternatives --set x-terminal-emulator /usr/bin/terminator 2>/dev/null || true
# Add TERMINAL env var for scripts that check $TERMINAL
grep -q '^TERMINAL=' /etc/environment 2>/dev/null || echo 'TERMINAL=terminator' | sudo tee -a /etc/environment

# Configure XFCE preferred applications to use Terminator and Firefox by default
sudo mkdir -p /etc/skel/.config/xfce4/
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/helpers.rc
WebBrowser=firefox
MailReader=debian-sensible-mime
TerminalEmulator=terminator
EOF

sudo mkdir -p /etc/skel/.config/terminator
cat << 'TERMEOF' | sudo tee /etc/skel/.config/terminator/config
[global_config]
  title_use_system_font = False
  title_font = IBM Plex Mono Medium 9
  suppress_multiple_term_dialog = True

[keybindings]

[profiles]
  [[default]]
    background_darkness = 0.95
    background_type = transparent
    cursor_color = "#e2e8f0"
    cursor_blink = True
    font = IBM Plex Mono 11
    foreground_color = "#cbd5e1"
    background_color = "#0c0f16"
    palette = "#0c0f16:#ef4444:#10b981:#f59e0b:#3b82f6:#8b5cf6:#06b6d4:#cbd5e1:#475569:#f87171:#34d399:#fbbf24:#60a5fa:#a78bfa:#67e8f9:#ffffff"
    use_system_font = False
    scrollback_lines = 5000
    show_titlebar = True
    title_transmit_fg_color = "#e2e8f0"
    title_transmit_bg_color = "#181f30"
    title_receive_fg_color = "#888888"
    title_receive_bg_color = "#0a0a0a"
    title_inactive_fg_color = "#555555"
    title_inactive_bg_color = "#0a0a0a"
  [[monitor]]
    background_darkness = 0.95
    background_type = transparent
    cursor_color = "#38bdf8"
    font = IBM Plex Mono 11
    foreground_color = "#e0f2fe"
    background_color = "#08101a"
    palette = "#08101a:#e11d48:#0d9488:#22d3ee:#0891b2:#6366f1:#38bdf8:#94a3b8:#334155:#fda4af:#2dd4bf:#67e8f9:#60a5fa:#a5b4fc:#7dd3fc:#ffffff"
    use_system_font = False
    scrollback_lines = 10000
    title_transmit_fg_color = "#38bdf8"
    title_transmit_bg_color = "#0c1d2e"
  [[analysis]]
    background_darkness = 0.95
    background_type = transparent
    cursor_color = "#34d399"
    font = IBM Plex Mono 11
    foreground_color = "#d1fae5"
    background_color = "#05120a"
    palette = "#05120a:#dc2626:#10b981:#34d399:#047857:#84cc16:#a7f3d0:#94a3b8:#334155:#f87171:#4ade80:#6ee7b7:#059669:#a3e635:#d1fae5:#ffffff"
    use_system_font = False
    scrollback_lines = 10000
    title_transmit_fg_color = "#34d399"
    title_transmit_bg_color = "#062016"
  [[network]]
    background_darkness = 0.95
    background_type = transparent
    cursor_color = "#fb7185"
    font = IBM Plex Mono 11
    foreground_color = "#ffe4e6"
    background_color = "#16070a"
    palette = "#16070a:#ef4444:#ea580c:#f43f5e:#be123c:#d946ef:#fda4af:#cbd5e1:#475569:#fca5a5:#ff7849:#fecdd3:#e11d48:#f472b6:#ffe4e6:#ffffff"
    use_system_font = False
    scrollback_lines = 10000
    title_transmit_fg_color = "#fb7185"
    title_transmit_bg_color = "#2e0f15"
  [[console]]
    background_darkness = 0.95
    background_type = transparent
    cursor_color = "#38bdf8"
    font = IBM Plex Mono 11
    foreground_color = "#cbd5e1"
    background_color = "#090d16"
    palette = "#090d16:#ef4444:#10b981:#f59e0b:#3b82f6:#8b5cf6:#06b6d4:#cbd5e1:#475569:#f87171:#34d399:#fbbf24:#60a5fa:#a78bfa:#67e8f9:#ffffff"
    use_system_font = False
    scrollback_lines = 5000
    show_titlebar = True
    title_transmit_fg_color = "#cbd5e1"
    title_transmit_bg_color = "#181f30"

[layouts]
  [[default]]
    [[[window0]]]
      type = Window
      parent = ""
      title = TelcoSec Terminal
      size = 1600, 900
    [[[child1]]]
      type = HPaned
      parent = window0
      ratio = 0.5
    [[[child2]]]
      type = VPaned
      parent = child1
      ratio = 0.45
    [[[terminal5]]]
      type = Terminal
      parent = child2
      profile = console
      title = [5] Local Console
    [[[child4]]]
      type = VPaned
      parent = child2
      ratio = 0.5
    [[[terminal1]]]
      type = Terminal
      parent = child4
      profile = default
      command = tmux new-session -A -s general
      title = [1] General
    [[[terminal2]]]
      type = Terminal
      parent = child4
      profile = monitor
      command = tmux new-session -A -s monitor
      title = [2] Monitor
    [[[child3]]]
      type = VPaned
      parent = child1
      ratio = 0.5
    [[[terminal3]]]
      type = Terminal
      parent = child3
      profile = analysis
      command = tmux new-session -A -s analysis
      title = [3] Analysis
    [[[terminal4]]]
      type = Terminal
      parent = child3
      profile = network
      command = tmux new-session -A -s network
      title = [4] Network

[plugins]
TERMEOF

# Apply Terminator config to telcosec home
if [ -d /home/telcosec ]; then
  sudo mkdir -p /home/telcosec/.config/terminator
  sudo cp /etc/skel/.config/terminator/config /home/telcosec/.config/terminator/config
  sudo chown -R telcosec:telcosec /home/telcosec/.config/terminator
fi

# 7. GNOME Security & Privacy Hardening
echo "Applying GNOME security hardening..."
sudo mkdir -p /etc/dconf/db/local.d

cat << 'EOF' | sudo tee /etc/dconf/db/local.d/03-telcosec-security
# ── Privacy ──────────────────────────────────────────────────────────────────
[org/gnome/desktop/privacy]
report-technical-problems=false
send-software-usage-stats=false
remove-old-trash-files=false
remove-old-temp-files=false
recent-files-max-age=-1

# ── Location services ─────────────────────────────────────────────────────────
[org/gnome/system/location]
enabled=false

# ── Software updates: never distract researchers with update banners ──────────
[org/gnome/software]
allow-updates=false
download-updates=false
download-updates-notify=false

# ── Media handling: no auto-mount ─────────────────────────────────────────────
# Researchers plug in SDR hardware, SIM readers, and suspect devices;
# auto-mount creates accidental write access to forensic evidence.
[org/gnome/desktop/media-handling]
automount=false
automount-open=false
autorun-never=true

# ── Remote desktop: disabled by default ──────────────────────────────────────
[org/gnome/desktop/remote-desktop/rdp]
enable=false

[org/gnome/desktop/remote-desktop/vnc]
enable=false

# ── Sharing: all off by default ───────────────────────────────────────────────
[org/gnome/desktop/sharing]
enabled=false

# ── Notifications: no lock-screen previews ───────────────────────────────────
[org/gnome/desktop/notifications]
show-in-lock-screen=false

# ── Nautilus security posture ─────────────────────────────────────────────────
[org/gnome/nautilus/preferences]
executable-text-activation='ask'
show-hidden-files=true
show-delete-permanently=true

[org/gnome/nautilus/list-view]
use-tree-view=true
default-zoom-level='standard'

# ── Search providers: local only, no external cloud ───────────────────────────
[org/gnome/desktop/search-providers]
disable-external=true
EOF

# Disable Ubuntu crash reporter — no data should leave the research environment
sudo systemctl disable apport 2>/dev/null || true
sudo systemctl mask apport 2>/dev/null || true
sudo rm -f /etc/apport/crashdb.conf 2>/dev/null || true

# 8. TelcoSec Design — Yaru-teal-dark + Papirus-Dark + GNOME Shell extensions
echo "Applying TelcoSec design configuration..."
cat << 'EOF' | sudo tee /etc/dconf/db/local.d/04-telcosec-design
# ── GTK theme: Yaru teal dark — matches TelcoSec teal (#00FFD5) brand color ─
[org/gnome/desktop/interface]
gtk-theme='Yaru-teal-dark'
icon-theme='Papirus-Dark'
cursor-theme='Yaru'
document-font-name='Sans 10'
font-name='Ubuntu 10'
monospace-font-name='IBM Plex Mono 11'
color-scheme='prefer-dark'
accent-color='teal'
clock-show-date=true
clock-show-weekday=true
clock-show-seconds=false
clock-format='24h'
enable-hot-corners=true
show-battery-percentage=true

# ── GNOME Shell extensions to enable ─────────────────────────────────────────
# apps-menu: traditional "Applications" dropdown in top bar reading
#   /etc/xdg/menus/gnome-applications.menu — telecom categories appear here.
# places-status-indicator: quick "Places" dropdown for bookmarks and mounts.
# window-list: classic taskbar at bottom showing open windows.
# appindicatorsupport: system tray icons (Wireshark, nm-applet, etc.).
[org/gnome/shell]
disable-user-extensions=false
enabled-extensions=['apps-menu@gnome-shell-extensions.gcampax.github.com', 'places-status-indicator@gnome-shell-extensions.gcampax.github.com', 'window-list@gnome-shell-extensions.gcampax.github.com', 'ubuntu-appindicators@ubuntu.com']
favorite-apps=['org.gnome.Terminal.desktop', 'firefox.desktop', 'org.wireshark.Wireshark.desktop', 'org.gnome.Nautilus.desktop', 'gnuradio-companion.desktop', 'gqrx.desktop', 'open5gs-start.desktop', 'wireshark-mon.desktop']

# ── Window list (bottom taskbar) behavior ─────────────────────────────────────
[org/gnome/shell/extensions/window-list]
grouping-mode='auto'
show-on-all-monitors=true

# ── Workspace behavior ────────────────────────────────────────────────────────
[org/gnome/mutter]
workspaces-only-on-primary=true
edge-tiling=true

[org/gnome/shell/overrides]
dynamic-workspaces=false

# ── Text editor defaults ──────────────────────────────────────────────────────
[org/gnome/TextEditor]
use-system-font=false
custom-font='IBM Plex Mono 11'
show-line-numbers=true
show-map=true
indent-style='space'
tab-width=uint32 4
EOF

# Nautilus bookmarks — quick access to TelcoSec research paths
sudo mkdir -p /etc/skel/.config/gtk-3.0
cat << 'EOF' | sudo tee /etc/skel/.config/gtk-3.0/bookmarks
file:///usr/share/wordlists/telecom Telecom Wordlists
file:///opt/telcosec TelcoSec Tools
file:///usr/share/doc/telcosec TelcoSec Docs
EOF
if [ -d /home/telcosec ]; then
    sudo mkdir -p /home/telcosec/.config/gtk-3.0
    sudo cp /etc/skel/.config/gtk-3.0/bookmarks /home/telcosec/.config/gtk-3.0/bookmarks
    sudo chown -R telcosec:telcosec /home/telcosec/.config/gtk-3.0
fi

# 5. GDM3 Login Screen Branding
echo "Branding GDM3 login screen..."
sudo mkdir -p /etc/dconf/db/gdm.d/locks
sudo mkdir -p /etc/dconf/profile

# GDM dconf profile tells the login screen which databases to load
cat << 'EOF' | sudo tee /etc/dconf/profile/gdm
user-db:user
system-db:gdm
EOF

# Login screen settings: TelcoSec wallpaper, dark theme, security banner, no user list
cat << 'EOF' | sudo tee /etc/dconf/db/gdm.d/00-telcosec-login
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/telcosec/wallpaper.png'
picture-uri-dark='file:///usr/share/backgrounds/telcosec/wallpaper.png'
picture-options='scaled'
color-shading-type='solid'
primary-color='#0A0E18'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/telcosec/wallpaper.png'
color-shading-type='solid'
primary-color='#0A0E18'

[org/gnome/login-screen]
logo='/usr/share/backgrounds/telcosec/logo.png'
disable-user-list=true
banner-message-enable=true
banner-message-text='TelcoSec Chisel — Telecom Security Research Platform\nDefault credentials: telcosec / telcosec'

[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='Yaru-teal-dark'
icon-theme='Papirus-Dark'
clock-show-date=true
clock-format='24h'
EOF

# Lock GDM background so extensions cannot override it
cat << 'EOF' | sudo tee /etc/dconf/db/gdm.d/locks/00-telcosec
/org/gnome/desktop/background/picture-uri
/org/gnome/desktop/background/picture-options
/org/gnome/login-screen/disable-user-list
/org/gnome/login-screen/banner-message-enable
/org/gnome/login-screen/banner-message-text
EOF

# Compile dconf database (must run after all local.d/ keyfiles are written)
sudo dconf update

# Autostart Terminator with 4-split layout on desktop login
sudo mkdir -p /etc/xdg/autostart
cat << 'EOF' | sudo tee /etc/xdg/autostart/telcosec-terminal.desktop
[Desktop Entry]
Type=Application
Name=TelcoSec Terminal
Comment=Launch Terminator with 4-pane layout on login
Exec=terminator --layout=default
Terminal=false
Categories=System;TerminalEmulator;
X-GNOME-Autostart-enabled=true
EOF

# Cleanup deferred to build-iso.sh central cleanup phase

