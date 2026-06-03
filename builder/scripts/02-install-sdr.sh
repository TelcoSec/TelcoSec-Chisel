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

# Accept Terms of Service for default channels to prevent non-interactive blocks
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || true

# Configure Conda to use conda-forge and avoid Anaconda commercial ToS issues
conda config --add channels conda-forge
conda config --set channel_priority strict
conda config --remove channels defaults || true

# 3. Create SDR Virtual Environment
echo "Creating SDR Conda Environment..."
conda create -y --override-channels -c conda-forge -n telcosec-sdr python=3.11 cmake ninja pkg-config boost-cpp swig pybind11
conda activate telcosec-sdr

# 4. Compile SoapySDR from Source
echo "Compiling SoapySDR..."
mkdir -p /opt/telcosec/src && cd /opt/telcosec/src
git clone --depth 1 https://github.com/pothosware/SoapySDR.git
cd SoapySDR
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make -j$(nproc)
make install

# 5. Compile HackRF from Source
echo "Compiling HackRF..."
cd /opt/telcosec/src
git clone --depth 1 https://github.com/greatscottgadgets/hackrf.git
cd hackrf/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make -j$(nproc)
make install

# 6. Compile UHD (USRP) from Source
echo "Compiling UHD..."
cd /opt/telcosec/src
git clone --depth 1 https://github.com/EttusResearch/uhd.git
cd uhd/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF ..
make -j$(nproc)
make install
uhd_images_downloader

# 7. Install GNU Radio, GQRX, gr-osmosdr, and gr-gsm globally
echo "Installing GNU Radio, Osmocom SDR blocks, GQRX, and gr-gsm globally..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  gnuradio gnuradio-dev gqrx-sdr gr-osmosdr gr-gsm

# 8. Compile and Install Kalibrate-RTL from Source
echo "Compiling and installing Kalibrate-RTL..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  librtlsdr-dev librtlsdr0 libfftw3-double3 libfftw3-dev libfftw3-bin \
  autoconf automake libtool
cd /opt/telcosec/src
git clone --depth 1 https://github.com/steve-m/kalibrate-rtl.git
cd kalibrate-rtl
./bootstrap
./configure
make -j$(nproc)
sudo make install
cd -

# Set permissions
sudo chown -R telcosec:telcosec /opt/telcosec
