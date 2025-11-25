# Photonicat 2 OpenWrt Build Wrapper

## Overview

This repository provides a **build system wrapper** for creating custom OpenWrt images for the Photonicat 2 device using **vanilla OpenWrt** with minimal device-specific patches. 

**Key Features:**
- 🔒 **Security First**: Uses official OpenWrt repository, not third-party forks
- 🏭 **Factory-like Installation**: Base system installs to internal eMMC
- 💾 **NVMe Data Persistence**: Automatic overlay mounting on NVMe for user data
- 🔄 **Graceful Fallback**: Reverts to eMMC if NVMe is removed
- ⚙️ **Minimal Patches**: Only essential hardware support (device tree + drivers)
- 🎯 **Single Command Build**: Simple build process with one script

## Why Vanilla OpenWrt?

Unlike the photonicat/photonicat_openwrt fork which uses custom package feeds and extensive modifications, this build wrapper:
- ✅ Uses **official OpenWrt package repositories** (better security, regular updates)
- ✅ Applies **minimal device-specific patches** (device tree, essential drivers only)
- ✅ Avoids **supply chain risks** from third-party maintained feeds
- ✅ Maintains **compatibility with upstream** OpenWrt
- ✅ Provides **transparency** - all patches are in `photonicat2-support/` for review

See `photonicat2-support/README.md` for details on what's included vs. excluded.

## Architecture

### Storage Strategy

This build creates an OpenWrt image that implements a two-tier storage system:

1. **eMMC (Internal Storage)**
   - Contains the base OpenWrt system (read-only squashfs)
   - Acts as the "factory" installation
   - Always available, even if NVMe is removed
   - Provides reliable fallback configuration

2. **NVMe Drive (Optional)**
   - Automatically mounted as `/overlay` on first boot
   - Stores all user data, configurations, and installed packages
   - Provides high-performance persistent storage
   - Removable without breaking the system

### First Boot Behavior

When the device boots for the first time:
1. The `99-mount-nvme` script detects the NVMe drive (`/dev/nvme0n1p1`)
2. Formats it as ext4 if not already formatted
3. Configures UCI/fstab to mount it as `/overlay`
4. Copies any existing overlay data to NVMe
5. On subsequent boots, uses NVMe for all persistent storage

If the NVMe is removed, the device automatically falls back to using the eMMC overlay.

## Quick Start

### Prerequisites

- Linux development environment (Ubuntu/Debian or Arch Linux)
- Required packages:
  
  **Ubuntu/Debian:**
  ```bash
  sudo apt update
  sudo apt install -y build-essential git curl wget unzip
  ```
  
  **Arch Linux:**
  ```bash
  sudo pacman -Syu
  sudo pacman -S --needed base-devel git curl wget unzip
  ```

- At least 50GB of free disk space
- 2-4 hours for initial build (faster on subsequent builds)

### Building Your Custom Image

1. **Clone this repository**:
   ```bash
   git clone https://github.com/th3cavalry/photonicat2-openwrt
   cd photonicat2-openwrt
   ```

2. **Generate your custom configuration** (see [configs/README.md](./configs/README.md)):
   ```bash
   # You need to create configs/pcat2_custom.config
   # See configs/README.md for detailed instructions
   ```
   
   The configuration should enable:
   - `pcat2-display-mini` - Userspace driver for LCD display
   - `kmod-pwm`, `kmod-pwm-rockchip` - PWM for fan control (Native)
   - `kmod-nvme`, `kmod-fs-ext4` - NVMe storage support
   - See `configs/pcat2_custom.config.example` for full list

3. **Run the build**:
   ```bash
   ./build.sh
   ```
   
   This will:
   - Clone the **official OpenWrt repository** (not photonicat fork)
   - Apply Photonicat 2 device tree and essential kernel patches
   - Update and install official OpenWrt feeds
   - Apply your custom configuration
   - Copy custom files (including NVMe mount script)
   - Build the complete OpenWrt image

4. **Find your image**:
   ```bash
   # Image will be in:
   ./build/openwrt/bin/targets/rockchip/armv8/
   ```

### Flashing the Image

Once built, flash the image to your Photonicat 2's eMMC storage:

1. Enter maskrom mode on your device
2. Use `rkdeveloptool` (Linux/Mac) or RKDevTool (Windows)
3. Flash the `.img` file to eMMC
4. Reboot and enjoy!

For detailed flashing instructions, see the legacy guides in the `guides/` directory.

## Repository Structure

```
photonicat2-openwrt/
├── build.sh                          # Main build wrapper script
├── configs/
│   ├── README.md                     # Configuration guide
│   ├── pcat2_custom.config           # Your custom config (you create this)
│   └── pcat2_custom.config.example   # Example configuration
├── files/
│   └── etc/
│       └── uci-defaults/
│           └── 99-mount-nvme         # First-boot NVMe mount script
├── photonicat2-support/              # ⭐ Hardware support files
│   ├── README.md                     # What's included and why
│   ├── device-tree/                  # RK3576 Photonicat 2 device tree
│   ├── kernel-patches/               # Essential drivers (review before use!)
│   └── packages/                     # Custom packages (optional)
├── guides/                           # Legacy documentation
├── scripts/                          # Legacy scripts (for reference)
└── README.md                         # This file
```

## Customization

### Custom Configuration

The `configs/pcat2_custom.config` file controls your build options. See [configs/README.md](./configs/README.md) for:
- How to generate your custom config
- Required kernel modules
- Recommended packages
- Target system settings

### Custom Files

Any files placed in the `files/` directory will be copied to the build and included in your firmware image. This is useful for:
- Pre-configured system files
- Custom scripts
- Default network configurations
- SSH keys

Current custom files:
- `files/etc/uci-defaults/99-mount-nvme` - NVMe overlay auto-mount script

### LCD Display and Fan Support

The Photonicat 2 includes an LCD display and cooling fan. Documentation:
- 📘 **[Complete Guide](./guides/06-SCREEN_AND_FAN_DETAILED.md)** - Comprehensive configuration documentation
- 📖 **[Quick Reference](./photonicat2-support/LCD_AND_FAN.md)** - Installation and basic setup

Features:
- ✅ **LCD Display** - GC9307 SPI LCD (172x320px) showing system status
- ✅ **Cooling Fan** - PWM-controlled automatic thermal management
- ✅ **Full customization** - Display application with HTTP API
- ✅ **Installation guide** - How to enable in your build
- ✅ **Configuration** - Customize display pages, intervals, appearance, colors
- ✅ **All options documented** - Complete data keys, element types, and examples

The display package (`pcat2-display-mini`) is included in `photonicat2-support/packages/` and automatically copied during build. Enable it in menuconfig or add to your config file.

### Build Options

```bash
# Build with custom number of CPU cores
./build.sh --jobs 8

# Use a different build directory
./build.sh --dir /mnt/external/openwrt-build

# Skip feed updates (for rebuilds)
./build.sh --skip-feeds

# Show help
./build.sh --help
```

## Device Specifications

**Device**: Photonicat 2  
**CPU**: Rockchip RK3576 (8-core Cortex A72/A53 @ 2.2GHz)  
**RAM**: 4-16GB LPDDR5  
**Storage**: 
- 8-128GB eMMC (internal, system storage)
- NVMe M.2 support (optional, user data)
- SD Card support (optional, additional storage)

**Display**: GC9307 LCD (172x320px, SPI interface)  
**Connectivity**: 5G Modem (RM500/RM520), WiFi 6, Dual GigE  
**Bootloader**: Rockchip maskrom protocol

## How It Works

### Build Process

1. **Clone Upstream**: Clones **official OpenWrt** from `https://github.com/openwrt/openwrt.git`
2. **Apply Hardware Support**: Copies Photonicat 2 device tree and essential kernel patches
3. **Feed Management**: Updates and installs **official OpenWrt package feeds** (not photonicat forks)
4. **Apply Config**: Copies your `pcat2_custom.config` and runs `make defconfig`
5. **Custom Files**: Integrates files from `files/` directory into the build
6. **Compilation**: Builds the complete firmware image with your settings

**Key Difference**: Unlike photonicat/photonicat_openwrt which uses custom feed repositories for ALL packages, this wrapper uses official OpenWrt feeds, ensuring better security and transparency.

### Runtime Behavior

1. **First Boot**:
   - System boots from eMMC
   - `99-mount-nvme` script runs via uci-defaults
   - Detects and configures NVMe if present
   - Formats NVMe as ext4 with label "overlay"
   - Migrates existing overlay to NVMe
   - Configures automatic mount on subsequent boots

2. **Subsequent Boots**:
   - System boots from eMMC (base system)
   - Automatically mounts NVMe as `/overlay`
   - All changes persist to NVMe
   - eMMC remains untouched (factory state)

3. **NVMe Removal**:
   - System gracefully falls back to eMMC overlay
   - Reverts to factory-like configuration
   - No data loss if NVMe is reconnected

## Troubleshooting

### Build Issues

**Missing config file**:
```bash
ERROR: Custom config not found: ./configs/pcat2_custom.config
```
Solution: Create your custom config file. See [configs/README.md](./configs/README.md).

**Build fails during compilation**:
```bash
# Clean and retry
cd build/photonicat_openwrt
make clean
cd ../..
./build.sh --skip-clone
```

**Out of disk space**:
```bash
# Use external drive
./build.sh --dir /mnt/external/build
```

### Runtime Issues

**NVMe not mounting automatically**:
- Check that NVMe is detected: `ls -l /dev/nvme*`
- Check system logs: `logread | grep nvme-mount`
- Verify fstab: `cat /etc/config/fstab`

**Want to reset to factory state**:
- Remove NVMe drive or disable its mount in `/etc/config/fstab`
- Reboot - system will use eMMC overlay

## Vanilla OpenWrt vs Photonicat Fork

### What's Different?

This build wrapper uses **vanilla OpenWrt** instead of the photonicat fork:

| Aspect | This Wrapper (Vanilla) | photonicat/photonicat_openwrt Fork |
|--------|----------------------|----------------------------------|
| **Base Repository** | Official OpenWrt | Modified fork |
| **Package Feeds** | Official OpenWrt feeds | Custom photonicat-controlled feeds |
| **Security** | Community-reviewed packages | Unknown review process |
| **Updates** | Direct from OpenWrt project | Delayed through photonicat |
| **Modifications** | Minimal (device tree + 2 patches) | Extensive (feeds, patches, packages) |
| **Transparency** | All patches visible in repo | Distributed across multiple repos |
| **Supply Chain Risk** | Low (official sources) | Higher (single-entity controlled) |

### What's Included from Photonicat?

Only the **essential hardware support** (extracted to `photonicat2-support/`):
- ✅ Device tree file (rk3576-photonicat2.dts)
- ✅ Power management driver patch
- ✅ USB watchdog driver patch

### What's NOT Included?

To maintain security and use vanilla OpenWrt:
- ❌ Custom package feeds (use official OpenWrt feeds instead)
- ❌ pcat-manager web interface (use standard LuCI)
- ❌ Custom base scripts (you can add if needed)
- ❌ Overclocking patches
- ❌ Other non-essential modifications

See `photonicat2-support/README.md` for detailed analysis.

## Advanced Usage

### Manual Build Steps

If you want to manually control the build process:

```bash
# Clone vanilla OpenWrt
git clone https://github.com/openwrt/openwrt.git build/openwrt
cd build/openwrt

# Apply Photonicat 2 hardware support
cp ../../photonicat2-support/device-tree/*.dts target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
cp ../../photonicat2-support/kernel-patches/*.patch target/linux/rockchip/patches-6.12/

# Update feeds (official OpenWrt feeds)
./scripts/feeds update -a
./scripts/feeds install -a

# Apply custom config
cp ../../configs/pcat2_custom.config .config
make defconfig

# Copy custom files
cp -r ../../files/* package/base-files/files/

# Build
make download -j8
make -j8
```

### Kernel Module Development

If you're developing custom kernel modules:
1. Place module source in `files/` or as a package
2. Update `pcat2_custom.config` to enable your module
3. Rebuild with `./build.sh`

### Debugging

Build with verbose output:
```bash
cd build/photonicat_openwrt
make V=s -j1
```

## Legacy Documentation

For reference, the `guides/` and `scripts/` directories contain previous documentation and build scripts. These are kept for historical reference but are not required for the new build process.

## Support & Resources

- **This Repository**: https://github.com/th3cavalry/photonicat2-openwrt
- **Upstream Build**: https://github.com/photonicat/photonicat_openwrt
- **Official Wiki**: https://photonicat.com/wiki
- **Firmware Releases**: https://dl.photonicat.com/images/photonicat2/openwrt/
- **Display Driver**: https://github.com/photonicat/photonicat2_mini_display
- **Community**: https://t.me/+IATZElRYPydkM2Rl (Telegram)

## Contributing

Contributions are welcome! Please:
1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This build wrapper is provided as-is under the MIT License. OpenWrt and its components have their own licenses - see the upstream repository for details.

## Disclaimer

This is an unofficial build system wrapper. While tested, improper firmware flashing can brick your device. Always:
- ✅ Backup your data before flashing
- ✅ Use proper USB cables and drivers
- ✅ Follow official flashing procedures
- ✅ Keep a recovery image handy

---

**Last Updated**: November 2025  
**Device**: Photonicat 2 (RK3576)  
**OpenWrt**: Based on upstream photonicat_openwrt
