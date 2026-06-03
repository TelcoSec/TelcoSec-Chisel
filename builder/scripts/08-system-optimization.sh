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

# 4. Wireshark Dissector Profile & Plugins
echo "Configuring default Wireshark telecom profile, custom Lua plugins, and OpenAPI schemas..."
sudo mkdir -p /etc/skel/.config/wireshark/
if [ -f /tmp/wireshark/preferences ]; then
  # For future users created via Calamares
  sudo cp /tmp/wireshark/preferences /etc/skel/.config/wireshark/preferences
  # For the pre-created live user
  sudo mkdir -p /home/telcosec/.config/wireshark/
  sudo cp /tmp/wireshark/preferences /home/telcosec/.config/wireshark/preferences
  sudo chown -R telcosec:telcosec /home/telcosec/.config
fi

# Deploy custom Lua plugins system-wide
sudo mkdir -p /usr/share/wireshark/plugins/
if [ -d /tmp/wireshark/plugins ]; then
  sudo cp -rf /tmp/wireshark/plugins/. /usr/share/wireshark/plugins/
  sudo chmod 644 /usr/share/wireshark/plugins/*.lua || true
fi

# Create directory for 5G SBI OpenAPI YAML definitions
sudo mkdir -p /etc/wireshark/openapi/
sudo chmod 755 /etc/wireshark/openapi/

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

# 6. SCTP Stack Optimizations
echo "Deploying SCTP module loading and sysctl tuning..."
# Enable auto-loading of the sctp kernel module at boot
if [ -f /etc/modules ]; then
  if ! grep -q "^sctp$" /etc/modules 2>/dev/null; then
    echo "sctp" | sudo tee -a /etc/modules
  fi
else
  echo "sctp" | sudo tee /etc/modules
fi

# Deploy kernel sysctl settings
sudo mkdir -p /etc/sysctl.d/
if [ -f /tmp/security/99-sctp-tuning.conf ]; then
  sudo cp /tmp/security/99-sctp-tuning.conf /etc/sysctl.d/
  sudo chmod 644 /etc/sysctl.d/99-sctp-tuning.conf
fi

# Attempt to load module and apply sysctl settings (ignores failures in chroot)
sudo modprobe sctp || true
if command -v sysctl &> /dev/null; then
  sudo sysctl --system || true
fi

echo "=== System Optimizations Applied Successfully ==="

