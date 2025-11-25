# Photonicat 2 LCD Display and Fan Support

## Overview

The Photonicat 2 includes two important hardware features that require software support:

1. **LCD Display** - GC9307 SPI LCD (172x320 pixels) showing system status
2. **Cooling Fan** - PWM-controlled fan for thermal management

This document explains how to enable these features with vanilla OpenWrt.

> 📖 **For comprehensive configuration guide**: See [guides/06-SCREEN_AND_FAN_DETAILED.md](../guides/06-SCREEN_AND_FAN_DETAILED.md) for complete documentation including all display configuration options, data keys, element types, color schemes, configuration examples, and detailed fan control options.

## LCD Display Support

### Hardware Specifications

- **Controller**: GC9307 SPI LCD
- **Resolution**: 172x320 pixels
- **Interface**: SPI (SPI1)
- **GPIO Pins**: 
  - RST (Reset): GPIO 122
  - DC (Data/Command): GPIO 121
  - CS (Chip Select): GPIO 13
- **Backlight**: PWM-controlled (PWM2)
- **Rotation**: 180 degrees

### Device Tree Support

The LCD is defined in the device tree (`rk3576-photonicat2.dts`):
- SPI1 interface configuration
- PWM backlight control
- GPIO pin assignments

### Display Application

The display is driven by **pcat2_mini_display**, a Go-based application that:
- Renders system information to the LCD
- Shows real-time stats (CPU, memory, network, battery)
- Displays 5G modem status and signal strength
- Shows SMS messages
- Provides customizable screens
- HTTP API for remote control

**Repository**: https://github.com/photonicat/photonicat2_mini_display

### Required Packages

Add this to your `configs/pcat2_custom.config`:

```
# LCD Display Application (includes required kernel modules)
CONFIG_PACKAGE_pcat2-display-mini=y
```

# Framebuffer support
CONFIG_PACKAGE_kmod-fb=y
CONFIG_PACKAGE_kmod-fb-sys-fops=y

# Additional display support
CONFIG_PACKAGE_kmod-backlight=y
```

### Building with Display Support

#### Option 1: Add Display Package to Build (Recommended for Full Functionality)

1. **Copy the display package to OpenWrt build**:
   ```bash
   # After running ./build.sh and it clones OpenWrt
   cd build/openwrt
   mkdir -p package/custom
   cp -r ../../photonicat2-support/packages/pcat2-display-mini package/custom/
   ```

2. **Enable in menuconfig**:
   ```bash
   make menuconfig
   # Navigate to: Utilities → pcat2-display-mini
   # Press 'Y' to build into firmware or 'M' for module
   ```

3. **Or add to your config file**:
   ```
   CONFIG_PACKAGE_pcat2-display-mini=y
   ```

4. **Rebuild**:
   ```bash
   make -j$(nproc)
   ```

#### Option 2: Install Display Application Post-Install

If you've already flashed OpenWrt without the display package:

1. **On the device, install Go runtime** (if not already in firmware):
   ```bash
   opkg update
   opkg install golang
   ```

2. **Build and install manually**:
   ```bash
   # Clone display application
   git clone https://github.com/photonicat/photonicat2_mini_display
   cd photonicat2_mini_display
   
   # Build for ARM64
   GOOS=linux GOARCH=arm64 go build -o photonicat2_mini_display
   
   # Install
   cp photonicat2_mini_display /usr/bin/
   chmod +x /usr/bin/photonicat2_mini_display
   
   # Copy assets
   mkdir -p /usr/share/pcat2_mini_display
   cp -r assets /usr/share/pcat2_mini_display/
   cp config.json /etc/pcat2_mini_display-config.json
   
   # Install init script (from photonicat2-support/packages/)
   # ... or create systemd service
   ```

### Display Customization

The display is highly customizable via `config.json`:

- **Update intervals**: Control how often data is refreshed
- **Display pages**: Choose which information screens to show
- **Colors and themes**: Customize appearance
- **API endpoints**: Configure data sources
- **Screen timeout**: Battery vs AC power settings
- **SMS display**: Enable/disable SMS notifications

**Configuration file**: `/etc/pcat2_mini_display-config.json`

Example customizations:
```json
{
  "displayPages": ["system", "network", "battery", "modem"],
  "updateIntervals": {
    "system": 2,
    "battery": 1,
    "network": 2
  },
  "screenTimeout": {
    "onBattery": 60,
    "onDC": 86400
  }
}
```

### HTTP API

The display application provides an HTTP API (default: port 8080):
- View current stats: `http://device-ip:8080/api/status`
- Control display: `http://device-ip:8080/api/control`
- Upload custom graphics: `http://device-ip:8080/api/upload`

## Fan Support

### Hardware Specifications

- **Type**: PWM-controlled cooling fan
- **Interface**: PWM1 (channel 0)
- **Control**: Automatic thermal management via kernel

### Device Tree Support

The fan is configured in the device tree:
- PWM1 interface
- Thermal zone bindings
- Cooling device integration

### Thermal Management

The RK3576 SoC includes thermal zones with automatic fan control:
- **Thermal zones**: CPU, GPU, NPU temperature monitoring
- **Cooling levels**: Fan speed adjusts based on temperature
- **Thresholds**: Defined in device tree

### Required Kernel Modules

Add these to your `configs/pcat2_custom.config`:

```
# PWM support for fan
CONFIG_PACKAGE_kmod-pwm=y
CONFIG_PACKAGE_kmod-pwm-rockchip=y

# Thermal management
CONFIG_PACKAGE_kmod-thermal=y
CONFIG_PACKAGE_kmod-hwmon-core=y
```

### Fan Control

#### Automatic Control (Default)

The fan is automatically controlled by the kernel thermal management:
- Temperature sensors monitor SoC temperature
- Fan speed increases as temperature rises
- No manual configuration needed

#### Manual Control (Advanced)

For custom fan control:

1. **Check fan PWM device**:
   ```bash
   ls /sys/class/pwm/
   ```

2. **Control fan speed manually**:
   ```bash
   # Enable PWM
   echo 0 > /sys/class/pwm/pwmchip0/export
   
   # Set period (in nanoseconds)
   echo 25000 > /sys/class/pwm/pwmchip0/pwm0/period
   
   # Set duty cycle (0-25000 for speed control)
   echo 12500 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle  # 50% speed
   
   # Enable
   echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
   ```

3. **Monitor temperatures**:
   ```bash
   # View all thermal zones
   cat /sys/class/thermal/thermal_zone*/temp
   
   # View specific zone
   cat /sys/class/thermal/thermal_zone0/temp
   ```

#### Custom Fan Scripts

Create a fan control script in `/etc/init.d/fan-control`:

```bash
#!/bin/sh /etc/rc.common

START=99

start() {
    # Set fan to automatic mode
    echo 0 > /sys/class/pwm/pwmchip0/export 2>/dev/null
    echo 25000 > /sys/class/pwm/pwmchip0/pwm0/period
    echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
}
```

## Testing

### Test LCD Display

1. **Check SPI device**:
   ```bash
   ls /dev/spidev*
   # Should show: /dev/spidev1.0
   ```

2. **Check display service**:
   ```bash
   /etc/init.d/pcat2-display-mini status
   ```

3. **View logs**:
   ```bash
   logread | grep display
   ```

### Test Fan

1. **Check PWM device**:
   ```bash
   ls /sys/class/pwm/
   ```

2. **Monitor fan activity**:
   ```bash
   watch -n 1 'cat /sys/class/pwm/pwmchip0/pwm0/duty_cycle'
   ```

3. **Stress test to trigger fan**:
   ```bash
   # Install stress tool
   opkg install stress-ng
   
   # Run CPU stress
   stress-ng --cpu 8 --timeout 60s
   
   # Monitor temperature
   watch -n 1 'cat /sys/class/thermal/thermal_zone0/temp'
   ```

## Troubleshooting

### LCD Not Working

**Check SPI module**:
```bash
lsmod | grep spi
# Should show: spi_rockchip, spidev
```

**Manually load modules**:
```bash
modprobe spi-rockchip
modprobe spidev
```

**Check device tree**:
```bash
ls /sys/firmware/devicetree/base/spi*/
```

**Verify backlight**:
```bash
ls /sys/class/backlight/
echo 255 > /sys/class/backlight/backlight/brightness
```

### Fan Not Working

**Check PWM module**:
```bash
lsmod | grep pwm
# Should show: pwm-rockchip
```

**Manually load PWM**:
```bash
modprobe pwm-rockchip
```

**Check thermal zones**:
```bash
ls /sys/class/thermal/thermal_zone*/
cat /sys/class/thermal/thermal_zone*/type
```

### Display Application Crashes

**Check logs**:
```bash
logread -f | grep pcat2
```

**Run manually for debugging**:
```bash
/etc/init.d/pcat2-display-mini stop
/usr/bin/photonicat2_mini_display -config /etc/pcat2_mini_display-config.json
```

## Integration with Build System

To automatically include display and fan support in your build:

1. **Update `build.sh`** to copy display package (already done in wrapper)
2. **Add required kernel modules** to your config file
3. **Include init scripts** in files/ directory
4. **Build and flash** the complete image

## Additional Resources

- **Display Application**: https://github.com/photonicat/photonicat2_mini_display
- **Display Documentation**: See application README for full API and customization
- **Device Tree**: `photonicat2-support/device-tree/rk3576-photonicat2.dts`
- **Kernel Modules**: Official OpenWrt kernel documentation

## Security Note

⚠️ The display application includes an HTTP API. For security:
- Change default ports in config
- Use firewall rules to restrict access
- Disable SMS features if not needed
- Review the code before use in production

## Summary

- ✅ **LCD**: Supported via device tree + pcat2-display-mini application
- ✅ **Fan**: Supported via device tree + automatic thermal management
- ✅ **Customizable**: Both can be fully customized
- ✅ **Vanilla OpenWrt**: Works with official OpenWrt + minimal patches
