#!/bin/bash
set -e

# Install rkdeveloptool from source
# This script automates the process of building rkdeveloptool.

echo "=== Installing Dependencies ==="

if command -v pacman &> /dev/null; then
    echo "Detected Arch Linux"
    sudo pacman -S --needed --noconfirm \
        base-devel \
        git \
        libusb \
        autoconf \
        automake \
        pkg-config \
        make \
        gcc
elif command -v apt-get &> /dev/null; then
    echo "Detected Debian/Ubuntu"
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        git \
        libusb-1.0-0-dev \
        autoconf \
        automake \
        pkg-config \
        make \
        gcc
else
    echo "Unsupported package manager. Please install dependencies manually:"
    echo "libusb-1.0, autoconf, automake, pkg-config, make, gcc"
fi

echo "=== Cloning rkdeveloptool Repository ==="
if [ -d "rkdeveloptool" ]; then
    rm -rf rkdeveloptool
fi
git clone https://github.com/rockchip-linux/rkdeveloptool.git
cd rkdeveloptool

echo "=== Building rkdeveloptool ==="
autoreconf -i
./configure
make -j$(nproc)

echo "=== Installing rkdeveloptool ==="
sudo make install

echo "=== Verifying Installation ==="
rkdeveloptool --version

echo "=== Cleanup ==="
cd ..
rm -rf rkdeveloptool

echo "✓ rkdeveloptool installed successfully!"
