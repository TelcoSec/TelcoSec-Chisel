#!/bin/bash
set -e

echo "=== Installing Conda & Compiling SDR Drivers from Source ==="

# 1. Install Build Dependencies
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential cmake git wget libusb-1.0-0-dev pkg-config

# 2. Install Miniconda
echo "Installing Miniconda..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p /opt/telcosec/miniconda
rm /tmp/miniconda.sh

# Make Conda available to all users
cat << 'EOF' | sudo tee /etc/profile.d/conda.sh
export PATH="/opt/telcosec/miniconda/bin:$PATH"
. /opt/telcosec/miniconda/etc/profile.d/conda.sh
EOF

source /opt/telcosec/miniconda/etc/profile.d/conda.sh

# 3. Create SDR Virtual Environment
echo "Creating SDR Conda Environment..."
conda create -y -n telcosec-sdr python=3.11 cmake ninja pkg-config boost-cpp swig pybind11
conda activate telcosec-sdr

# 4. Compile SoapySDR from Source
echo "Compiling SoapySDR..."
mkdir -p /opt/telcosec/src && cd /opt/telcosec/src
git clone https://github.com/pothosware/SoapySDR.git
cd SoapySDR
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make -j$(nproc)
make install

# 5. Compile HackRF from Source
echo "Compiling HackRF..."
cd /opt/telcosec/src
git clone https://github.com/greatscottgadgets/hackrf.git
cd hackrf/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make -j$(nproc)
make install

# 6. Compile UHD (USRP) from Source
echo "Compiling UHD..."
cd /opt/telcosec/src
git clone https://github.com/EttusResearch/uhd.git
cd uhd/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF ..
make -j$(nproc)
make install
uhd_images_downloader

# Set permissions
sudo chown -R telcosec:telcosec /opt/telcosec
