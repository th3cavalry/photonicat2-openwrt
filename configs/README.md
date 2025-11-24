# Custom OpenWrt Configuration for Photonicat 2

## Overview

This directory should contain your custom OpenWrt configuration file (`pcat2_custom.config`) that will be used during the build process.

## Generating Your Custom Config

The custom configuration file is generated using the upstream OpenWrt `diffconfig.sh` script. This creates a minimal configuration diff that captures only your custom settings.

### Steps to Generate Configuration

1. **Clone and build the upstream repository** (if not already done):
   ```bash
   git clone https://github.com/photonicat/photonicat_openwrt
   cd photonicat_openwrt
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   ```

2. **Configure your build** using menuconfig:
   ```bash
   make menuconfig
   ```

3. **Required Configuration Options**:
   
   Enable these kernel modules and packages:
   - **SPI Support**:
     - `kmod-spi-dev` - SPI device support (for LCD display)
     - `kmod-spi-bitbang` - SPI bitbang support
   
   - **NPU Support**:
     - `kmod-rknpu` - Rockchip NPU kernel module
   
   - **Disable**:
     - `luci-app-pcat-manager` - Disable if you don't need the web-based Photonicat manager

   Optional but recommended:
   - `block-mount` - For automatic filesystem mounting (NVMe overlay)
   - `kmod-fs-ext4` - EXT4 filesystem support for NVMe
   - `kmod-nvme` - NVMe drive support

4. **Generate the diffconfig**:
   ```bash
   ./scripts/diffconfig.sh > /path/to/this/repo/configs/pcat2_custom.config
   ```

5. **Verify the config file** contains your required options:
   ```bash
   cat configs/pcat2_custom.config
   ```

## Example Configuration Entries

Your `pcat2_custom.config` file should contain entries like:

```
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_photonicat_photonicat2=y
CONFIG_PACKAGE_kmod-spi-dev=y
CONFIG_PACKAGE_kmod-spi-bitbang=y
CONFIG_PACKAGE_kmod-rknpu=y
# CONFIG_PACKAGE_luci-app-pcat-manager is not set
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-nvme=y
```

## Using the Configuration

Once you've created `pcat2_custom.config` in this directory, simply run:

```bash
./build.sh
```

The build script will automatically apply your configuration and build the custom image.

## Additional Customization

### Target System Settings

Ensure your configuration targets the Photonicat 2:
- **Target System**: `Rockchip`
- **Subtarget**: `RK3568/RK3566/RK3576 boards`
- **Target Profile**: `Photonicat (Photonicat 2)`

### Kernel Modules for LCD Display

The GC9307 LCD display requires SPI support:
- `Kernel modules → SPI Support → kmod-spi-dev`
- `Kernel modules → SPI Support → kmod-spi-bitbang`

### Kernel Modules for 5G Modem

For 5G/4G modem support:
- `Kernel modules → USB Support → kmod-usb-serial`
- `Kernel modules → USB Support → kmod-usb-serial-option`
- `Kernel modules → USB Support → kmod-usb-serial-wwan`
- `Network → wwan` packages

### Storage and Filesystem

For NVMe overlay support:
- `Kernel modules → Block Devices → kmod-nvme`
- `Kernel modules → Filesystems → kmod-fs-ext4`
- `Base system → block-mount`

## Troubleshooting

**Config file not found error**: Make sure `pcat2_custom.config` exists in this directory before running `./build.sh`.

**Build fails with missing package**: Run `make menuconfig` in the upstream build directory to verify the package is available, then regenerate your diffconfig.

**Config appears to be ignored**: The build process runs `make defconfig` which expands your minimal config. Check the full `.config` in the build directory if needed.

## More Information

- OpenWrt Build System: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem
- OpenWrt Configuration: https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#configure_target_and_options
- Photonicat Documentation: https://photonicat.com/wiki
