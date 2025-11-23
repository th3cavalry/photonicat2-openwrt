# Photonicat 2 - OpenWrt Installation & Flashing Guide

Complete step-by-step instructions for flashing OpenWrt to Photonicat 2 using USB maskrom mode.

## ⭐ Note: Firmware Preparation

**Before following this guide, you need an OpenWrt image. Choose one:**

### PRIMARY: Build Your Own Image (Recommended)
Follow [../BUILD_QUICK_START.md](../BUILD_QUICK_START.md) to compile custom firmware:
```bash
./scripts/build-openwrt.sh --full --extract --backup
```
This gives you the latest features, security updates, and full customization.

### ALTERNATIVE: Use Pre-Built Image
Download from: https://dl.photonicat.com/images/photonicat2/openwrt/

**Once you have your image (either built or pre-built), continue with the flashing steps below.**

---

## Table of Contents
1. [Prerequisites & Preparation](#prerequisites--preparation)
2. [Download Required Files](#download-required-files)
3. [Windows Installation](#windows-installation)
4. [Linux/Mac Installation](#linuxmac-installation)
5. [Post-Flash Setup](#post-flash-setup)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites & Preparation

### Hardware Requirements
- ✓ Photonicat 2 device (RK3576 based)
- ✓ USB Type-A to Type-A cable (standard USB data cable)
- ✓ Computer (Windows, Linux, or Mac)
- ✓ Fully charged battery or external power
- ✓ OpenWrt image (built or pre-built)

### What You'll Lose
- ⚠️ All data on internal storage (eMMC)
- ⚠️ Original factory firmware (can be restored from backup)
- ⚠️ Any previously installed apps or configurations

### What You'll Gain
- ✅ Fresh, clean OpenWrt installation
- ✅ Full customization capabilities
- ✅ Latest security updates
- ✅ Preservation of: LCD screen, 5G modem, WiFi, battery management

---

## Download Required Files

### Step 1: Create Working Directory
Create a folder on your computer to organize all files:
```
~/photonicat2-install/
├── firmware/
├── bootloader/
├── tools/
└── backups/
```

### Step 2: Download Official Firmware

**Official Photonicat 2 OpenWrt**
- URL: https://dl.photonicat.com/images/photonicat2/openwrt/
- Download the latest `photonicat2-openwrt-*-photonicat2-*.img.gz` file
- Extract to get the `.img` file

Example:
```bash
# Extract the firmware
gunzip photonicat2-openwrt-*-photonicat2-*.img.gz
# Result: photonicat2-openwrt-*-photonicat2-*.img
```

### Step 3: Download Bootloader

**RK3576 MiniLoader**
- URL: https://dl.photonicat.com/images/photonicat2/
- Download: `RK3576_MiniLoaderAll.bin`

### Step 4: Download Flashing Tools

#### For Windows
**RKDevTool v2.86+**
- Download: https://dl.photonicat.com/tools/RKDevTool_Release_v2.86.zip
- Extract to a folder (e.g., `C:\RKDevTool\`)

**Rockchip USB Drivers**
- Download: https://dl.photonicat.com/tools/DriverAssitant_v5.1.1.zip
- Contains: Driver installer for Rockchip devices

**Installation Steps (Windows)**:
1. Extract DriverAssitant_v5.1.1.zip
2. Run `DriverInstall.exe` (right-click → Run as Administrator)
3. Click "Install Driver" to install Rockchip USB drivers
4. Reboot computer (recommended)
5. Extract RKDevTool_Release_v2.86.zip

#### For Linux
**rkdeveloptool**
```bash
# Ubuntu/Debian
sudo apt-get install rockchip-tools

# Or compile from source
git clone https://github.com/rockchip-linux/rkdeveloptool
cd rkdeveloptool
autoreconf -i
./configure
make
sudo make install
```

#### For Mac
**rkdeveloptool via Homebrew**
```bash
brew install rkdeveloptool
```

---

## Windows Installation

### Step 1: Prepare Device for Flashing

**Enter Maskrom Mode** (CRITICAL):
1. Power off Photonicat 2 completely
2. Locate the small button on the left side of the device
3. **Press button 3 times rapidly, then press and hold for 15 seconds**
4. Release button (first LED will blink rapidly in yellow)
5. LED status confirms maskrom mode is active

**Visual Guide:**
```
[POWER OFF]
    ↓
[TAP 3x QUICKLY]
    ↓
[HOLD 15 SECONDS]
    ↓
[LED FLASHES YELLOW] ← Maskrom mode confirmed
```

### Step 2: Connect USB Cable

⚠️ **IMPORTANT**: Connect USB cable **AFTER** entering maskrom mode

1. Device already in maskrom mode (yellow LED flashing)
2. Connect USB Type-A to Type-A cable
3. Connect to USB port on TOP of device (USB 3.0 port)
4. Connect other end to Windows computer
5. Windows will detect new USB device (Rockchip Device in Device Manager)

### Step 3: Configure RKDevTool

1. **Open RKDevTool.exe** (from extracted folder)
2. Click "下载镜像" / "Download Image" button
3. In the image configuration table:
   - **Row 1 (Address 0x00000000)**:
     - Path: `RK3576_MiniLoaderAll.bin`
     - Check: ✓ Execute
   - **Row 2 (Address 0x00000000)**:
     - Path: `photonicat2-openwrt-*-photonicat2-*.img`
     - Check: ✓ (should be auto-filled)

4. Click "下载" / "Download" button to start flashing

### Step 4: Wait for Completion

- Flashing progress will show in real-time
- Expected time: **1-2 minutes**
- Wait for message: "下载完成" / "Download Complete"
- Device screen should light up when complete
- Do NOT disconnect USB or power off during flashing

### Step 5: Post-Flash Steps

1. Unplug USB cable
2. Device will boot automatically or press power button
3. OpenWrt will boot (screen may show boot output)
4. Wait for WiFi/network to stabilize (30-60 seconds)
5. Device accessible at default IP: `192.168.1.1`

---

## Linux/Mac Installation

### Step 1: Prepare Device for Flashing

Same as Windows - enter maskrom mode:

```bash
# On device: Press button 3x rapidly, hold 15 seconds
# LED will blink yellow when ready
```

### Step 2: Connect USB Cable

```bash
# Connect device to computer
# Verify connection
lsusb | grep Rockchip
# Should show: Bus XXX Device XXX: ID 2207:0010 Rockchip Electronics Co., Ltd. ...
```

### Step 3: Flash Using rkdeveloptool

```bash
# Verify device is in maskrom mode
rkdeveloptool ld

# Expected output:
# DevNo=1 Vid=0x2207,Pid=0x0010,LocationID=XXX SerialNumber=...

# Write bootloader
rkdeveloptool wl 0 RK3576_MiniLoaderAll.bin

# Write firmware image
rkdeveloptool wl 0x0 photonicat2-openwrt-*-photonicat2-*.img

# Reboot device
rkdeveloptool rd
```

### Step 4: Complete and Verify

```bash
# Device will reboot automatically
# Monitor boot process
watch 'rkdeveloptool ld'

# When device disappears from output, it's booting into OpenWrt
# Give it 60 seconds to fully boot
```

---

## Post-Flash Setup

### Initial Boot

1. **Wait 60 seconds** for OpenWrt to fully boot
2. **Check LED indicators**:
   - Solid LED = System operational
   - LED patterns = Network activity
3. **Access web interface**: http://192.168.1.1
4. **Default credentials**:
   - Username: `root`
   - Password: `password`

### First Time Configuration

1. **Change Admin Password** (CRITICAL for security)
   - System → Administration → Change Password
   - Or via SSH: `passwd`

2. **Configure Network**
   - Network → Interfaces
   - Rename: `br-lan` for LAN devices
   - Configure WAN (5G/4G modem will appear as available interface)

3. **Enable SSH** (if needed)
   - System → Administration → SSH
   - Generate SSH keys or use password auth

4. **Set Hostname**
   - System → System Settings
   - Change hostname from default

### Next Steps

After initial setup, proceed to:
- [02-LCD_SCREEN_SETUP.md](./02-LCD_SCREEN_SETUP.md) - Enable LCD display
- [03-5G_MODEM_SETUP.md](./03-5G_MODEM_SETUP.md) - Configure 5G connectivity
- [02-LCD_SCREEN_SETUP.md](./02-LCD_SCREEN_SETUP.md) - Display driver

---

## Troubleshooting

### Device Not Detected (Windows)

**Problem**: RKDevTool shows no device after entering maskrom mode

**Solutions**:
1. Uninstall antivirus temporarily (Huorui known to block drivers)
2. Run RKDevTool as Administrator
3. Reinstall Rockchip drivers:
   ```
   Device Manager → Find unknown device → Right-click → Delete
   Rerun DriverAssitant to reinstall
   ```
4. Try different USB port (preferably USB 2.0 port)
5. Use different USB cable (must be USB-A to USB-A data cable)
6. Check Event Viewer for driver errors

### Device Not Detected (Linux/Mac)

**Problem**: `lsusb` doesn't show Rockchip device

**Solutions**:
```bash
# Check for permission issues
sudo dmesg | tail -20

# Grant user permission to USB device
sudo usermod -aG dialout $USER
sudo usermod -aG plugdev $USER

# Reload USB database
sudo systemctl restart udev

# Try again
lsusb | grep Rockchip
```

### Flashing Fails Midway

**Problem**: "Download Failed" or connection lost

**Solutions**:
1. **Stop**: Do NOT disconnect or power off
2. **Retry**: Click "Download" again in RKDevTool
3. **Check Cable**: Verify USB cable is secure
4. **Check Power**: Ensure device has sufficient charge
5. **Reset**: 
   - Disconnect USB
   - Re-enter maskrom mode
   - Reconnect and retry

### Device Won't Boot After Flashing

**Problem**: Device is powered on but not connecting/responding

**Solutions**:
1. **Wait**: Give device 2-3 minutes to boot initially
2. **Check LED**: Should show signs of activity
3. **Access via SSH**: 
   ```bash
   ssh root@192.168.1.1
   # Default password: password
   ```
4. **Check Serial Console** (if available):
   - TTL pins on PCB - requires serial adapter
   - Allows viewing boot messages

### Web Interface Not Accessible

**Problem**: Can't reach http://192.168.1.1

**Solutions**:
1. Verify device is powered on and booted
2. Check network connection: `ping 192.168.1.1`
3. If no ping response:
   - Device may still be booting (wait 2-3 minutes)
   - Try SSH: `ssh root@192.168.1.1`
   - Check if in recovery mode
4. Reset network settings:
   - Power off device
   - Power on and wait 5 minutes

### Need to Restore Factory Firmware

See [04-RECOVERY.md](./04-RECOVERY.md) for instructions on reverting to original firmware.

---

## Next Steps

✓ OpenWrt is now installed on your Photonicat 2!

Proceed with configuration:
1. Enable and configure **LCD screen** → [02-LCD_SCREEN_SETUP.md](./02-LCD_SCREEN_SETUP.md)
2. Set up **5G/4G connectivity** → [03-5G_MODEM_SETUP.md](./03-5G_MODEM_SETUP.md)
3. Configure **network and WiFi** → Web UI System settings
4. Install **optional packages** → System → Software

---

**Last Updated**: November 2025  
**Device**: Photonicat 2 (RK3576)  
**Tested On**: OpenWrt 24.10 stable
