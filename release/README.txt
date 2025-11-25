Photonicat 2 OpenWrt Release
Date: 2025-11-24

Images:
- openwrt-rockchip-armv8-armsom_sige7-squashfs-sysupgrade.img.gz: SquashFS image (Read-only rootfs + overlay) - Recommended
- openwrt-rockchip-armv8-armsom_sige7-ext4-sysupgrade.img.gz: Ext4 image (Read-write rootfs)

Changes:
- Added full package set for out-of-the-box functionality:
  - Network: firewall4, nftables, offloading support.
  - Modem: ModemManager, QMI/MBim drivers, LuCI protocol support.
  - WiFi: Drivers for Realtek (RTW88/89) and Mediatek (MT7921), WPA3 support.
  - System: htop, nano, curl, wget-ssl, git, pciutils, usbutils.
- Fixed build conflict with pcat2-display-mini package.
- Moved display configuration to uci-defaults script.
- Custom ping targets (google.com, openwrt.org) configured via setup script.
- Auto-start of display service enabled.
