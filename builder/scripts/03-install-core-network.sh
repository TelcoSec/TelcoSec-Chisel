#!/bin/bash
set -e

echo "=== Installing Core Network Tools ==="

# Add Open5GS PPA
sudo add-apt-repository -y ppa:open5gs/latest
sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  srsran

# Disable services from starting automatically

