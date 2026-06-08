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
export USERFULLNAME="TelcoSec"
export HOST=telcosec
export BUILD_SYSTEM=TelcoSec-Chisel
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

# 3. Custom Bash Prompt (PS1)
echo "Configuring Global Bash Prompt..."
cat << 'EOF' | sudo tee /etc/profile.d/telcosec_prompt.sh
# TelcoSec Custom Bash Prompt
export PS1="\[\e[36;1m\][TelcoSec]\[\e[m\] \[\e[32;1m\]\u@\h\[\e[m\]:\[\e[34;1m\]\w\[\e[m\]\$ "
EOF
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
        "URL": "https://community.telcosec.net/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Academy",
        "URL": "https://app.telcosec.net/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Blog",
        "URL": "https://blog.telcosec.net/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Tools",
        "URL": "https://tools.telcosec.net/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec Calculators",
        "URL": "https://calculators.telcosec.net/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec CTF Portal",
        "URL": "https://ctf.telcosec.net/",
        "Placement": "toolbar"
      },
      {
        "Title": "TelcoSec 3GPP Tracker",
        "URL": "https://3gpp.telcosec.net/",
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

# Cleanup deferred to build-iso.sh central cleanup phase

