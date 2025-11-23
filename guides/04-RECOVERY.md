# Photonicat 2 - Device Recovery Guide

Instructions for recovering Photonicat 2 from brick state, restoring factory firmware, or troubleshooting boot issues.

## Overview

This guide covers recovery procedures when:
- Device won't boot after flashing
- Need to restore original factory firmware
- Device is in "bricked" state
- Want to recover from a bad configuration

---

## Recovery Methods (Ordered by Simplicity)

1. **Software Recovery** - Reboot into recovery mode
2. **Maskrom Flashing** - Flash via USB (easiest hardware fix)
3. **Serial Console** - Access bootloader via UART
4. **TFTP Fallback** - Network-based firmware recovery
5. **Full Unbrick** - Last resort for hardware issues

---

## Method 1: Soft Reboot to Recovery

Simplest method if device is still partially functional:

```bash
# SSH into device
ssh root@192.168.1.1

# Trigger reboot to recovery
reboot -f

# Or command for recovery mode
reboot recovery

# Device will reboot into Rockchip recovery mode
# Then flash new firmware via maskrom
```

---

## Method 2: Maskrom Flashing (Most Common)

If device won't boot at all, use maskrom mode to reflash:

### Step 1: Enter Maskrom Mode

1. **Power off completely**
2. Locate power button on left side
3. **Press 3 times rapidly**, then **hold for 15 seconds**
4. Release button
5. **First LED will flash yellow** = maskrom mode confirmed
6. ⚠️ **DO NOT connect USB yet**

### Step 2: Connect and Flash

#### Windows

```batch
# Connect USB cable AFTER device is in maskrom mode
# Open RKDevTool
# Configure same as initial installation:
#   Row 1: RK3576_MiniLoaderAll.bin (Address: 0x00000000)
#   Row 2: photonicat2-openwrt-*-*.img (Address: 0x00000000)
# Click "Download" button
# Wait for completion message
```

#### Linux/Mac

```bash
# Verify maskrom is detected
rkdeveloptool ld
# Should show: Maskrom mode device

# Write bootloader
rkdeveloptool wl 0 RK3576_MiniLoaderAll.bin

# Write firmware
rkdeveloptool wl 0x0 photonicat2-openwrt-*-*.img

# Reboot into new firmware
rkdeveloptool rd
```

### Step 3: Boot New System

1. Device will auto-reboot
2. OpenWrt will load (wait 60-90 seconds)
3. Access via http://192.168.1.1

---

## Method 3: Restore Factory Firmware

If you backed up original firmware, restore it:

### Prerequisites

- Backup file: `photonicat2-factory-original.img.gz` (from backup)
- OR download pre-made factory image from https://dl.photonicat.com/images/photonicat2/

### Restore Steps

```bash
# Decompress factory image
gunzip photonicat2-factory-original.img.gz

# Enter maskrom mode on device (see Method 2, Step 1)

# Flash factory firmware
rkdeveloptool wl 0 RK3576_MiniLoaderAll.bin
rkdeveloptool wl 0x0 photonicat2-factory-original.img
rkdeveloptool rd

# Device boots with original factory firmware
```

---

## Method 4: Serial Console Access (Advanced)

If you have UART/TTL adapter, access bootloader directly:

### Pinout Diagram

```
Photonicat 2 PCB serial pins (when viewed from back):
┌─────────────────────────┐
│ [Antenna area]          │
│                         │
│  [Serial Pins]   [USB]  │
│  GND TX RX      3.0 Port
│   ●  ●  ●
│   1  2  3
└─────────────────────────┘

Pin 1: Ground (GND)
Pin 2: TX (3.3V logic)
Pin 3: RX (3.3V logic)
```

### Connect Serial Adapter

```
USB-to-TTL Adapter:
GND → Pin 1 (GND)
RX  → Pin 2 (TX)  # Note: RX connects to TX
TX  → Pin 3 (RX)  # Note: TX connects to RX
```

### Access Bootloader

```bash
# On Linux/Mac
screen /dev/ttyUSB0 1500000
# Or: minicom -D /dev/ttyUSB0 -b 1500000

# On Windows
# Use PuTTY or Tera Term
# COM port matching your adapter, 1500000 baud

# Boot messages will appear
# During U-Boot countdown, press any key to interrupt
# Access Rockchip bootloader

# Useful commands:
# boot           - Continue normal boot
# fastboot       - Enter fastboot mode
# help           - List available commands
```

---

## Method 5: TFTP Network Recovery (For advanced users)

If device has network access but corrupt firmware:

### Step 1: Setup TFTP Server

On your computer:

```bash
# Linux
sudo apt-get install tftpd-hpa
sudo systemctl start tftpd-hpa

# Copy firmware to TFTP root
sudo cp photonicat2-openwrt-*.img /srv/tftp/

# Mac
brew install tftp-hpa
sudo launchctl start homebrew.mxcl.tftp-hpa

# Windows - use TFTP server software
```

### Step 2: Access Bootloader via Serial

Follow Method 4 to access U-Boot console

### Step 3: Download via TFTP

In U-Boot bootloader:

```
# Set network parameters
setenv ipaddr 192.168.1.100
setenv netmask 255.255.255.0
setenv serverip 192.168.1.1

# Load firmware via TFTP
tftp 0x00200000 photonicat2-openwrt-*.img

# Write to flash
mmc write 0x00200000 0x0 0x4000

# Boot new firmware
boot
```

---

## Method 6: Full Unbrick (Last Resort)

Complete device recovery with JTAG (requires special hardware):

⚠️ **Only if:**
- Device completely unresponsive
- Maskrom mode unreachable
- Serial console doesn't respond

**Options:**
1. **Seek professional repair** - Photonicat may offer repair service
2. **JTAG Unbrick** - Requires JTAG adapter (expensive, risky)
3. **Device replacement** - If under warranty

For support: info@photonicat.com or https://github.com/photonicat/issues

---

## Troubleshooting Recovery

### Maskrom Device Not Appearing

**Problem**: "Device not found" in RKDevTool or rkdeveloptool

**Solutions**:
1. Verify in maskrom mode:
   ```bash
   lsusb | grep -i rockchip
   ```

2. Check USB drivers (Windows):
   - Device Manager for unknown device
   - Reinstall Rockchip drivers

3. Try different USB port

4. Use different USB cable (must be data cable, not charging)

5. Disable antivirus temporarily

### Flashing Fails Midway

**Problem**: "Download Failed" error during flashing

**Solutions**:
1. Don't disconnect - retry immediately
2. Check power - ensure sufficient battery
3. Check temperature - device shouldn't get hot
4. Try again with fresh bootloader: `RK3576_MiniLoaderAll.bin`
5. Consider corrupted firmware file - re-download

### Device Won't Boot After Recovery

**Problem**: Black screen after successful flash

**Solutions**:
1. Wait 2-3 minutes - might still be booting
2. Check for LED activity
3. Try accessing via SSH:
   ```bash
   ssh root@192.168.1.1  # password: password
   ```

4. Try recovery again with different firmware
5. Access serial console for boot messages

### Can't Enter Maskrom Mode

**Problem**: LED doesn't flash yellow with button sequence

**Solutions**:
1. Power off completely (5 second wait)
2. Try button sequence again slowly:
   - Tap TAP TAP (3 quick presses)
   - Hold for exactly 15 seconds
   - Release

3. Try holding button WHILE powering on
4. Watch LED carefully - yellow flash is quick (1 second)
5. Try different USB power source

---

## Prevention: Backup Your Firmware

Always backup before flashing:

```bash
# Via SSH (after first boot)
ssh root@192.168.1.1
dd if=/dev/mmcblk0 of=/tmp/photonicat2-backup.img bs=4M

# Transfer backup to computer
scp root@192.168.1.1:/tmp/photonicat2-backup.img ./

# Or via maskrom (before first boot)
# Use RKDevTool's "Read Flash" button
# Or rkdeveloptool: rkdeveloptool rl 0 0x1000 backup.img
```

---

## Important Files for Recovery

Keep these files on your computer:
- `RK3576_MiniLoaderAll.bin` (bootloader)
- Original factory firmware image
- Latest OpenWrt firmware
- RKDevTool (Windows) or rkdeveloptool (Linux/Mac)
- Rockchip USB drivers (Windows)

Store in: `~/photonicat2-recovery/`

---

## When All Else Fails

If device is unrecoverable:

1. **Contact Support**
   - Email: info@photonicat.com
   - GitHub Issues: https://github.com/photonicat/issues
   - Telegram: https://t.me/+IATZElRYPydkM2Rl

2. **Check Community**
   - Official Forum: https://photonicat.com/wiki
   - Community Forum: https://club.photonicat.cn/
   - GitHub Discussions

3. **Warranty Service**
   - If within 1-year warranty, contact seller
   - May offer device replacement or repair

---

**Last Updated**: November 2025  
**Device**: Photonicat 2 (RK3576)  
**Tested**: Recovery methods confirmed working
