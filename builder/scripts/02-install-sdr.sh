#!/bin/bash
set -e

echo "=== Installing Conda & Compiling SDR Drivers from Source ==="

# Skip apt operations — handled by 00-install-all-packages.sh
if [ ! -f /tmp/.packages-installed ]; then
  echo "WARNING: Running standalone (packages not pre-installed)"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cmake git wget libusb-1.0-0-dev pkg-config
fi

# 1. Install Miniconda
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

# 2. Create SDR Virtual Environment
echo "Creating SDR Conda Environment..."
conda create -y --override-channels -c conda-forge -n telcosec-sdr python=3.11 cmake ninja pkg-config boost-cpp swig pybind11 libusb mako requests numpy ruamel.yaml setuptools
conda activate telcosec-sdr

# Export compilation environment variables to prefer the Conda environment
export PKG_CONFIG_PATH="$CONDA_PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export CMAKE_PREFIX_PATH="$CONDA_PREFIX"

# 3. Clone all SDR source repos in parallel
echo "Cloning SDR source repositories..."
mkdir -p /opt/telcosec/src
(git clone --depth 1 https://github.com/pothosware/SoapySDR.git /opt/telcosec/src/SoapySDR) &
(git clone --depth 1 https://github.com/greatscottgadgets/hackrf.git /opt/telcosec/src/hackrf) &
(git clone --depth 1 https://github.com/EttusResearch/uhd.git /opt/telcosec/src/uhd) &
(git clone --depth 1 https://github.com/steve-m/kalibrate-rtl.git /opt/telcosec/src/kalibrate-rtl) &
wait
echo "All SDR repos cloned."

# 4. Compile SoapySDR from Source
echo "Compiling SoapySDR..."
cd /opt/telcosec/src/SoapySDR
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make -j$(nproc)
make install

# 5. Compile HackRF from Source
echo "Compiling HackRF..."
cd /opt/telcosec/src/hackrf/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX ..
make -j$(nproc)
make install

# 6. Compile UHD (USRP) from Source
echo "Compiling UHD..."
cd /opt/telcosec/src/uhd/host
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=$CONDA_PREFIX -DENABLE_TESTS=OFF -DENABLE_EXAMPLES=OFF ..
make -j$(nproc)
make install

# Defer uhd_images_downloader to first-run (saves ~1.5 GB ISO space and ~10 min)
echo "Creating UHD images first-run downloader..."
cat << 'FIRSTRUN' | sudo tee /usr/local/bin/uhd-download-images
#!/bin/bash
echo "Downloading UHD FPGA images (~1.5 GB)..."
echo "This only needs to run once after installation."
source /opt/telcosec/miniconda/etc/profile.d/conda.sh
conda activate telcosec-sdr 2>/dev/null || true
uhd_images_downloader
echo "UHD images downloaded successfully."
FIRSTRUN
sudo chmod +x /usr/local/bin/uhd-download-images

# 7. GNU Radio, GQRX, gr-osmosdr, gr-gsm already installed by 00-install-all-packages.sh

# 8. Compile and Install Kalibrate-RTL from Source
echo "Compiling and installing Kalibrate-RTL..."
cd /opt/telcosec/src/kalibrate-rtl
./bootstrap
./configure
make -j$(nproc)
sudo make install
cd -

# Set permissions
sudo chown -R telcosec:telcosec /opt/telcosec
