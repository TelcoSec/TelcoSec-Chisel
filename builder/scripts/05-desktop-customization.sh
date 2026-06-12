#!/bin/bash
set -e

echo "=== Customizing Desktop Environment ==="

# 1. Custom Wallpaper & LightDM Login Background
echo "Setting up branding directories..."
sudo mkdir -p /usr/share/backgrounds/telcosec

# Configure LightDM greeter — no background path so greeter doesn't hang
# if the wallpaper asset is absent
sudo mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d/
cat << 'EOF' | sudo tee /etc/lightdm/lightdm-gtk-greeter.conf.d/99_telcosec.conf
[greeter]
theme-name = Adwaita-dark
icon-theme-name = gnome
font-name = Sans 11
EOF

# Configure LightDM main config: autologin + explicit XFCE session.
# Autologin is the standard approach for a live ISO — it bypasses the PAM
# session-start path that fails when the user's home is freshly populated
# from /etc/skel (race with xfce4-session first-run setup).
sudo mkdir -p /etc/lightdm/lightdm.conf.d
cat << 'EOF' | sudo tee /etc/lightdm/lightdm.conf.d/50-telcosec.conf
[Seat:*]
user-session=xfce
greeter-session=lightdm-gtk-greeter
autologin-user=telcosec
autologin-user-timeout=0
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

# XFCE session skeleton — ensures the user gets a working failsafe desktop
# even before xfce4-session has a chance to write its own config on first run.
echo "Setting up XFCE skeleton configuration..."
sudo mkdir -p /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/

cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="SaveOnExit" type="bool" value="false"/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="5"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfwm4"/>
      </property>
      <property name="Client1_Command" type="array">
        <value type="string" value="xfce4-panel"/>
      </property>
      <property name="Client2_Command" type="array">
        <value type="string" value="Thunar"/>
        <value type="string" value="--daemon"/>
      </property>
      <property name="Client3_Command" type="array">
        <value type="string" value="xfdesktop"/>
      </property>
      <property name="Client4_Command" type="array">
        <value type="string" value="xfce4-screensaver"/>
      </property>
    </property>
  </property>
</channel>
EOF

# Apply the skeleton to the pre-created telcosec home directory so the
# config is present even before casper's first-boot user setup runs.
if [ -d /home/telcosec ]; then
  sudo cp -rn /etc/skel/.config /home/telcosec/
  sudo chown -R telcosec:telcosec /home/telcosec/.config
fi

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

# 3. Custom Rich Bash Prompt
echo "Configuring Global Bash Prompt..."
cat << 'PROMPTEOF' | sudo tee /etc/profile.d/telcosec_prompt.sh
# TelcoSec multi-line rich prompt: user@host | IP | load | date | path | tmux session | mem
__telcosec_ps1() {
  local IP; IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  local LOAD; LOAD=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)
  local MEM; MEM=$(free -m 2>/dev/null | awk '/^Mem:/{printf "%dM/%dM", $3, $2}')
  local DT; DT=$(date '+%Y-%m-%d %H:%M:%S')
  local SESS=""
  [ -n "$TMUX" ] && SESS=$(tmux display-message -p '#S' 2>/dev/null)
  local C='\[\e[38;5;208m\]'   # orange border
  local Y='\[\e[1;33m\]'       # yellow
  local W='\[\e[1;37m\]'       # white
  local G='\[\e[0;32m\]'       # green
  local CY='\[\e[0;36m\]'      # cyan
  local M='\[\e[0;35m\]'       # magenta
  local R='\[\e[0m\]'          # reset
  local BL='\[\e[1;36m\]'      # bright cyan
  PS1="\n${C}┌[${Y}TelcoSec${C}]──[${CY}\u@\h${C}]──[${G}${IP}${C}]──[${M}Load:${LOAD}${C}]──[${Y}${DT}${C}]${R}\n"
  PS1+="${C}├[${W}\w${C}]${SESS:+──[${BL}session:${SESS}${C}]}──[mem:${G}${MEM}${C}]${R}\n"
  PS1+="${C}└─${Y}\$${R} "
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

# 6. Terminator — default terminal, 4-split layout, 4 profiles
echo "Configuring Terminator as default terminal..."
sudo update-alternatives --set x-terminal-emulator /usr/bin/terminator 2>/dev/null || true
# Add TERMINAL env var for scripts that check $TERMINAL
grep -q '^TERMINAL=' /etc/environment 2>/dev/null || echo 'TERMINAL=terminator' | sudo tee -a /etc/environment

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
    cursor_color = "#ffa500"
    cursor_blink = True
    font = IBM Plex Mono 11
    foreground_color = "#ffb000"
    background_color = "#0a0a0a"
    palette = "#000000:#e60000:#00cc44:#ffa500:#0066cc:#990066:#00aacc:#bbbbbb:#555555:#ff4444:#44ff44:#ffcc00:#3399ff:#cc44cc:#33ccdd:#ffffff"
    use_system_font = False
    scrollback_lines = 5000
    show_titlebar = True
    title_transmit_fg_color = "#ffb000"
    title_transmit_bg_color = "#1a0a00"
    title_receive_fg_color = "#888888"
    title_receive_bg_color = "#0a0a0a"
    title_inactive_fg_color = "#555555"
    title_inactive_bg_color = "#0a0a0a"
  [[monitor]]
    background_darkness = 0.97
    background_type = transparent
    cursor_color = "#00ffff"
    font = IBM Plex Mono 11
    foreground_color = "#00e5ff"
    background_color = "#000a12"
    palette = "#000000:#e60000:#00cc44:#ffa500:#0066cc:#990066:#00aacc:#bbbbbb:#555555:#ff4444:#44ff44:#ffcc00:#3399ff:#cc44cc:#33ccdd:#ffffff"
    use_system_font = False
    scrollback_lines = 10000
    title_transmit_fg_color = "#00e5ff"
    title_transmit_bg_color = "#001a2a"
  [[analysis]]
    background_darkness = 0.97
    background_type = transparent
    cursor_color = "#44ff44"
    font = IBM Plex Mono 11
    foreground_color = "#33dd44"
    background_color = "#050a05"
    palette = "#000000:#e60000:#00cc44:#ffa500:#0066cc:#990066:#00aacc:#bbbbbb:#555555:#ff4444:#44ff44:#ffcc00:#3399ff:#cc44cc:#33ccdd:#ffffff"
    use_system_font = False
    scrollback_lines = 10000
    title_transmit_fg_color = "#33dd44"
    title_transmit_bg_color = "#051005"
  [[network]]
    background_darkness = 0.97
    background_type = transparent
    cursor_color = "#ff4444"
    font = IBM Plex Mono 11
    foreground_color = "#ff6644"
    background_color = "#0a0000"
    palette = "#000000:#e60000:#00cc44:#ffa500:#0066cc:#990066:#00aacc:#bbbbbb:#555555:#ff4444:#44ff44:#ffcc00:#3399ff:#cc44cc:#33ccdd:#ffffff"
    use_system_font = False
    scrollback_lines = 10000
    title_transmit_fg_color = "#ff6644"
    title_transmit_bg_color = "#1a0000"

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
      ratio = 0.5
    [[[terminal1]]]
      type = Terminal
      parent = child2
      profile = default
      command = tmux new-session -A -s general
      title = [1] General
    [[[terminal2]]]
      type = Terminal
      parent = child2
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

