#!/bin/bash
set -e

echo "=== Running TelcoSec Professional System Optimizations ==="

# 1. Hardware Access & Udev Rules
echo "Deploying hardware udev rules..."
sudo mkdir -p /etc/udev/rules.d/
if [ -f /tmp/udev/50-telcosec-hw.rules ]; then
  sudo cp /tmp/udev/50-telcosec-hw.rules /etc/udev/rules.d/
  sudo chmod 644 /etc/udev/rules.d/50-telcosec-hw.rules
fi

# 2. PAM Real-time Scheduling Priority Limits
echo "Deploying real-time limits and configuring groups..."
sudo mkdir -p /etc/security/limits.d/
if [ -f /tmp/security/99-realtime.conf ]; then
  sudo cp /tmp/security/99-realtime.conf /etc/security/limits.d/
  sudo chmod 644 /etc/security/limits.d/99-realtime.conf
fi
# Add the realtime group and add our users to it
sudo groupadd -r realtime || true
sudo usermod -aG realtime telcosec || true

# 3. Custom Desktop Menu & Tool Categories
echo "Deploying custom XFCE tool menus and categories..."
sudo mkdir -p /etc/xdg/menus/applications-merged/
if [ -f /tmp/menu/telcosec.menu ]; then
  sudo cp /tmp/menu/telcosec.menu /etc/xdg/menus/applications-merged/
fi

sudo mkdir -p /usr/share/desktop-directories/
if [ -d /tmp/menu/directories ]; then
  sudo cp -rf /tmp/menu/directories/. /usr/share/desktop-directories/
fi

sudo mkdir -p /usr/share/applications/
if [ -d /tmp/menu/applications ]; then
  sudo cp -rf /tmp/menu/applications/. /usr/share/applications/
  sudo chmod 644 /usr/share/applications/*.desktop || true
  sudo chmod +x /usr/share/applications/*.desktop || true
fi

# 4. Wireshark Dissector Profile
echo "Configuring default Wireshark telecom profile..."
sudo mkdir -p /etc/skel/.config/wireshark/
if [ -f /tmp/wireshark/preferences ]; then
  # For future users created via Calamares
  sudo cp /tmp/wireshark/preferences /etc/skel/.config/wireshark/preferences
  # For the pre-created live user
  sudo mkdir -p /home/telcosec/.config/wireshark/
  sudo cp /tmp/wireshark/preferences /home/telcosec/.config/wireshark/preferences
  sudo chown -R telcosec:telcosec /home/telcosec/.config
fi

# 5. Boot Theme (GRUB Customization)
echo "Deploying custom boot styling..."
sudo mkdir -p /etc/default/grub.d/
if [ -f /tmp/boot/grub-theme.conf ]; then
  sudo cp /tmp/boot/grub-theme.conf /etc/default/grub.d/99-telcosec.cfg
  sudo chmod 644 /etc/default/grub.d/99-telcosec.cfg
fi

# Deploy the logo background to backgrounds directory for GRUB access
sudo mkdir -p /usr/share/backgrounds/telcosec/
if [ -f /tmp/calamares-config/branding/telcosec/logo.png ]; then
  sudo cp /tmp/calamares-config/branding/telcosec/logo.png /usr/share/backgrounds/telcosec/logo.png
  # Also set as greeter greeter-background if not already done
  sudo cp /tmp/calamares-config/branding/telcosec/logo.png /usr/share/backgrounds/telcosec/wallpaper.png || true
  sudo chmod 644 /usr/share/backgrounds/telcosec/*
fi

# Refresh GRUB configurations inside the chroot
if command -v update-grub &> /dev/null; then
  sudo update-grub || true
fi

echo "=== System Optimizations Applied Successfully ==="
