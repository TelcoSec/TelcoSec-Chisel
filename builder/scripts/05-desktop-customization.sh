#!/bin/bash
set -e

echo "=== Customizing Desktop Environment ==="

# 1. Custom Wallpaper & LightDM Login Background
echo "Setting up branding directories..."
sudo mkdir -p /usr/share/backgrounds/telcosec

# Configure LightDM greeter with matching Greybird-dark styling and logo background
sudo mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d/
cat << 'EOF' | sudo tee /etc/lightdm/lightdm-gtk-greeter.conf.d/99_telcosec.conf
[greeter]
theme-name = Greybird-dark
icon-theme-name = elementary-xfce-darkest
font-name = Sans 11
background = /usr/share/backgrounds/telcosec/wallpaper.png
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

# GTK and icon themes (Greybird-dark and elementary-xfce-darkest)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Greybird-dark"/>
    <property name="IconThemeName" type="string" value="elementary-xfce-darkest"/>
    <property name="DoubleClickTime" type="int" value="400"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Sans 10"/>
    <property name="MonospaceFontName" type="string" value="IBM Plex Mono 10"/>
    <property name="ButtonImages" type="bool" value="true"/>
    <property name="MenuImages" type="bool" value="true"/>
    <property name="CursorThemeName" type="string" value="Adwaita"/>
    <property name="CursorThemeSize" type="int" value="24"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
</channel>
EOF

# Window manager settings (theme, fonts, layout)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Greybird-dark"/>
    <property name="title_font" type="string" value="Sans Bold 9"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="button_layout" type="string" value="O|HMC"/>
    <property name="click_to_focus" type="bool" value="true"/>
    <property name="double_click_action" type="string" value="maximize"/>
    <property name="workspace_count" type="int" value="4"/>
    <property name="show_dirty_workspaces" type="bool" value="true"/>
  </property>
</channel>
EOF

# Desktop settings (wallpaper and clean desktop icons)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string" value="/usr/share/backgrounds/telcosec/wallpaper.png"/>
        <property name="image-style" type="int" value="5"/>
      </property>
    </property>
  </property>
  <property name="desktop-icons" type="empty">
    <property name="style" type="int" value="2"/>
    <property name="icon-size" type="uint" value="48"/>
    <property name="file-icons" type="empty">
      <property name="show-home" type="bool" value="false"/>
      <property name="show-filesystem" type="bool" value="false"/>
      <property name="show-trash" type="bool" value="false"/>
      <property name="show-removable" type="bool" value="true"/>
    </property>
  </property>
</channel>
EOF

# Panel settings (set up Whisker Menu as default application menu)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <value type="int" value="2"/>
    <property name="dark-mode" type="bool" value="true"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="icon-size" type="uint" value="16"/>
      <property name="size" type="uint" value="26"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="8"/>
        <value type="int" value="9"/>
        <value type="int" value="10"/>
        <value type="int" value="11"/>
        <value type="int" value="12"/>
        <value type="int" value="13"/>
        <value type="int" value="14"/>
      </property>
    </property>
    <property name="panel-2" type="empty">
      <property name="autohide-behavior" type="uint" value="1"/>
      <property name="position" type="string" value="p=10;x=0;y=0"/>
      <property name="length" type="uint" value="1"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="48"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="15"/>
        <value type="int" value="16"/>
        <value type="int" value="17"/>
        <value type="int" value="18"/>
        <value type="int" value="19"/>
        <value type="int" value="20"/>
        <value type="int" value="21"/>
        <value type="int" value="22"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="grouping" type="uint" value="1"/>
      <property name="flat-buttons" type="bool" value="true"/>
      <property name="show-handle" type="bool" value="false"/>
      <property name="sort-order" type="uint" value="4"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-5" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-6" type="string" value="systray">
      <property name="square-icons" type="bool" value="true"/>
    </property>
    <property name="plugin-8" type="string" value="pulseaudio">
      <property name="enable-keyboard-shortcuts" type="bool" value="true"/>
      <property name="show-notifications" type="bool" value="true"/>
    </property>
    <property name="plugin-9" type="string" value="power-manager-plugin"/>
    <property name="plugin-10" type="string" value="notification-plugin"/>
    <property name="plugin-11" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-12" type="string" value="clock"/>
    <property name="plugin-13" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-14" type="string" value="actions"/>
    <property name="plugin-15" type="string" value="showdesktop"/>
    <property name="plugin-16" type="string" value="separator"/>
    <property name="plugin-17" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="terminator.desktop"/>
      </property>
    </property>
    <property name="plugin-18" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="xfce4-file-manager.desktop"/>
      </property>
    </property>
    <property name="plugin-19" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="xfce4-web-browser.desktop"/>
      </property>
    </property>
    <property name="plugin-20" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="xfce4-appfinder.desktop"/>
      </property>
    </property>
    <property name="plugin-21" type="string" value="separator"/>
    <property name="plugin-22" type="string" value="directorymenu"/>
  </property>
</channel>
EOF

# Whisker Menu configurations (Favorites + Title settings)
sudo mkdir -p /etc/skel/.config/xfce4/panel/
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/panel/whiskermenu-1.rc
favorites=firefox.desktop,terminator.desktop,wireshark.desktop,thunar.desktop
button-title=Applications
button-icon=org.xfce.panel.applicationsmenu
show-button-title=false
show-button-icon=true
show-generic-names=true
show-category-names=true
show-description-tooltip=true
show-menu-tooltips=true
position-search-alternate=false
position-commands-alternate=false
position-categories-alternate=false
stay-on-focus-out=false
profile-shape=0
search-actions=true
EOF

# Power Manager settings (No screen blanking, sleep, or lock in live session)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-power-manager" version="1.0">
  <property name="xfce4-power-manager" type="empty">
    <property name="power-button-action" type="uint" value="4"/>
    <property name="inactivity-on-ac" type="uint" value="0"/>
    <property name="dpms-enabled" type="bool" value="false"/>
    <property name="blank-on-ac" type="int" value="0"/>
    <property name="dpms-on-ac-sleep" type="uint" value="0"/>
    <property name="dpms-on-ac-off" type="uint" value="0"/>
    <property name="lock-screen-suspend-comment" type="bool" value="false"/>
  </property>
</channel>
EOF

# Screensaver settings (Disabled screensaver & automatic locking)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-screensaver" version="1.0">
  <property name="mode" type="int" value="0"/>
  <property name="saver" type="empty">
    <property name="enabled" type="bool" value="false"/>
  </property>
  <property name="lock" type="empty">
    <property name="enabled" type="bool" value="false"/>
  </property>
</channel>
EOF

# Keyboard shortcuts (Add Super+Arrows for tiling, Super+Space for Whisker Menu)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-keyboard-shortcuts" version="1.0">
  <property name="commands" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;space" type="string" value="xfce4-popup-whiskermenu"/>
      <property name="&lt;Primary&gt;Escape" type="string" value="xfce4-popup-whiskermenu"/>
      <property name="override" type="bool" value="true"/>
    </property>
  </property>
  <property name="xfwm4" type="empty">
    <property name="custom" type="empty">
      <property name="&lt;Super&gt;Left" type="string" value="tile_left_key"/>
      <property name="&lt;Super&gt;Right" type="string" value="tile_right_key"/>
      <property name="&lt;Super&gt;Up" type="string" value="tile_up_key"/>
      <property name="&lt;Super&gt;Down" type="string" value="tile_down_key"/>
      <property name="override" type="bool" value="true"/>
    </property>
  </property>
</channel>
EOF

# Thunar productivity options (Show hidden files, detailed view, folders first, full path in title)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/thunar.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="thunar" version="1.0">
  <property name="last-view" type="string" value="ThunarDetailsView"/>
  <property name="last-show-hidden" type="bool" value="true"/>
  <property name="misc-folders-first" type="bool" value="true"/>
  <property name="misc-full-path-in-title" type="bool" value="true"/>
</channel>
EOF

# Notification styling (Dark theme & Bottom-Right positioning)
cat << 'EOF' | sudo tee /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-notifyd.xml
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-notifyd" version="1.0">
  <property name="theme" type="string" value="Greybird-dark"/>
  <property name="initial-opacity" type="double" value="0.900000"/>
  <property name="notify-location" type="uint" value="3"/>
</channel>
EOF

# Apply the skeleton to the pre-created telcosec home directory.
# Force copy (-f) to apply settings updates on resume builds.
if [ -d /home/telcosec ]; then
  sudo cp -rf /etc/skel/.config /home/telcosec/
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

