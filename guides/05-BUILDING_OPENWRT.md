# Photonicat 2 - Building OpenWrt from Source

Complete guide for compiling a custom OpenWrt image for Photonicat 2 using Vanilla OpenWrt.

> 💡 **Tip**: For a simplified, automated build process, use the `./build.sh` script in the root of this repository. This guide is for users who want to understand the manual build process or customize it further.

## Overview

This guide covers building OpenWrt from source using the official OpenWrt repository ("Vanilla OpenWrt") with minimal patches for Photonicat 2 hardware support.

### Build Requirements

**System**: Linux (Debian/Ubuntu, Arch Linux, or macOS)
**Disk Space**: 50GB+ free space
**RAM**: 8GB+ (16GB+ recommended)
**Time**: 2-4 hours for first build (depends on internet speed)

---

## Prerequisites

### System Requirements

Ensure you have a Linux system. This guide supports Ubuntu 20.04 LTS, Debian 11+, or Arch Linux.

```bash
# Check Linux version
lsb_release -a  # Ubuntu/Debian
cat /etc/os-release  # Any Linux
uname -m  # Should be x86_64 or aarch64
```

### Create Non-Root Build User

⚠️ **CRITICAL**: Do NOT compile as root

```bash
# Create build user
sudo useradd -m -s /bin/bash photonicat-build
sudo usermod -aG sudo photonicat-build

# Switch to build user
su - photonicat-build
```

---

## Step 1: Install Build Dependencies

### Ubuntu/Debian

```bash
# Update system
sudo apt update -y
sudo apt full-upgrade -y

# Install required packages
sudo apt install -y \
  ack antlr3 asciidoc autoconf automake autopoint binutils bison \
  build-essential bzip2 ccache clang cmake cpio curl device-tree-compiler \
  flex gawk gcc-multilib g++-multilib gettext genisoimage git gperf \
  haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev \
  libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev \
  libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
  libssl-dev libtool llvm lrzsz msmtp ninja-build p7zip p7zip-full \
  patch pkgconf python3 python3-pyelftools python3-setuptools \
  qemu-utils rsync scons squashfs-tools subversion swig texinfo \
  uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
```

### Arch Linux

```bash
# Update system
sudo pacman -Syu

# Install required packages
sudo pacman -S --needed \
  base-devel git wget curl unzip vim \
  asciidoc bash bc bison boost bzip2 ccache clang cmake cpio \
  dtc fakeroot flex gawk gcc git glibc gperf help2man intltool \
  lib32-glibc libelf libffi libxslt make msmtp ncurses openssl \
  patch pkgconf python python-pyelftools python-setuptools \
  qemu-base rsync scons squashfs-tools subversion swig texinfo \
  uglify-js unzip upx wget which xmlto xxd zlib

# Note: python-pyelftools and swig are critical and often missed
sudo pacman -S --needed python-pyelftools swig

# Install AUR packages (optional, for additional tools)
# You may use yay or another AUR helper
# yay -S ack antlr3 genisoimage haveged lrzsz ninja p7zip
```

### macOS

```bash
# Install Xcode
xcode-select --install

# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install build tools
brew install coreutils diffutils findutils gawk gnu-getopt gnu-tar grep make ncurses pkg-config wget quilt xz gcc@11

# For Intel Macs
echo 'export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/usr/local/opt/findutils/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/usr/local/opt/gnu-getopt/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/usr/local/opt/grep/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/usr/local/opt/make/libexec/gnubin:$PATH"' >> ~/.bashrc

# For Apple Silicon Macs
echo 'export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/opt/homebrew/opt/gnu-getopt/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"' >> ~/.bashrc
echo 'export PATH="/opt/homebrew/opt/make/libexec/gnubin:$PATH"' >> ~/.bashrc

source ~/.bashrc
bash
```

---

## Step 2: Clone OpenWrt Repository

### Option A: Use Official OpenWrt Repository (Recommended)

```bash
# Create build directory
mkdir -p ~/openwrt-builds
cd ~/openwrt-builds

# Clone official OpenWrt
git clone https://github.com/openwrt/openwrt.git openwrt
cd openwrt

# Configure git (for your commits if needed)
git config user.email "your-email@example.com"
git config user.name "Your Name"
```

### Option B: Use Photonicat Fork (Legacy)

```bash
mkdir -p ~/openwrt-builds
cd ~/openwrt-builds
git clone https://github.com/photonicat/photonicat_openwrt lede
cd lede
```

---

## Step 3: Update Feeds and Install Packages

```bash
cd ~/openwrt-builds/openwrt

# Update all feeds
./scripts/feeds update -a

# Install all packages
./scripts/feeds install -a
```

This downloads community packages and Rockchip-specific builds.

---

## Step 4: Apply Hardware Support (Critical)

Before configuring, you must apply the Photonicat 2 device tree and kernel patches.

```bash
# Assuming you have cloned the photonicat2-openwrt repo separately to get the support files
# Let's say it's at ~/photonicat2-openwrt

# Copy Device Tree
cp ~/photonicat2-openwrt/photonicat2-support/device-tree/rk3576-photonicat2.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/

# Copy Kernel Patches
# Note: Check target/linux/rockchip/patches-* for the correct version directory
cp ~/photonicat2-openwrt/photonicat2-support/kernel-patches/*.patch target/linux/rockchip/patches-6.12/

# Copy Custom Packages (Display)
mkdir -p package/custom
cp -r ~/photonicat2-openwrt/photonicat2-support/packages/* package/custom/
```

---

## Step 5: Configure Build

### Option A: Use Default Configuration (Quick)

```bash
# Use existing Photonicat 2 config (if available)
# Or create minimal config
make defconfig
```

### Option B: Interactive Configuration (Recommended)

```bash
# Open configuration menu
make menuconfig
```

**Key Configuration Steps**:

1. **Target System**: Select `Rockchip`
2. **Subtarget**: Select `Rockchip ARMv8`
3. **Target Profile**: Select `ArmSoM Sige7` 
   - *Note: The Photonicat 2 is manufactured by Ariaboard but uses the ArmSoM Sige7 hardware profile in upstream OpenWrt.*
4. **Target Images**: 
   - ✓ ext4 filesystem
   - ✓ squashfs filesystem (recommended for smaller image)
   - ✓ tar.gz filesystem (for backup)

**Hardware Support Configuration**:

1. **LCD Display Support**:
   - Navigate to `Utilities` -> `pcat2-display-mini`
   - Or manually add to `.config`: `CONFIG_PACKAGE_pcat2-display-mini=y`
   - This installs the Go-based application that drives the mini display.

2. **Fan Control**:
   - Fan support is **native** via Kernel Thermal zones and PWM.
   - Ensure `kmod-thermal` and `kmod-pwm-rockchip` are selected (usually default).
   - No extra userspace package is required for basic operation.

3. **5G Modem**:
   - Ensure `kmod-usb-net-qmi-wwan` and `kmod-usb-serial-option` are selected.
   - ext4 + overlay filesystem
6. **Luci Web Interface** (optional): Select if you want web admin UI
7. **Additional Packages** (optional):
   - `modemmanager` - for 5G/4G modem
   - `qmi-utils` - QMI utilities
   - `kmod-usb-serial-option` - USB modem support

**Navigate in menuconfig**:
- Arrow keys: Navigate
- Space/Enter: Select
- M: Module (compiles but not built-in)
- Y: Yes (built-in)
- N: No (skip)
- ?: Help
- Q: Quit and save

---

## Step 6: Download Sources

```bash
cd ~/openwrt-builds/openwrt

# Download all required source files
# First build: use single thread, subsequent builds can use -j8 or higher
make download -j1

# Wait for all sources to download (can take 10-30 minutes)
```

Check for errors in output. If download fails for a package, run again:
```bash
make download -j1
```

---

## Step 7: Compile Firmware

### First Compile (Recommended: Single Thread)

```bash
cd ~/openwrt-builds/openwrt

# Compile with verbose output (shows build progress)
make V=s -j1

# This takes 1-2 hours on first build
# Shows real-time compilation output
```

### Subsequent Compiles (Can use parallel jobs)

```bash
# Use all available CPU cores
make V=s -j$(nproc)

# Or specify explicit thread count (e.g., j8 for 8 threads)
make V=s -j8
```

### If Compilation Fails

```bash
# Check for build errors
# Scroll up in output to find error message

# Common fixes:
# 1. Re-run configuration
rm -rf .config
make menuconfig
make V=s -j1

# 2. Clean previous build
make clean
make download -j1
make V=s -j1

# 3. Update feeds again
./scripts/feeds update -a
./scripts/feeds install -a
make V=s -j1
```

---

## Step 8: Locate Compiled Image

After successful compilation:

```bash
# Navigate to output directory
cd ~/openwrt-builds/lede/bin/targets

# List available images
ls -lh rockchip/rockchip-rk3568/

# You should see files like:
# openwrt-rockchip-rockchip-rk3568-photonicat2-squashfs-sysupgrade.img.gz
# openwrt-rockchip-rockchip-rk3568-photonicat2-ext4-sysupgrade.img.gz
# openwrt-rockchip-rockchip-rk3568-photonicat2-ext4-factory.img.gz
```

### Image Types Explained

- **squashfs-sysupgrade.img.gz**: Compressed, read-only filesystem (smallest, recommended)
- **ext4-sysupgrade.img.gz**: Read-write ext4 filesystem
- **ext4-factory.img.gz**: Full factory image with bootloader
- **.md5**: MD5 checksum for verification

---

## Step 9: Extract and Prepare Image

### Extract Firmware

```bash
# Navigate to output directory
cd ~/openwrt-builds/lede/bin/targets/rockchip/rockchip-rk3568/

# Extract gzip archive
gunzip openwrt-rockchip-rockchip-rk3568-photonicat2-squashfs-sysupgrade.img.gz

# Result: openwrt-rockchip-rockchip-rk3568-photonicat2-squashfs-sysupgrade.img (now uncompressed)
```

### Verify Image Integrity

```bash
# Check MD5 checksum (if .md5 file exists)
md5sum -c *.md5

# Or manually verify
md5sum openwrt-rockchip-rockchip-rk3568-photonicat2-squashfs-sysupgrade.img
# Compare with value in .md5 file
```

### Copy to Safe Location

```bash
# Create backup directory
mkdir -p ~/photonicat2-images/$(date +%Y%m%d)

# Copy compiled image
cp ~/openwrt-builds/lede/bin/targets/rockchip/rockchip-rk3568/openwrt-*.img \
   ~/photonicat2-images/$(date +%Y%m%d)/

# Also keep the .md5 file
cp ~/openwrt-builds/lede/bin/targets/rockchip/rockchip-rk3568/*.md5 \
   ~/photonicat2-images/$(date +%Y%m%d)/
```

---

## Step 10: Flash to Photonicat 2

Use the extracted image to flash your device. See [01-INSTALLATION.md](./01-INSTALLATION.md) for flashing instructions.

### Linux/Mac Flashing

```bash
# Put device in maskrom mode first (see 01-INSTALLATION.md)

# Flash your compiled image
rkdeveloptool wl 0 RK3576_MiniLoaderAll.bin
rkdeveloptool wl 0x0 ~/photonicat2-images/$(date +%Y%m%d)/openwrt-*.img
rkdeveloptool rd

# Device reboots with your custom OpenWrt
```

---

## Troubleshooting

### Build Dependencies Missing

**Error**: "Please install X" during make

**Solution**:
```bash
# Re-run dependency installation
sudo apt install -y <package-name>

# Or reinstall all dependencies
# (See Step 1: Install Build Dependencies)
```

### Insufficient Disk Space

**Error**: "No space left on device"

**Solution**:
```bash
# Check disk space
df -h

# Clean old builds
make clean      # Removes built binaries
make distclean   # Removes everything including downloads

# Or use separate partition
# Minimum 50GB recommended for full build
```

### Compilation Timeout or Hangs

**Error**: Build appears stuck for extended time

**Solution**:
```bash
# Kill current build
Ctrl+C

# Check system resources
top     # Check CPU and memory usage
free -h # Check available RAM

# If low on RAM, reduce parallel jobs
make V=s -j2  # Use fewer cores
```

### Network Issues During Download

**Error**: "wget: unable to resolve host"

**Solution**:
```bash
# Check internet connection
ping 8.8.8.8

# Re-run downloads
make download -j1

# Or use different DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

### File System Case Sensitivity (Windows/WSL)

**Error**: "OpenWrt can only be built on a case-sensitive filesystem"

**Solution**:
```bash
# On WSL2, enable case sensitivity for new directory
# (Must be done BEFORE git clone)

# PowerShell (Admin):
fsutil.exe file setCaseSensitiveInfo D:\openwrt enable

# Then clone with:
git clone https://github.com/photonicat/photonicat_openwrt D:\openwrt\lede
```

---

## Advanced: Custom Patches and Modifications

### Add Custom Package

```bash
# Create custom package
mkdir -p ~/openwrt-builds/lede/package/custom/mypackage
cat > ~/openwrt-builds/lede/package/custom/mypackage/Makefile << 'PKGEOF'
include $(TOPDIR)/rules.mk

PKG_NAME:=mypackage
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/mypackage
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=My Custom Package
endef

define Package/mypackage/install
$(INSTALL_DIR) $(1)/usr/bin
$(INSTALL_BIN) ./src/myapp $(1)/usr/bin/
endef

$(eval $(call BuildPackage,mypackage))
PKGEOF
```

### Apply Patch

```bash
# Add patch to specific package
cd ~/openwrt-builds/lede/package/network/services/hostapd/patches/

# Create patch file
cat > 001-custom.patch << 'PATCHEOF'
--- a/hostapd/config.c
+++ b/hostapd/config.c
@@ -1,5 +1,5 @@
 /* Custom patch */
PATCHEOF

# Rebuild package
cd ~/openwrt-builds/lede
make package/network/services/hostapd/clean
make package/network/services/hostapd/compile
```

---

## Next Steps

1. **Flash your custom image** to Photonicat 2 (see 01-INSTALLATION.md)
2. **Configure LCD display** (see 02-LCD_SCREEN_SETUP.md)
3. **Setup 5G modem** (see 03-5G_MODEM_SETUP.md)
4. **Customize further** using web UI or SSH

---

## Useful Build Commands Reference

```bash
cd ~/openwrt-builds/lede

# Clean and reset
make clean              # Remove compiled binaries
make distclean          # Remove everything

# Configuration
make menuconfig         # Interactive menu
make nconfig            # Alternative menu
make defconfig          # Use defaults

# Building
make download -j8       # Download sources
make -j4                # Compile with 4 threads
make V=s -j1            # Verbose single-threaded

# Specific targets
make tools/install      # Just build tools
make toolchain/install  # Just build toolchain
make target/compile     # Just compile target

# Incremental builds
make                    # Rebuild what changed
make package/refresh    # Update package timestamps
make -B                 # Force rebuild everything

# Information
make info               # Show build configuration
make package/index      # Rebuild package index
make world              # Build everything
```

---

## References

- Official Photonicat: https://photonicat.com/
- Photonicat OpenWrt Repo: https://github.com/photonicat/photonicat_openwrt
- OpenWrt Documentation: https://openwrt.org/docs/guide-developer/build-system/start
- Rockchip Support: https://github.com/ariaboard-com/rockchip_rk3568_openwrt
- coolsnowwolf LEDE: https://github.com/coolsnowwolf/lede

---

**Last Updated**: November 2025  
**Device**: Photonicat 2 (RK3568/RK3576)  
**Build System**: OpenWrt/LEDE  
**Status**: Tested and working

