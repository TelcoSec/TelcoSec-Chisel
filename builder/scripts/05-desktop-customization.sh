#!/bin/bash
set -e

echo "=== Customizing Desktop Environment ==="

# 1. Custom Wallpaper & LightDM Login Background
echo "Setting up branding directories..."
sudo mkdir -p /usr/share/backgrounds/telcosec
# Uncomment and replace with actual branding asset URLs when available:
# sudo wget -qO /usr/share/backgrounds/telcosec/wallpaper.png https://example.com/telcosec-wallpaper.png
# sudo wget -qO /usr/share/backgrounds/telcosec/logo.png https://example.com/telcosec-logo.png

# Configure LightDM to use the custom background
sudo mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d/
cat << 'EOF' | sudo tee /etc/lightdm/lightdm-gtk-greeter.conf.d/99_telcosec.conf
[greeter]
background = /usr/share/backgrounds/telcosec/wallpaper.png
theme-name = Adwaita-dark
icon-theme-name = gnome
font-name = Sans 11
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

# 3. Custom Bash Prompt (PS1)
echo "Configuring Global Bash Prompt..."
cat << 'EOF' | sudo tee /etc/profile.d/telcosec_prompt.sh
# TelcoSec Custom Bash Prompt
export PS1="\[\e[36;1m\][TelcoSec]\[\e[m\] \[\e[32;1m\]\u@\h\[\e[m\]:\[\e[34;1m\]\w\[\e[m\]\$ "
EOF
sudo chmod +x /etc/profile.d/telcosec_prompt.sh

# Configure LightDM auto-login (optional, uncomment if needed)
# sudo mkdir -p /etc/lightdm/lightdm.conf.d
# echo -e "[Seat:*]\nautologin-user=telcosec\nautologin-user-timeout=0" | sudo tee /etc/lightdm/lightdm.conf.d/autologin.conf

# 4. Deploy Local Documentation & Configure Firefox Policies
echo "Deploying local documentation..."
sudo mkdir -p /usr/share/doc/telcosec/
if [ -d /tmp/docs ]; then
  sudo cp -rf /tmp/docs/. /usr/share/doc/telcosec/
  sudo chmod 644 /usr/share/doc/telcosec/index.html
fi

echo "Configuring Firefox enterprise policies..."
sudo mkdir -p /etc/firefox/policies/
cat << 'EOF' | sudo tee /etc/firefox/policies/policies.json
{
  "policies": {
    "DisableAppUpdate": true,
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
        "URL": "https://academy.telcosec.net/",
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

# Clean up
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /tmp/*

