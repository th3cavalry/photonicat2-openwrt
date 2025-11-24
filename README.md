# Photonicat 2 OpenWrt Build Wrapper

## Overview

This repository provides a **build system wrapper** for creating custom OpenWrt images for the Photonicat 2 device. It wraps the upstream [photonicat/photonicat_openwrt](https://github.com/photonicat/photonicat_openwrt) repository and applies custom configurations optimized for a "factory-like" installation.

**Key Features:**
- 🏭 **Factory-like Installation**: Base system installs to internal eMMC
- 💾 **NVMe Data Persistence**: Automatic overlay mounting on NVMe for user data
- 🔄 **Graceful Fallback**: Reverts to eMMC if NVMe is removed
- ⚙️ **Custom Configuration**: Easy customization via config files
- 🎯 **Single Command Build**: Simple build process with one script

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

- Linux development environment (Ubuntu/Debian recommended)
- Required packages:
  ```bash
  sudo apt update
  sudo apt install -y build-essential git curl wget unzip
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
   - `kmod-spi-dev` - SPI device support (for LCD)
   - `kmod-spi-bitbang` - SPI bitbang support
   - `kmod-rknpu` - Rockchip NPU support
   - Disable `luci-app-pcat-manager` if not needed

3. **Run the build**:
   ```bash
   ./build.sh
   ```
   
   This will:
   - Clone the upstream photonicat_openwrt repository
   - Update and install all feeds
   - Apply your custom configuration
   - Copy custom files (including NVMe mount script)
   - Build the complete OpenWrt image

4. **Find your image**:
   ```bash
   # Image will be in:
   ./build/photonicat_openwrt/bin/targets/rockchip/armv8/
   ```

### Flashing the Image

Once built, flash the image to your Photonicat 2's eMMC storage:

1. Enter maskrom mode on your device
2. Use `rkdeveloptool` (Linux/Mac) or RKDevTool (Windows)
3. Flash the `.img` file to eMMC
4. Reboot and enjoy!

For detailed flashing instructions, see the [upstream documentation](https://github.com/photonicat/photonicat_openwrt#flashing).

## Repository Structure

```
photonicat2-openwrt/
├── build.sh                          # Main build wrapper script
├── configs/
│   ├── README.md                     # Configuration guide
│   └── pcat2_custom.config           # Your custom config (you create this)
├── files/
│   └── etc/
│       └── uci-defaults/
│           └── 99-mount-nvme         # First-boot NVMe mount script
├── guides/                           # Additional documentation
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

1. **Clone Upstream**: The build script clones the official photonicat_openwrt repository
2. **Feed Management**: Updates and installs all OpenWrt package feeds
3. **Apply Config**: Copies your `pcat2_custom.config` and runs `make defconfig`
4. **Custom Files**: Integrates files from `files/` directory into the build
5. **Compilation**: Builds the complete firmware image with your settings

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

## Advanced Usage

### Manual Build Steps

If you want to manually control the build process:

```bash
# Clone upstream
git clone https://github.com/photonicat/photonicat_openwrt build/photonicat_openwrt
cd build/photonicat_openwrt

# Update feeds
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
