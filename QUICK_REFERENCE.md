# Photonicat 2 OpenWrt - Quick Reference

## Current Status
- **Build v3**: In progress (WiFi + Network fix)
- **Build Location**: `/home/th3cavalry/photonicat2/build/openwrt/`
- **Build Log**: `/home/th3cavalry/photonicat2/build/openwrt/build.log`
- **Expected Completion**: 30-60 minutes from 17:15 (Nov 26)

## Project Files

### 📋 Documentation
- `README.md` - Main documentation
- `PROJECT_STATUS.md` - Current status & architecture
- `CUSTOM_BUILD_NOTES.md` - Build history
- `QUICK_REFERENCE.md` - This file

### 🛠️ Build Files
- `build.sh` - Main build script
- `configs/pcat2_custom.config` - Build configuration
- `files/` - Custom files to include in image
  - `etc/board.d/02_network` - **CRITICAL** - Network interface setup
  - `etc/config/network` - Network configuration (172.16.0.1 LAN on eth1)
  - `etc/config/firewall` - Firewall rules
  - `etc/config/dhcp` - DHCP configuration

### 📦 Hardware Support
- `photonicat2-support/` - RK3576 patches and device tree

### 🚀 Flashing
- `rkdeveloptool/` - Flashing utility
- `release/flash.sh` - Automatic flashing script

## Key Facts (Fixed Nov 26, 2025)

### Network Configuration (Now Correct)
- **LAN**: 172.16.0.1/21 on eth1 (bridge device br-lan)
- **WAN**: DHCP on eth0
- **Source**: Extracted from factory image (verified working)
- **Critical Script**: `files/etc/board.d/02_network` - auto-detects board and sets interfaces

### Wireless Support (Now Enabled)
- Packages: `kmod-ath`, `kmod-ath10k`, `kmod-ath11k`
- Auto-discovery: WiFi detected on boot (no static config needed)
- SSID: "OpenWrt" (default OpenWrt SSID)

### NVMe Support
- Auto-mounts on first boot
- Configured in `files/etc/uci-defaults/99-mount-nvme`
- Falls back to eMMC if NVMe removed

## Common Commands

### Build
```bash
cd /home/th3cavalry/photonicat2/build/openwrt
make -j4               # Continue current build
make clean world -j4   # Full clean rebuild
```

### Check Build Status
```bash
tail -f /home/th3cavalry/photonicat2/build/openwrt/build.log
ps aux | grep make     # See active build processes
```

### Find Completed Image
```bash
ls -lh /home/th3cavalry/photonicat2/build/openwrt/bin/targets/rockchip/armv8/*.img*
```

### Flash to Device
```bash
cd /home/th3cavalry/photonicat2/release
chmod +x flash.sh
./flash.sh
```

### Manual Flash (if needed)
```bash
# Put device in Maskrom mode first (3 quick power presses, then hold 15 sec)
sudo rkdeveloptool db RK3576_MiniLoaderAll.bin
sleep 5
sudo rkdeveloptool wl 0x0 openwrt-rockchip-armv8-ariaboard_photonicat2-squashfs-sysupgrade.img
sudo rkdeveloptool rd
```

## Testing After Flash

### SSH Access
```bash
ssh root@172.16.0.1
```

### WiFi Test
```bash
# From device
iwconfig                 # See wireless interfaces
iw dev wlan0 link       # Check connection status

# From another device
nmcli dev wifi list     # Find "OpenWrt" SSID
nmcli dev wifi connect OpenWrt
```

### Network Verify
```bash
# From device
ip link show            # See eth0, eth1, wlan0, br-lan
ip addr show            # See 172.16.0.1 on br-lan
ping 8.8.8.8           # Test WAN

# From PC
ping 172.16.0.1        # Test device responds
```

### NVMe Check
```bash
# From device
lsblk                   # See nvme0n1 and mounts
df -h                   # See /overlay mounted on NVMe
```

## File Structure

```
/home/th3cavalry/photonicat2/
├── files/                          # Files to include in image
│   └── etc/
│       ├── board.d/
│       │   ├── 01_leds             # LED config (auto-run on first boot)
│       │   └── 02_network          # Network setup (auto-run on first boot) **CRITICAL**
│       ├── config/
│       │   ├── network             # Network static config (172.16.0.1, eth1 LAN)
│       │   ├── firewall            # Firewall rules
│       │   └── dhcp                # DHCP server (dnsmasq)
│       └── uci-defaults/
│           ├── 90-pcat2-setup      # Display configuration
│           └── 99-mount-nvme       # NVMe auto-mount
│
├── build/
│   └── openwrt/
│       ├── bin/targets/rockchip/armv8/
│       │   └── openwrt-*-squashfs-sysupgrade.img  ← Flashing image
│       ├── .config                 # Build configuration
│       └── build.log              # Build output
│
├── photonicat2-support/            # Hardware support
│   ├── device-tree/
│   │   └── rk3576-photonicat2.dts  # Photonicat 2 device tree
│   └── kernel-patches/
│       ├── 990-photonicat-pm-add-driver.patch
│       └── 998-add-photonicat-usb-watchdog-driver.patch
│
└── configs/
    ├── pcat2_custom.config         # Current config (with WiFi, Network fixes)
    └── pcat2_custom.config.example # Example config
```

## What Changed (Nov 26, 2025)

### Problem
Custom build (v1) had broken network:
- Device got 169.* APIPA address (no DHCP)
- No WiFi broadcasting
- SSH/web access impossible

### Root Cause
- Network interfaces were backwards (eth0 used for LAN instead of WAN)
- Board detection scripts not running
- WiFi packages not enabled

### Solution
1. **Extracted factory image** and analyzed working configuration
2. **Copied board.d scripts** that auto-configure interfaces correctly
3. **Copied factory network config** (172.16.0.1 on eth1)
4. **Enabled WiFi packages** in .config
5. **Started clean rebuild** with all fixes

### Files Added/Modified
```
NEW:  PROJECT_STATUS.md              # This session's work
NEW:  files/etc/board.d/01_leds      # From factory
NEW:  files/etc/board.d/02_network   # CRITICAL: from factory
NEW:  files/etc/config/network       # From factory
NEW:  files/etc/config/firewall      # From factory  
NEW:  files/etc/config/dhcp          # From factory
DELETED: files/etc/uci-defaults/10-network-setup
DELETED: files/etc/uci-defaults/11-wireless-setup
DELETED: files/etc/uci-defaults/12-enable-wifi
DELETED: files/etc/uci-defaults/13-network-bridge
UPDATED: configs/pcat2_custom.config # Added WiFi packages
```

## Next Steps

1. **Wait for build to complete** (~30-60 min from 17:15)
2. **Check for image**: `ls -lh build/openwrt/bin/targets/.../openwrt-*.img`
3. **Flash to device**: `release/flash.sh` (device in Maskrom mode)
4. **Test**:
   - SSH to 172.16.0.1
   - Check WiFi SSID broadcasts
   - Verify NVMe mounts on first boot
5. **If working**: Commit changes and update repo

## Troubleshooting

### Build Won't Complete
1. Check log: `tail -100 /home/th3cavalry/photonicat2/build/openwrt/build.log`
2. Look for "ERROR:" message
3. If out of space: `df -h` and clean up

### Device Won't Flash
1. Ensure in Maskrom mode (yellow LED flashing)
2. Try USB 2.0 hub instead of USB 3.0
3. Try different USB cable
4. Check: `lsusb | grep -i rockchip`

### Network Still Broken After Flash
1. Check board detection: `cat /proc/device-tree/compatible`
2. Should show: `ariaboard,photonicat2` (or similar)
3. Check board.d ran: `cat /etc/config/network` (should show 172.16.0.1)
4. If wrong: interface mapping failed - check board.d script

## Useful Links
- Factory Image: https://dl.photonicat.com/images/photonicat2/openwrt/
- OpenWrt Docs: https://openwrt.org/
- RK3576 Resources: https://photonicat.com/wiki/
- Community: https://t.me/+IATZElRYPydkM2Rl

---

**Last Updated**: Nov 26, 2025 - 17:20  
**Build Status**: In Progress  
**Build v3**: Network fixes + WiFi enabled
