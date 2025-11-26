# Photonicat 2 OpenWrt - Project Status

## ✅ Current Phase: Network Configuration & Build v3

**Status**: Custom image REBUILDING with corrected network configuration
**Date**: November 26, 2025
**Build Progress**: In Progress (~30-60 min)

## Recent Changes (Session: Nov 26, 2025)

### Problem Identified
Device had no network connectivity after first custom build (v1):
- Got 169.* APIPA address (DHCP not working)
- No WiFi broadcasting
- Issue: Incorrect network interface configuration

### Root Cause
- Custom build used **eth0** for LAN (static 192.168.1.1)
- Factory image uses **eth1** for LAN (172.16.0.1)  
- Custom build WAN on eth1, Factory uses eth0 for WAN
- **Interfaces were backwards**

### Solution Implemented

#### 1. Factory Configuration Extraction ✅
- Mounted factory image and extracted working configs
- Copied: `/etc/config/network`, `/etc/config/firewall`, `/etc/config/dhcp`
- Found factory uses board.d scripts for proper interface mapping

#### 2. Network Configuration Update ✅
- Replaced `files/etc/config/network` with factory version
  - LAN: 172.16.0.1/23 on br-lan (bridge with eth1)
  - WAN: DHCP on eth0
- Copied board.d scripts for proper configuration
  - `files/etc/board.d/02_network` - sets up eth1 as LAN, eth0 as WAN
  - `files/etc/board.d/01_leds` - LED configuration

#### 3. UCI Defaults Cleanup ✅
- Removed broken custom scripts that weren't working:
  - `10-network-setup` - incorrect interface mapping
  - `11-wireless-setup` - not detecting devices
  - `12-enable-wifi` - WiFi not enabling
  - `13-network-bridge` - manual bridge config failing
- Kept working scripts:
  - `90-pcat2-setup` - Display configuration
  - `99-mount-nvme` - NVMe overlay mount

#### 4. Wireless Support Added ✅
- Enabled WiFi packages in .config:
  - `CONFIG_PACKAGE_kmod-ath=y` - Atheros base driver
  - `CONFIG_PACKAGE_kmod-ath10k=y` - Atheros 10K support
  - `CONFIG_PACKAGE_kmod-ath11k=y` - Atheros 11K support
  - `CONFIG_PACKAGE_wireless-tools=y` - Wireless utilities
  - `CONFIG_PACKAGE_wireless-regdb=y` - Regulatory database
- WiFi will be auto-discovered on boot (factory approach)

### Files Modified/Added

```
files/
├── etc/
│   ├── board.d/
│   │   ├── 01_leds          ← Factory LED config
│   │   └── 02_network       ← Factory network setup (CRITICAL)
│   ├── config/
│   │   ├── network          ← Factory network (172.16.0.1 LAN, eth1)
│   │   ├── firewall         ← Factory firewall rules
│   │   └── dhcp             ← Factory DHCP config
│   └── uci-defaults/
│       ├── 90-pcat2-setup   ← Display config (working)
│       └── 99-mount-nvme    ← NVMe mount (working)
```

## Build Status

### Current Build (v3)
- **Started**: 17:15 (Nov 26, 2025)
- **Type**: Full clean rebuild (`make clean && make -j4`)
- **Expected Time**: 30-60 minutes
- **Configuration**: Network + WiFi + Display + NVMe
- **Log**: `/home/th3cavalry/photonicat2/build/openwrt/build.log`

### Expected Results
- ✅ Device boots to 172.16.0.1 on LAN (static IP)
- ✅ WiFi SSID broadcasts
- ✅ Can SSH to device
- ✅ Can access LuCI web interface
- ✅ NVMe auto-mounts on first boot
- ✅ Display shows system info (if enabled)

### Previous Builds
- **v1** (Nov 24): Initial custom build - Network broken (wrong interface config)
- **v2** (Nov 25): Attempted fixes - Still broken
- **v3** (Nov 26 - Current): Full factory config extraction + WiFi enabled

## Repository Structure

```
photonicat2-openwrt/
├── README.md                          # Main documentation (updated)
├── PROJECT_STATUS.md                  # THIS FILE
├── CUSTOM_BUILD_NOTES.md              # Build history & troubleshooting
├── build.sh                           # Build wrapper script
├── configs/
│   ├── README.md                      # Config guide
│   ├── pcat2_custom.config            # Current build config
│   └── pcat2_custom.config.example
├── files/                             # ⭐ CUSTOM FILES TO INCLUDE IN IMAGE
│   └── etc/
│       ├── board.d/                   # NEW: Board-specific scripts
│       │   ├── 01_leds                # LED configuration
│       │   └── 02_network             # Network interface setup (CRITICAL)
│       ├── config/                    # NEW: UCI config files
│       │   ├── network                # Network setup (172.16.0.1, eth1 LAN)
│       │   ├── firewall               # Firewall rules
│       │   └── dhcp                   # DHCP server config
│       └── uci-defaults/
│           ├── 90-pcat2-setup         # Display setup
│           └── 99-mount-nvme          # NVMe mount script
├── photonicat2-support/               # Hardware support files
│   ├── README.md
│   ├── device-tree/
│   │   └── rk3576-photonicat2.dts
│   └── kernel-patches/
├── release/
│   ├── flash.sh                       # Flashing script
│   └── README.txt
├── guides/                            # Documentation
├── build/                             # Build output directory
│   └── openwrt/                       # Cloned OpenWrt repo
│       └── bin/targets/rockchip/armv8/
│           └── openwrt-...-squashfs-sysupgrade.img
└── rkdeveloptool/                     # Flashing tool
```

## What's Different Now (v3 vs v1)

| Aspect | v1 (Broken) | v3 (Current) |
|--------|-----------|------------|
| LAN IP | 192.168.1.1 on eth0 | 172.16.0.1 on eth1 (br-lan) |
| WAN Interface | eth1 | eth0 |
| Network Config Source | Custom (wrong) | Factory (verified working) |
| Board Setup | None (broken) | Factory scripts (02_network, 01_leds) |
| WiFi Support | Not enabled | Enabled (kmod-ath*) |
| WiFi Config Method | Manual scripts | Auto-discovery (factory approach) |
| Test Result | 169.* APIPA, no WiFi | Pending |

## Configuration Details

### Network Configuration (`files/etc/config/network`)
```
LAN Interface:
- Name: lan
- Proto: static
- IP: 172.16.0.1
- Netmask: 255.255.248.0 (/21)
- Device: br-lan (bridge)
- Bridge Ports: eth1

WAN Interface:
- Name: wan
- Proto: dhcp
- Device: eth0

WAN IPv6:
- Name: wan6
- Proto: dhcpv6
- Device: eth0
```

### Board Script (`files/etc/board.d/02_network`)
Automatically configures for ariaboard,photonicat* boards:
```bash
ucidef_set_interfaces_lan_wan 'eth1' 'eth0'
```
This is the **critical function** that sets eth1 as LAN and eth0 as WAN.

### Wireless Packages
```
kmod-ath              - Atheros driver core
kmod-ath10k           - Atheros 10K (QCA988X, AR9888, etc)
kmod-ath11k           - Atheros 11K (QCA6390, QCN9074, etc)
wireless-tools        - iwconfig, iwlist utilities
wireless-regdb        - Regulatory database
```

## Next Steps

### When Build Completes
1. Image will be at: `build/openwrt/bin/targets/rockchip/armv8/openwrt-...img`
2. Flash to device using rkdeveloptool or flash.sh
3. Test:
   - Device should get 172.16.0.1 on LAN
   - WiFi SSID should broadcast
   - SSH to root@172.16.0.1 should work

### If Network Still Broken
1. Check board detection: `cat /proc/device-tree/compatible | tr '\0' '\n'`
2. Check if board.d scripts ran: `opkg log | grep 02_network`
3. Check network config: `uci show network`
4. Check interface status: `ip link show`

### Testing WiFi
```bash
# From device
iwconfig                    # Show wireless interfaces
iw dev wlan0 link          # Show connection status
# From client
nmcli dev wifi list         # Find SSID
nmcli dev wifi connect ...  # Connect
```

## Build Configuration (`configs/pcat2_custom.config`)

### Key Options (Current)
```
CONFIG_TARGET_rockchip=y
CONFIG_TARGET_rockchip_armv8=y
CONFIG_TARGET_rockchip_armv8_DEVICE_ariaboard_photonicat2=y
CONFIG_PACKAGE_kmod-ath=y
CONFIG_PACKAGE_kmod-ath10k=y
CONFIG_PACKAGE_kmod-ath11k=y
CONFIG_PACKAGE_wireless-tools=y
CONFIG_PACKAGE_wireless-regdb=y
CONFIG_PACKAGE_u-boot-generic-rk3576=y
CONFIG_PACKAGE_trusted-firmware-a-rk3576=y
```

## Known Issues & Workarounds

### Issue: Board Detection
If board scripts don't run, the board name must match `ariaboard,photonicat*` in device tree.
**Check**: `cat /proc/device-tree/compatible`

### Issue: WiFi Not Broadcasting
Factory image doesn't have `/etc/config/wireless` file - wireless is auto-discovered.
**Fix**: Ensure `wireless-tools` package is installed, reboot, check `iw list`

### Issue: DHCP on LAN
If DHCP server isn't running, check dnsmasq:
```bash
ps aux | grep dnsmasq
uci show dhcp
/etc/init.d/dnsmasq restart
```

## Files Cleaned Up in This Session

- Removed non-functional scripts from `uci-defaults/`
- Consolidated network configuration to factory-verified version
- Added board.d scripts for proper interface mapping

## Checkpoints

### ✅ Completed
- [x] Factory image mounted and analyzed
- [x] Network config extracted from factory image
- [x] Board scripts copied from factory
- [x] WiFi packages enabled in .config
- [x] Custom files directory updated
- [x] Clean rebuild started

### ⏳ In Progress
- [ ] Build completion (ETA: 30-60 min)
- [ ] Image testing on device
- [ ] Network verification (IP assignment, WiFi broadcast)
- [ ] SSH access confirmation

### 🔄 To Do
- [ ] SSH test to 172.16.0.1
- [ ] WiFi SSID broadcast verification
- [ ] Display functionality test
- [ ] NVMe mount on first boot
- [ ] Full system integration test

## Important Notes

### Critical Fix: Board Network Script
The `files/etc/board.d/02_network` script is the KEY to fixing the network issue. This script:
1. Runs on first boot
2. Detects board type from device tree
3. For `ariaboard,photonicat*`: sets eth1 as LAN, eth0 as WAN
4. Generates proper UCI configuration
5. Saves to `/etc/config/network`

Without this, the network configuration defaults are wrong.

### Factory Behavior
The factory image includes the same board.d script, which is why it works correctly. By copying this script and following the factory config approach, v3 should work properly.

---

**Session**: Nov 26, 2025 - Network Configuration Fix
**Status**: Build in progress
**Next Review**: When build completes (check build.log)
