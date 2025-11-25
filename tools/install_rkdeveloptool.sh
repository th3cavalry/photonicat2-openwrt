#!/bin/bash
set -e

# Install rkdeveloptool from source on Arch Linux
# This script automates the process of building rkdeveloptool since it's not in the standard repositories.

echo "=== Installing Dependencies ==="
sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    libusb \
    autoconf \
    automake \
    pkg-config \
    make \
    gcc

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
