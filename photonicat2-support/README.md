# Photonicat 2 Hardware Support Files

This directory contains the **minimal essential files** extracted from the photonicat/photonicat_openwrt repository needed to build vanilla OpenWrt with Photonicat 2 hardware support.

## Contents

### `device-tree/`
- **`rk3576-photonicat2.dts`** - Device tree file for Photonicat 2 hardware
  - Defines all hardware components (eMMC, NVMe, LCD, 5G modem, battery, sensors)
  - Required for kernel to recognize and initialize hardware
  - Source: https://github.com/photonicat/photonicat_openwrt

### `kernel-patches/`
- **`990-photonicat-pm-add-driver.patch`** - Power management driver
  - Custom driver for battery management, power control
  - Enables proper power off, battery monitoring
  
- **`998-add-photonicat-usb-watchdog-driver.patch`** - USB watchdog driver
  - Hardware watchdog for system stability

**Note**: These patches should be **reviewed for security and code quality** before use.

### `packages/`
- **`pcat2-display-mini/`** - LCD display driver application (Go-based)
  - Shows real-time system stats on the 172x320 LCD screen
  - Displays: CPU, memory, network, battery, 5G modem status, SMS
  - Fully customizable via config.json
  - HTTP API for remote control
  - Source: https://github.com/photonicat/photonicat2_mini_display
  - Enable in menuconfig: `Utilities → pcat2-display-mini`

### `LCD_AND_FAN.md`
- **Comprehensive guide** for LCD display and cooling fan support
- Installation instructions
- Customization options
- Troubleshooting tips
- Manual and automatic control methods

## Usage

These files are automatically applied by `build.sh` when building from vanilla OpenWrt.

## Security Considerations

⚠️ **IMPORTANT**: These files are extracted from a third-party repository and should be treated as **untrusted code** until reviewed.

**Before using in production:**
1. Review all kernel patches for security issues
2. Verify device tree definitions match your hardware
3. Test thoroughly in a non-production environment
4. Consider upstreaming patches to mainline kernel for better review

## What's NOT Included

To maintain security and use vanilla OpenWrt, we **deliberately exclude**:

- ❌ Photonicat-modified feed repositories (packages, LuCI, routing, telephony)
- ❌ `pcat-manager` web interface (use standard LuCI instead)
- ❌ Custom base system scripts
- ❌ Overclocking patches (can add separately if desired)
- ❌ Proprietary/closed-source components

## Alternative: Use Official Feeds

Instead of Photonicat feeds, the build script uses:
- Official OpenWrt package feed: `https://git.openwrt.org/feed/packages.git`
- Official OpenWrt LuCI: `https://git.openwrt.org/project/luci.git`
- Official routing feed: `https://git.openwrt.org/feed/routing.git`
- Official telephony feed: `https://git.openwrt.org/feed/telephony.git`

This ensures you get:
✅ Security-reviewed packages
✅ Regular updates from OpenWrt community
✅ No supply chain risk from third-party feeds
✅ Better compatibility with upstream

## LCD Display Support

If you need the LCD display to work:

1. Extract and review the `pcat2-display-mini` package source
2. Check for security issues, hardcoded credentials, etc.
3. Place in `packages/` directory
4. Enable in your config file

## 5G Modem Support

The RK3576 device tree includes USB definitions for 5G modem support. Standard OpenWrt packages should work:
- `kmod-usb-serial`
- `kmod-usb-serial-option`
- `kmod-usb-serial-wwan`
- `wwan` packages from official feeds

No custom patches required for basic modem functionality.

## Contributing

If you improve these patches or device tree files:
1. Consider upstreaming to mainline Linux kernel
2. Submit to OpenWrt project for RK3576 support
3. Share improvements back to the community

## License

- Device tree files: GPL-2.0+ OR MIT (as specified in file headers)
- Kernel patches: GPL-2.0 (kernel licensing)

## References

- Upstream source: https://github.com/photonicat/photonicat_openwrt
- Official OpenWrt: https://github.com/openwrt/openwrt
- Rockchip RK3576: https://www.rock-chips.com/
