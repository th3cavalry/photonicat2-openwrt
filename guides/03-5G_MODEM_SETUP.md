# Photonicat 2 - 5G/4G Modem Configuration Guide

Complete guide for configuring 5G and 4G LTE connectivity on Photonicat 2 running OpenWrt.

## Overview

Photonicat 2 supports cellular connectivity through Quectel modems (RM500 or RM520 series). This guide covers driver installation, modem detection, and configuration for both QMI and AT command interfaces.

### Supported Modems

- **Quectel RM500Q-GL**: Full 5G + 4G support (global bands)
- **Quectel RM520N-GL**: Full 5G + 4G support (global bands)
- Interface: USB or M.2 B-Key slot
- Bands: All global 4G LTE and 5G NR bands

### Connection Methods

1. **USB-based** (easiest): Modem appears as `/dev/ttyUSB*`
2. **M.2 B-Key**: Modem integrated directly on M.2 slot

---

## Prerequisites

1. ✓ OpenWrt installed on Photonicat 2
2. ✓ Display working (optional, for monitoring)
3. ✓ Valid SIM card inserted in device
4. ✓ SSH access to device
5. ✓ Internet connection via WiFi (for downloading packages)

---

## Step 1: Install Required Packages

```bash
ssh root@192.168.1.1

# Update package lists
opkg update

# Install cellular management packages
opkg install modemmanager modemmanger-data qmi-utils kmod-usb-serial-option kmod-usb-serial-wwan

# Optional: Install for advanced configuration
opkg install atinout chat ppp ppp-mod-pppoe
```

---

## Step 2: Detect Modem Hardware

### Check if Modem is Detected

```bash
# List USB devices
lsusb | grep -i quectel

# Expected output:
# Bus XXX Device XXX: ID 2c7c:0125 Quectel Wireless Solutions Co., Ltd. EC25 4G modem
# or
# Bus XXX Device XXX: ID 2c7c:0309 Quectel Wireless Solutions Co., Ltd. RM500Q-GL
# or
# Bus XXX Device XXX: ID 2c7c:0512 Quectel Wireless Solutions Co., Ltd. RM520N-GL

# Check serial ports created
ls -la /dev/ttyUSB*

# Expected output:
# /dev/ttyUSB0  (DM port - firmware download)
# /dev/ttyUSB1  (AT command port)
# /dev/ttyUSB2  (PPP data port)
# /dev/ttyUSB3  (GPS port - if available)
```

### If Modem Not Detected

```bash
# Check kernel logs
dmesg | grep -i "usb\|modem\|quectel"

# Manually modprobe drivers
modprobe option
modprobe usb_wwan
modprobe qmi_wwan

# Check again
lsusb | grep -i quectel
```

---

## Step 3: Install Firmware (If Needed)

Check if modem firmware is current:

```bash
# Query modem version
minicom -D /dev/ttyUSB1 -b 115200
# In minicom, type: AT+GMR
# Should show: RM500Q-GL or RM520N-GL with version

# Exit minicom: Ctrl+A, then X
```

If firmware update needed:
- Download from: https://www.quectel.com/cn/product/rm500q-gl/ (Chinese site)
- Use Quectel's official flash tool
- Not typically necessary for basic operation

---

## Step 4: Configure QMI Interface

QMI (Qualcomm MSM Interface) is the preferred method for modern 5G modems.

### Step 4a: Find QMI Device

```bash
# List QMI ports
ls -la /dev/cdc-wdm*

# Expected: /dev/cdc-wdm0
# If not present, create it
mknod /dev/cdc-wdm0 c 180 0
chmod 666 /dev/cdc-wdm0
```

### Step 4b: Test QMI Connection

```bash
# Query modem capabilities
qmicli -d /dev/cdc-wdm0 --device-open-net='net-raw-ip|net-qos-header' --wds-get-data-bearer-technology

# Expected output showing connection technology (LTE, NR, etc.)

# Get SIM status
qmicli -d /dev/cdc-wdm0 --dms-get-sim-state

# Expected: [dms-get-sim-state]
#   SIM state: SIM ready
```

### Step 4c: Get Network Information

```bash
# Check network registration
qmicli -d /dev/cdc-wdm0 --nas-get-serving-system

# Example output:
#   Serving system info:
#   Registration state: 'registered'
#   CS: 'registered'
#   PS: 'registered'
#   ...
```

---

## Step 5: Configure ModemManager

ModemManager provides a high-level interface for modem control.

### Step 5a: Start ModemManager

```bash
# Start service
/etc/init.d/modemmanager enable
/etc/init.d/modemmanager start

# Verify running
ps | grep ModemManager

# Check logs
logread -f -e ModemManager
```

### Step 5b: List Modems

```bash
# View all modems
mmcli -L

# Expected output:
# /org/freedesktop/ModemManager1/Modem/0

# Get detailed modem info
mmcli -m 0

# Shows: Model, IMEI, IMSI, capabilities, bands, etc.
```

### Step 5c: Enable Mobile Broadband

```bash
# Create mobile broadband connection
mmcli -m 0 --enable

# Set allowed mode (auto, 3g, 4g, 5g)
mmcli -m 0 --set-allowed-modes=5g

# Verify settings
mmcli -m 0 | grep Allowed
```

---

## Step 6: Configure Network Interface

### Option A: Using LuCI Web Interface (Easiest)

1. Access http://192.168.1.1
2. Navigate: Network → Interfaces → Create New
3. Select Protocol: "Mobile Broadband (ModemManager)"
4. Modem should auto-detect
5. Select APN for your carrier (see APN list below)
6. Click Save & Apply

### Option B: Manual Configuration (Advanced)

Create network configuration file:

```bash
cat > /etc/config/network << 'EOF'
config interface 'wan_mobile'
    option type 'modem'
    option device '/dev/cdc-wdm0'
    option proto 'qmi'
    option apn 'your-carrier-apn'
    option pincode ''  # Leave blank if no SIM PIN
    option username ''
    option password ''

config firewall
    option wan_zone 'wan'
    option wan_mobile_zone 'wan'
