#!/bin/bash
set -e

echo "=== Updating System ==="
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "=== Configuring Native Firefox PPA ==="
sudo add-apt-repository -y ppa:mozillateam/ppa
cat << 'EOF' | sudo tee /etc/apt/preferences.d/99mozillateam
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF

# Update package sources with the new PPA
sudo apt-get update

# Using XFCE for a lightweight, customizable desktop similar to Kali Linux
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  linux-image-generic casper \
  xfce4 xfce4-goodies lightdm \
  network-manager-gnome \
  terminator firefox \
  curl wget git vim nano htop \
  build-essential cmake pkg-config software-properties-common



echo "=== Configuring NetworkManager ==="
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

echo "=== Creating Default User ==="
# Pre-create telcosec group and user (UID/GID 1000) for build compatibility
sudo groupadd -g 1000 telcosec || true
sudo useradd -m -s /bin/bash -u 1000 -g telcosec telcosec || true
echo "telcosec:telcosec" | sudo chpasswd
sudo usermod -aG sudo,dialout,plugdev,audio,video telcosec || true

