# Photonicat 2 - LCD Screen Setup Guide

Complete guide for enabling and configuring the 1.28-inch LCD display on Photonicat 2 running OpenWrt.

> 📖 **For comprehensive customization**: See [06-SCREEN_AND_FAN_DETAILED.md](./06-SCREEN_AND_FAN_DETAILED.md) for complete documentation on all configuration options, data keys, element types, colors, and examples.

## Overview

The Photonicat 2 includes a built-in 172×320 pixel LCD display with the GC9307 controller. This guide enables the display driver and installs the pcat2_mini_display service for real-time system monitoring.

### Display Specifications

- **Model**: GC9307 SPI LCD controller
- **Resolution**: 172×320 pixels (portrait orientation)
- **Physical Size**: 1.28" (32mm diagonal)
- **Rotation**: 180 degrees
- **Interface**: SPI (3-wire or 4-wire)
- **GPIO Pins**:
  - RST (Reset): GPIO 122
  - DC (Data/Command): GPIO 121
  - CS (Chip Select): GPIO 13
  - SPI Bus: SPI1 (/dev/spidev1.0)
- **Backlight**: PWM controlled
- **Color Depth**: 16-bit RGB565
- **Refresh Rate**: 5 FPS (target, configurable)

### What Gets Displayed

The pcat2_mini_display application shows:
- **Top Bar** (32px): Time, signal strength, WiFi status, battery level
- **Main Content**: Rotating pages with stats:
  - Page 0: WAN speeds, data usage, battery details
  - Page 1: Ping results, IP addresses, connectivity
  - Page 2: CPU, memory, uptime, system info
  - Page 3: ISP info, cell bands, SIM status, temperatures
  - SMS Pages: Incoming messages (if enabled)
- **Footer** (22px): Page indicators, SMS counter

---

## Prerequisites

Before starting, ensure:
1. ✓ OpenWrt is freshly installed on Photonicat 2
2. ✓ Device is powered on and booted
3. ✓ SSH access: `ssh root@192.168.1.1` (password: `password`)
4. ✓ Internet connection available (for package downloads)
5. ✓ eMMC has at least 100MB free space

---

## Step 1: Install Kernel Modules

Connect to device via SSH and install SPI and GPIO drivers:

```bash
ssh root@192.168.1.1

# Update package lists
opkg update

# Install SPI and GPIO kernel modules
opkg install kmod-spi-dev kmod-spi-bitbang

# Verify modules loaded
lsmod | grep -i spi
# Output should show: spi_bitbang, spidev
```

---

## Step 2: Install pcat2_mini_display Binary

### Option A: Built-in Package (Default for this repo)

If you built your image using this repository (which uses `configs/pcat2_custom.config`), the `pcat2-display-mini` package is **already installed and configured**.

You can verify it by running:
```bash
opkg list-installed | grep pcat2-display-mini
```
If installed, the service should be running automatically. You can skip to **Step 3: Configure Service**.

### Option B: Download Pre-Built Binary (For Stock Firmware)

```bash
# Create application directory
mkdir -p /opt/pcat2_mini_display

# Download latest binary
cd /opt/pcat2_mini_display
wget -O pcat2_mini_display https://dl.photonicat.com/images/photonicat2/pcat2_mini_display
chmod +x pcat2_mini_display

# Verify binary
./pcat2_mini_display --version
# Should show: pcat2_mini_display version X.X.X
```

### Option B: Compile from Source

```bash
# Install Go compiler
opkg install golang

# Clone repository
cd /tmp
git clone https://github.com/photonicat/photonicat2_mini_display.git
cd photonicat2_mini_display

# Compile for ARM64
export GOARCH=arm64
export GOOS=linux
go build -o pcat2_mini_display

# Copy to system directory
mkdir -p /opt/pcat2_mini_display
cp pcat2_mini_display /opt/pcat2_mini_display/
chmod +x /opt/pcat2_mini_display/pcat2_mini_display
```

---

## Step 3: Install Configuration Files

### Download Default Configuration

```bash
cd /opt/pcat2_mini_display

# Download default config
wget -O config.json https://raw.githubusercontent.com/photonicat/photonicat2_mini_display/main/config.json

# Download assets (fonts and icons)
wget -O assets.tar.gz https://dl.photonicat.com/images/photonicat2/pcat2_mini_display_assets.tar.gz
tar -xzf assets.tar.gz

# Set permissions
chmod 644 config.json
chmod -R 755 assets/
```

### Create System Config Directory

```bash
# Copy config to system location
cp config.json /etc/pcat2_mini_display-config.json
cp -r assets /usr/share/pcat2_mini_display/assets

# Set permissions
chmod 644 /etc/pcat2_mini_display-config.json
```

---

## Step 4: Configure Service

The `pcat2-display-mini` package includes an OpenWrt init script.

```bash
# Enable service to start on boot
/etc/init.d/pcat2-display-mini enable

# Start service now
/etc/init.d/pcat2-display-mini start

# Check status (check if process is running)
ps | grep photonicat2_mini_display
```

---

## Step 5: Enable GPIO and SPI Devices

### Configure GPIO Pins

```bash
# Create GPIO initialization script
cat > /etc/init.d/gpio_init << 'GPIOEOF'
#!/bin/sh /etc/rc.common

START=90
STOP=10

start() {
    # Export GPIO pins
    echo 122 > /sys/class/gpio/export 2>/dev/null || true
    echo 121 > /sys/class/gpio/export 2>/dev/null || true
    echo 13 > /sys/class/gpio/export 2>/dev/null || true
    
    # Set as output
    echo out > /sys/class/gpio/gpio122/direction
    echo out > /sys/class/gpio/gpio121/direction
    echo out > /sys/class/gpio/gpio13/direction
    
    # Initial state (high)
    echo 1 > /sys/class/gpio/gpio122/value
    echo 1 > /sys/class/gpio/gpio121/value
    echo 1 > /sys/class/gpio/gpio13/value
    
    echo "GPIO initialized for LCD display"
}

stop() {
    # Cleanup GPIO
    echo 122 > /sys/class/gpio/unexport 2>/dev/null || true
    echo 121 > /sys/class/gpio/unexport 2>/dev/null || true
    echo 13 > /sys/class/gpio/unexport 2>/dev/null || true
    echo "GPIO cleaned up"
}
GPIOEOF

chmod +x /etc/init.d/gpio_init
/etc/init.d/gpio_init enable
/etc/init.d/gpio_init start
```

### Enable SPI Device

```bash
# Check SPI device availability
ls -l /dev/spidev*
# Should show: /dev/spidev1.0

# If not visible, load SPI modules
modprobe spi_bitbang
modprobe spidev

# Make persistent
echo "spi_bitbang" >> /etc/modules
echo "spidev" >> /etc/modules
```

---

## Step 6: Start LCD Display Service

### Manual Test (First Run)

```bash
# Run directly to check for errors
/opt/pcat2_mini_display/pcat2_mini_display

# Expected output:
# Initializing GC9307 SPI LCD display...
# Display initialized successfully
# Starting main loop...
# FPS: 5.0, Rendering page 0

# If you see this, display is working! (Ctrl+C to stop)
```

### Start as Service

```bash
# Enable service to start on boot
/etc/init.d/pcat2-display-mini enable

# Start service now
/etc/init.d/pcat2-display-mini start

# Restart service
/etc/init.d/pcat2-display-mini restart
```

---

## Step 7: Configure Display Settings

### Edit Configuration File

```bash
# Default config location
nano /etc/pcat2_mini_display-config.json
```

### Key Configuration Options

```json
{
  "display": {
    "width": 172,
    "height": 320,
    "rotation": 180,
    "backlight_gpio": 11,
    "refresh_rate_fps": 5
  },
  "pages": [
    {
      "id": 0,
      "name": "Network Stats",
      "elements": ["wan_speed", "data_usage", "battery"]
    },
    {
      "id": 1,
      "name": "Ping Results",
      "elements": ["ping_results", "ip_addresses"]
    }
  ],
  "ping_targets": {
    "site_0": "8.8.8.8",
    "site_1": "1.1.1.1"
  },
  "update_intervals": {
    "system_data_ms": 2000,
    "network_data_ms": 2000,
    "display_fps": 200
  }
}
```

### Common Customizations

**Change Ping Targets**:
```json
"ping_targets": {
  "site_0": "your-primary-dns.com",
  "site_1": "your-secondary-dns.com"
}
```

**Adjust Brightness**:
```json
"display": {
  "max_brightness": 100,
  "idle_brightness": 30,
  "dimmer_timeout_sec": 60
}
```

**Disable SMS Display**:
```json
"sms": {
  "enabled": false
}
```

After editing, restart service:
```bash
/etc/init.d/pcat2-display-mini restart
```

---

## Build-time Customization

If you are building your own OpenWrt image, you can customize the display configuration by creating a `uci-defaults` script. This ensures your custom settings are applied automatically on the first boot.

**Do not** place a custom config file at `files/etc/pcat2_mini_display-config.json` in your build root, as this will conflict with the package installation.

Instead, create a script at `files/etc/uci-defaults/90-pcat2-setup`:

```bash
#!/bin/sh

# Write custom display configuration
cat <<EOF > /etc/pcat2_mini_display-config.json
{
    "ping_site0": "google.com",
    "ping_site1": "openwrt.org",
    "show_sms": true,
    "screen_dimmer_time_on_battery_seconds": 60,
    "screen_dimmer_time_on_dc_seconds": 86400,
    "screen_max_brightness": 100,
    "screen_min_brightness": 0,
    "display_template": {
        "elements": {
            "page0": [
                {
                    "type": "text",
                    "label": "My Custom Page",
                    "position": {"x": 10, "y": 10},
                    "font": "big",
                    "color": [255, 255, 255],
                    "enable": 1
                }
            ]
        }
    }
}
EOF

# Enable and start the display service
if [ -x /etc/init.d/pcat2-display-mini ]; then
    /etc/init.d/pcat2-display-mini enable
    /etc/init.d/pcat2-display-mini start
fi

exit 0
```

This method avoids file collisions during the build process.

---

## Step 8: Verify Display Functionality

### Check Display Output

1. **Visual Confirmation**:
   - Screen should light up within 5 seconds of service start
   - Display should show real-time system data
   - Pages should rotate every 30 seconds (configurable)

2. **Test Page Rotation**:
   - Device shows current page indicator at bottom
   - Navigate pages via GPIO pins or API

3. **Monitor Service**:
   ```bash
   # Watch service logs in real-time
   logread -f -e pcat2-display-mini
   
   # Check system resources used
   ps | grep pcat2_mini_display
   ```

### Access Display API

The service exposes HTTP API for control:

```bash
# Get current backlight level
curl http://localhost:8080/api/v1/go_get_max_backlight
# Response: {"status":"ok","max_brightness":100}

# Set backlight to 75%
curl -X POST -d "max_brightness=75" \
  http://localhost:8080/api/v1/go_set_max_backlight
# Response: {"status":"ok","max_brightness":75}

# Dim to minimum
curl -X POST -d "max_brightness=1" \
  http://localhost:8080/api/v1/go_set_max_backlight
```

---

## Troubleshooting

### Display Not Showing

**Problem**: Screen remains dark after starting service

**Solutions**:
1. Check GPIO initialization:
   ```bash
   cat /sys/class/gpio/gpio122/value
   # Should return: 1 (high)
   ```

2. Verify SPI device:
   ```bash
   ls -l /dev/spidev1.0
   chmod 666 /dev/spidev1.0  # Allow access
   ```

3. Check service logs:
   ```bash
   logread | grep pcat2-display-mini | tail -n 50
   # Look for error messages
   ```

4. Verify binary permissions:
   ```bash
   ls -l /opt/pcat2_mini_display/pcat2_mini_display
   chmod +x /opt/pcat2_mini_display/pcat2_mini_display
   ```

### Garbled/Corrupted Display

**Problem**: Screen shows random pixels or corrupted text

**Solutions**:
1. Reduce refresh rate in config.json:
   ```json
   "display": {"refresh_rate_fps": 3}
   ```

2. Check SPI clock speed:
   ```bash
   # GC9307 typically supports up to 50MHz
   # If errors occur, reduce to 25MHz in device tree
   ```

3. Verify GPIO connections (software):
   ```bash
   # Test GPIO pins manually
   echo 0 > /sys/class/gpio/gpio122/value  # RST low
   sleep 0.1
   echo 1 > /sys/class/gpio/gpio122/value  # RST high
   ```

### Service Crashes Frequently

**Problem**: Service keeps restarting

**Solutions**:
1. Check for memory issues:
   ```bash
   free -h  # Check available RAM
   dmesg | tail -20  # Check kernel errors
   ```

2. Review configuration syntax:
   ```bash
   # Validate JSON
   python3 -m json.tool /etc/pcat2_mini_display-config.json
   ```

3. Run with debug output:
   ```bash
   # Stop the service first
   /etc/init.d/pcat2-display-mini stop
   
   # Run manually to see output
   /usr/bin/pcat2_mini_display
   
   # Or check logs
   logread -f -e pcat2-display-mini
   ```

### High CPU Usage

**Problem**: Display service consuming >20% CPU

**Solutions**:
1. Reduce refresh rate:
   ```json
   "display": {"refresh_rate_fps": 2}
   ```

2. Disable expensive data collection:
   ```json
   "update_intervals": {
     "network_speed_ms": 5000,  # Increase interval
     "sms_check_ms": 10000
   }
   ```

3. Disable SMS if not needed:
   ```json
   "sms": {"enabled": false}
   ```

---

## Advanced: Building Custom Display Application

If you need custom display functionality, the source is available:

```bash
# Clone repository
git clone https://github.com/photonicat/photonicat2_mini_display.git
cd photonicat2_mini_display

# Build for Photonicat 2 (ARM64)
export GOARCH=arm64
export GOOS=linux
go build -v

# Or use cross-compilation tool
./compile.sh
```

Reference: https://github.com/photonicat/photonicat2_mini_display

---

## Next Steps

Display is now working! Proceed to:
1. Configure **5G/4G modem** → [03-5G_MODEM_SETUP.md](./03-5G_MODEM_SETUP.md)
2. Set up **network connectivity** → OpenWrt web UI
3. Install **additional packages** → System → Software

---

**Last Updated**: November 2025  
**Device**: Photonicat 2 (RK3576)  
**Display Controller**: GC9307  
**Application**: pcat2_mini_display v1.0+
