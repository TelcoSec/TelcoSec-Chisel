#!/bin/bash
set -e

echo "=== Updating System ==="
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "=== Installing prerequisites ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  software-properties-common curl wget

echo "=== Configuring Native Firefox PPA ==="
sudo add-apt-repository -y ppa:mozillateam/ppa
cat << 'EOF' | sudo tee /etc/apt/preferences.d/99mozillateam
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
sudo apt-get update

echo "=== Installing live-boot infrastructure (must precede kernel) ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  casper initramfs-tools

echo "=== Installing kernel ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  linux-image-generic

echo "=== Ensuring initrd is generated ==="
KVER=$(ls /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|/boot/vmlinuz-||')
if [ -n "$KVER" ] && [ ! -f "/boot/initrd.img-$KVER" ]; then
  update-initramfs -c -k "$KVER"
fi

echo "=== Installing desktop environment and tools ==="
# Using XFCE for a lightweight, customizable desktop similar to Kali Linux
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  xfce4 xfce4-goodies lightdm \
  network-manager-gnome \
  terminator firefox \
  git vim nano htop \
  build-essential cmake pkg-config \
  ufw openssh-server \
  docker.io docker-compose-v2



echo "=== Configuring NetworkManager ==="
sudo systemctl enable NetworkManager
sudo systemctl enable lightdm

echo "=== Creating Default User ==="
# Pre-create telcosec group and user (UID/GID 1000) for build compatibility
sudo groupadd -g 1000 telcosec || true
sudo useradd -m -s /bin/bash -u 1000 -g telcosec telcosec || true
echo "telcosec:telcosec" | sudo chpasswd
sudo usermod -aG sudo,dialout,plugdev,audio,video,docker telcosec || true

