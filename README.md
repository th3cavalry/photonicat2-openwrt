# Photonicat 2 OpenWrt Installation & Configuration Guide

## Overview

This guide covers installing a fresh OpenWrt installation on your Photonicat 2 while keeping the 5G modem and LCD screen fully functional.

**Device**: Photonicat 2
**CPU**: Rockchip RK3576 (8-core Cortex A72/A53 @ 2.2GHz)
**RAM**: 4-16GB LPDDR5
**Storage**: 8-128GB eMMC, SD Card, NVMe support
**Display**: GC9307 LCD (172x320px, SPI interface)
**Connectivity**: 5G Modem (RM500/RM520), WiFi 6, Dual GigE
**Bootloader**: Rockchip maskrom protocol

## Quick Links

- [Building from Source](./guides/05-BUILDING_OPENWRT.md) - Compile custom OpenWrt firmware
- [Installation Guide](./guides/01-INSTALLATION.md) - Step-by-step firmware flashing
- [LCD Screen Setup](./guides/02-LCD_SCREEN_SETUP.md) - Display driver configuration
- [5G Modem Configuration](./guides/03-5G_MODEM_SETUP.md) - Cellular connectivity
- [Recovery Procedures](./guides/04-RECOVERY.md) - Device recovery and unbricking

## Key Hardware Specifications

### Display (LCD Screen)
- **Driver**: GC9307 SPI LCD controller
- **Resolution**: 172x320 pixels
- **Rotation**: 180 degrees
- **Interface**: SPI (GPIO pins: RST=122, DC=121, CS=13)
- **Backlight**: PWM controlled brightness
- **Application**: pcat2_mini_display (Go-based)

### 5G/4G Modem
- **Models**: Quectel RM500Q-GL or RM520N-GL
- **Protocol**: QMI (Qualcomm MSM Interface)
- **Interface**: USB or M.2 B-Key slot
- **Bands**: Full global 4G/5G coverage
- **Management**: ModemManager, QMI services, AT commands

### Storage Layout
- **eMMC**: System storage (8-128GB options)
- **SD Card**: Optional additional storage
- **NVMe M.2**: High-speed SSD support (M-Key slot)

## Directory Structure

```
photonicat2/
├── guides/
│   ├── 01-INSTALLATION.md         # Firmware flashing instructions
│   ├── 02-LCD_SCREEN_SETUP.md     # LCD driver configuration
│   ├── 03-5G_MODEM_SETUP.md       # 5G/4G modem setup
│   ├── 04-RECOVERY.md             # Device recovery procedures
│   └── 05-TOOLS_REFERENCE.md      # Tools and utilities
├── scripts/
│   ├── backup-factory.sh          # Backup original firmware
│   ├── install-display-driver.sh  # LCD setup script
│   ├── setup-modem.sh             # 5G modem configuration
│   └── post-install.sh            # Post-installation setup
├── configs/
│   ├── display-config.json        # pcat2_mini_display config
│   ├── network.config             # Network configuration
│   └── modem-settings.conf        # Modem configuration
├── tools/
│   └── README.md                  # Tool download links
└── references/
    ├── GC9307_datasheet.txt       # LCD controller info
    ├── RK3576_specs.txt           # CPU specifications
    └── OpenWrt_docs.txt           # OpenWrt resources
```

## Prerequisites

### On Your Computer
- USB Type-A to Type-A cable (for flashing)
- **Linux/Mac**: RKDevTool or rkdeveloptool
- **Windows**: RKDevTool v2.86+, Rockchip drivers
- Firmware image: Official Photonicat 2 OpenWrt build or custom build

### On Photonicat 2
- Bootloader: RK3576 maskrom (built-in, always available)
- USB port: USB 3.0 on top of device
- Power: Fully charged battery or external power

## What Gets Preserved

When installing fresh OpenWrt:
- ✅ **LCD Screen** - Full functionality with pcat2_mini_display service
- ✅ **5G/4G Modem** - All bands, all cellular connectivity
- ✅ **WiFi** - 802.11ac/ax wireless
- ✅ **Ethernet** - Dual gigabit ports
- ✅ **Battery Management** - Power control and monitoring
- ✅ **USB Ports** - All USB functionality
- ✅ **Sensors** - Temperature, voltage, current monitoring

## What You'll Need to Configure

After installing OpenWrt:
1. **LCD Display** - Install pcat2_mini_display service (provided)
2. **5G Modem** - Enable and configure cellular connection
3. **Network** - Configure LAN/WAN, DHCP, routing
4. **WiFi** - Set up wireless SSID and security
5. **System** - Hostname, NTP, web UI password

## Building vs. Flashing Pre-Built Images

### Option 1: Quick Start (Pre-Built Images)
Use official pre-built images from Photonicat:
1. Download firmware from https://dl.photonicat.com/images/photonicat2/openwrt/
2. Flash using instructions in [01-INSTALLATION.md](./guides/01-INSTALLATION.md)
3. Configure LCD and 5G modem

### Option 2: Custom Build (Build from Source)
Compile your own OpenWrt image:
1. Follow [05-BUILDING_OPENWRT.md](./guides/05-BUILDING_OPENWRT.md)
2. Or use the automated build script: `./scripts/build-openwrt.sh --full`
3. Flash your custom image using [01-INSTALLATION.md](./guides/01-INSTALLATION.md)

## Installation Overview

1. **Backup**: Save original factory firmware (optional but recommended)
2. **Build/Prepare**: Build from source OR download pre-built image
3. **Flash**: Enter maskrom mode and flash firmware via USB
4. **Configure**: Boot into OpenWrt and run post-install configuration
5. **Enable LCD**: Install and start pcat2_mini_display service
6. **Setup Modem**: Configure 5G/4G cellular connectivity
7. **Verify**: Test all features are working

## Getting Started

Choose your path:

**Fast Track (Pre-built firmware):**
1. Download firmware from https://dl.photonicat.com/images/photonicat2/openwrt/
2. Start with **[01-INSTALLATION.md](./guides/01-INSTALLATION.md)** for flashing instructions

**Custom Build (Compile from source):**
1. Start with **[05-BUILDING_OPENWRT.md](./guides/05-BUILDING_OPENWRT.md)** for build instructions
2. Or run: `./scripts/build-openwrt.sh --full --extract --backup`
3. Then follow **[01-INSTALLATION.md](./guides/01-INSTALLATION.md)** to flash your custom image

## Important Notes

⚠️ **Backup First**: Always backup your factory firmware before flashing  
⚠️ **USB Cable**: Use proper USB-A to USB-A cable, not charging cable  
⚠️ **Maskrom Mode**: Device must be in maskrom mode before connecting to computer  
⚠️ **Driver Installation**: On Windows, install Rockchip drivers first  
⚠️ **Antivirus**: Disable antivirus (e.g., Huorui) if flashing fails on Windows  

## Support & Resources

- **Official Wiki**: https://photonicat.com/wiki
- **GitHub**: https://github.com/photonicat
- **Firmware Releases**: https://dl.photonicat.com/images/photonicat2/openwrt/
- **Display Driver**: https://github.com/photonicat/photonicat2_mini_display
- **OpenWrt Build**: https://github.com/photonicat/photonicat_openwrt
- **Community**: https://t.me/+IATZElRYPydkM2Rl (Telegram)

## License & Disclaimer

This guide is provided as-is. While the Photonicat 2 is designed to be user-friendly and hackable, improper firmware flashing can brick your device. Always follow instructions carefully and back up your data.

---

**Last Updated**: November 2025  
**Device**: Photonicat 2 (RK3576)  
**OpenWrt Version**: Latest official/custom builds
