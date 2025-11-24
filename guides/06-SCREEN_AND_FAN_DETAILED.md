# Photonicat 2 - Complete LCD Screen and Fan Guide

**Comprehensive documentation for configuring and customizing the LCD display and cooling fan on Photonicat 2 running OpenWrt.**

---

## Table of Contents

1. [Overview](#overview)
2. [LCD Screen](#lcd-screen)
   - [Hardware Specifications](#hardware-specifications)
   - [How It Works](#how-it-works)
   - [Display Application Architecture](#display-application-architecture)
   - [Configuration Overview](#configuration-overview)
3. [Display Configuration Deep Dive](#display-configuration-deep-dive)
   - [All Available Options](#all-available-options)
   - [Element Types](#element-types)
   - [Data Keys Reference](#data-keys-reference)
   - [Font Types](#font-types)
   - [Color Values](#color-values)
4. [Configuration Examples](#configuration-examples)
5. [Cooling Fan](#cooling-fan)
6. [Advanced Topics](#advanced-topics)
7. [Troubleshooting](#troubleshooting)
8. [Reference](#reference)

---

## Overview

The Photonicat 2 includes two important hardware features for system monitoring and thermal management:

### LCD Display
- **Purpose**: Real-time visual display of system information, network status, and device metrics
- **Controller**: GC9307 SPI LCD
- **Size**: 1.28" diagonal (172×320 pixels)
- **Driven by**: \`pcat2-display-mini\` Go application
- **Customizable**: Fully configurable via JSON configuration file

### Cooling Fan
- **Purpose**: Active thermal management to keep the RK3576 SoC cool
- **Control**: PWM-controlled with automatic thermal zones
- **Interface**: PWM1 (channel 0)
- **Management**: Automatic speed adjustment based on temperature

---

## LCD Screen

### Hardware Specifications

| Specification | Value |
|---------------|-------|
| **Display Controller** | GC9307 |
| **Resolution** | 172×320 pixels (portrait) |
| **Physical Size** | 1.28" diagonal (32mm) |
| **Interface** | SPI (4-wire) |
| **SPI Bus** | SPI1 (\`/dev/spidev1.0\`) |
| **Color Depth** | 16-bit RGB565 |
| **Orientation** | Portrait, rotated 180° |
| **Backlight** | PWM-controlled via PWM2 |
| **Target FPS** | 5 FPS (configurable) |

#### GPIO Pin Assignments

| Function | GPIO Pin | Description |
|----------|----------|-------------|
| **RST** (Reset) | GPIO 122 | Display reset control |
| **DC** (Data/Command) | GPIO 121 | Data/command selector |
| **CS** (Chip Select) | GPIO 13 | SPI chip select |
| **Backlight** | PWM2 Ch2 | PWM brightness control |

#### Display Layout

\`\`\`
┌─────────────────────────────────┐
│  Top Bar (32px)                 │  ← Time, Signal, Battery
├─────────────────────────────────┤
│                                 │
│                                 │
│  Middle Content (256px)         │  ← Pages with data
│                                 │
│                                 │
├─────────────────────────────────┤
│  Footer (22px)                  │  ← Page indicators
└─────────────────────────────────┘
   172px width × 320px height
\`\`\`

---

### How It Works

#### Component Overview

1. **Kernel Drivers**
   - SPI driver (\`spi-rockchip\`) communicates with GC9307 controller
   - PWM driver (\`pwm-rockchip\`) controls backlight brightness
   - GPIO drivers manage control pins (RST, DC, CS)

2. **Display Application** (\`photonicat2_mini_display\`)
   - Go-based application running as a system service
   - Collects system data from various sources
   - Renders graphics and text to the display
   - Provides HTTP API for remote control

3. **Device Tree Configuration**
   - Defines hardware interfaces in \`rk3576-photonicat2.dts\`
   - Maps GPIO pins, SPI buses, and PWM channels
   - Sets up backlight control and brightness levels

#### Data Flow

\`\`\`
System Data Sources → Data Collection → Rendering Engine → SPI Driver → LCD Display
     ↓                     ↓                  ↓               ↓            ↓
- /proc/stat        collectLinuxData()    draw.go      spi-rockchip   GC9307
- /sys/class/       collectBatteryData()  processData.go              Controller
- Network APIs      collectNetworkData()
- AT commands       getInfoFromPcatWeb()
\`\`\`

---

### Display Application Architecture

The \`pcat2-display-mini\` application consists of several key components:

#### Core Files

| File | Purpose |
|------|---------|
| \`main.go\` | Main loop, initialization, and page management |
| \`draw.go\` | Rendering functions for all display elements |
| \`processData.go\` | Data collection from system sources |
| \`processSms.go\` | SMS handling for 5G modem |
| \`httpServer.go\` | HTTP API server for remote control |
| \`utils.go\` | Utility functions |
| \`config.json\` | Main configuration file |

#### Update Frequencies

**Display Rendering:**
| Component | Update Rate | Notes |
|-----------|-------------|-------|
| Main Display | 5 FPS (200ms) | Configurable via \`desiredFPS\` |
| Top Bar | Every 10 frames (~2s) | Time, battery, signal |
| Footer | Every 5 frames (~1s) | Page indicators |
| Middle Content | Every frame | Main data area |

**Data Collection:**
| Data Source | Interval | Function |
|-------------|----------|----------|
| System Info | 2 seconds | CPU, memory, disk, temp |
| Battery | 1 second | SOC, voltage, current |
| Network Basic | 2 seconds | IPs, SSID |
| Network Speed | 3 seconds | WAN up/down speeds |
| PCAT Manager | 10 seconds | ISP, signal, data usage |
| SMS | 60 seconds | Message collection |
| Ping | 2 seconds | Connectivity tests |

---

### Configuration Overview

The display is configured via \`/etc/pcat2_mini_display-config.json\`. Configuration can also be read from:
- \`/etc/pcat2_mini_display-user_config.json\` (user overrides)
- Local \`config.json\` (for development)

#### Top-Level Configuration Structure

\`\`\`json
{
  "ping_site0": "taobao.com",
  "ping_site1": "photonicat.com",
  "show_sms": true,
  "screen_dimmer_time_on_battery_seconds": 60,
  "screen_dimmer_time_on_dc_seconds": 86400,
  "screen_max_brightness": 100,
  "screen_min_brightness": 0,
  "display_template": {
    "elements": {
      "page0": [ /* array of elements */ ],
      "page1": [ /* array of elements */ ],
      "page2": [ /* array of elements */ ],
      "page3": [ /* array of elements */ ]
    }
  }
}
\`\`\`

---

## Display Configuration Deep Dive

### All Available Options

#### Global Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| \`ping_site0\` | string | \`"taobao.com"\` | Primary ping target hostname/IP |
| \`ping_site1\` | string | \`"photonicat.com"\` | Secondary ping target hostname/IP |
| \`show_sms\` | boolean | \`true\` | Enable SMS message display pages |
| \`screen_dimmer_time_on_battery_seconds\` | integer | \`60\` | Seconds before dimming on battery power |
| \`screen_dimmer_time_on_dc_seconds\` | integer | \`86400\` | Seconds before dimming on DC power (24 hours) |
| \`screen_max_brightness\` | integer | \`100\` | Maximum brightness level (0-100) |
| \`screen_min_brightness\` | integer | \`0\` | Minimum brightness when dimmed (0-100) |

**Example:**
\`\`\`json
{
  "ping_site0": "8.8.8.8",
  "ping_site1": "1.1.1.1",
  "show_sms": false,
  "screen_dimmer_time_on_battery_seconds": 30,
  "screen_dimmer_time_on_dc_seconds": 300,
  "screen_max_brightness": 80,
  "screen_min_brightness": 10
}
\`\`\`

---

### Element Types

The display supports multiple element types for building custom pages:

#### 1. Text Element

Displays dynamic data from system sources.

**Structure:**
\`\`\`json
{
  "type": "text",
  "label": "ElementLabel",
  "position": {"x": 10, "y": 20},
  "font": "huge",
  "color": [255, 229, 0],
  "units": "Mbps",
  "data_key": "WanUP",
  "units_font": "unit",
  "enable": 1
}
\`\`\`

**Properties:**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| \`type\` | string | Yes | Must be \`"text"\` |
| \`label\` | string | Yes | Internal label (for debugging) |
| \`position\` | object | Yes | \`{x, y}\` coordinates in pixels |
| \`font\` | string | Yes | Font size (see [Font Types](#font-types)) |
| \`color\` | array | Yes | RGB array \`[R, G, B]\` (0-255 each) |
| \`data_key\` | string | Yes | Key from data collection (see [Data Keys](#data-keys-reference)) |
| \`units\` | string | No | Unit text to display after value |
| \`units_font\` | string | No | Font for units text |
| \`enable\` | integer | Yes | \`1\` = enabled, \`0\` = disabled |
| \`os\` | string | No | OS filter (e.g., \`"OpenWRT"\`) |

#### 2. Fixed Text Element

Displays static text that doesn't change.

**Structure:**
\`\`\`json
{
  "type": "fixed_text",
  "label": "Daily Cell Usage",
  "position": {"x": 10, "y": 89},
  "font": "tiny",
  "color": [255, 229, 0],
  "enable": 1
}
\`\`\`

**Properties:**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| \`type\` | string | Yes | Must be \`"fixed_text"\` |
| \`label\` | string | Yes | The text to display |
| \`position\` | object | Yes | \`{x, y}\` coordinates in pixels |
| \`font\` | string | Yes | Font size |
| \`color\` | array | Yes | RGB array \`[R, G, B]\` |
| \`enable\` | integer | Yes | \`1\` = enabled, \`0\` = disabled |
| \`os\` | string | No | OS filter |

**Note:** For \`fixed_text\`, you can use placeholders:
- \`[ping_site0]\` - replaced with value of \`ping_site0\` config
- \`[ping_site1]\` - replaced with value of \`ping_site1\` config

**Example:**
\`\`\`json
{
  "type": "fixed_text",
  "label": "ping: [ping_site0]",
  "position": {"x": 6, "y": 3},
  "font": "tiny",
  "color": [255, 255, 255],
  "enable": 1
}
\`\`\`
Displays: "ping: 8.8.8.8" (if \`ping_site0\` is set to "8.8.8.8")

#### 3. Icon Element

Displays SVG icons from the assets directory.

**Structure:**
\`\`\`json
{
  "type": "icon",
  "icon_path": "assets/svg/up_trig.svg",
  "position": {"x": 9, "y": 18},
  "enable": 1
}
\`\`\`

**Properties:**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| \`type\` | string | Yes | Must be \`"icon"\` |
| \`icon_path\` | string | Yes | Path to SVG file relative to app root |
| \`position\` | object | Yes | \`{x, y}\` coordinates in pixels |
| \`enable\` | integer | Yes | \`1\` = enabled, \`0\` = disabled |

**Available Icons:**
- \`assets/svg/up_trig.svg\` - Upload triangle
- \`assets/svg/down_trig.svg\` - Download triangle
- \`assets/svg/hline.svg\` - Horizontal line separator
- \`assets/svg/batt.svg\` - Battery icon
- \`assets/svg/charge.svg\` - Charging icon

#### 4. Graph Element

Displays time-series graphs (experimental).

**Structure:**
\`\`\`json
{
  "type": "graph",
  "position": {"x": 100, "y": 228},
  "size": {"width": 60, "height": 25},
  "enable": 0,
  "graph_config": {
    "graph_type": "power",
    "time_frame_mins": 15
  }
}
\`\`\`

**Properties:**
| Property | Type | Required | Description |
|----------|------|----------|-------------|
| \`type\` | string | Yes | Must be \`"graph"\` |
| \`position\` | object | Yes | \`{x, y}\` coordinates for top-left corner |
| \`size\` | object | Yes | \`{width, height}\` in pixels |
| \`enable\` | integer | Yes | \`1\` = enabled, \`0\` = disabled |
| \`graph_config\` | object | Yes | Graph-specific configuration |

**Graph Config:**
| Property | Type | Description |
|----------|------|-------------|
| \`graph_type\` | string | Type of graph: \`"power"\` |
| \`time_frame_mins\` | integer | Time window in minutes |

**Note:** Graph support is experimental and may not work in all configurations.

---

### Data Keys Reference

Complete list of all available \`data_key\` values for text elements:

#### Network Data

| Data Key | Type | Units | Description | Example Value |
|----------|------|-------|-------------|---------------|
| \`WanUP\` | float | Mbps | WAN upload speed | \`12.5\` |
| \`WanDOWN\` | float | Mbps | WAN download speed | \`45.3\` |
| \`DailyDataUsage\` | float | GB | Daily cellular data usage | \`2.34\` |
| \`MonthlyDataUsage\` | float | GB | Monthly cellular data usage | \`15.67\` |
| \`LAN_IP\` | string | - | LAN IP address | \`192.168.1.1\` |
| \`WAN_IP\` | string | - | WAN IP address | \`10.0.0.1\` |
| \`PUBLIC_IP\` | string | - | Public internet IP | \`203.0.113.42\` |
| \`SSID\` | string | - | Primary WiFi SSID (onboard) | \`Photonicat2\` |
| \`SSID2\` | string | - | Secondary WiFi SSID (PCIe) | \`Photonicat2-5G\` |

#### Connectivity

| Data Key | Type | Units | Description | Example Value |
|----------|------|-------|-------------|---------------|
| \`Ping0\` | integer | ms | Ping latency to site 0 | \`45\` or \`-2\` (timeout) |
| \`Ping1\` | integer | ms | Ping latency to site 1 | \`32\` or \`-1\` (error) |
| \`Ping0Rate\` | integer | % | Success rate for site 0 | \`98\` |
| \`Ping1Rate\` | integer | % | Success rate for site 1 | \`100\` |

**Ping Special Values:**
- \`-2\` = Timeout (>3 seconds) → Displays red "X"
- \`-1\` = Error with no previous success → Displays "-"
- \`>0\` = Successful ping time in milliseconds

#### System Information

| Data Key | Type | Units | Description | Example Value |
|----------|------|-------|-------------|---------------|
| \`CpuUsage\` | integer | % | CPU utilization | \`23\` |
| \`MemUsage\` | string | - | Memory usage formatted | \`1.2/4.0\` |
| \`Uptime\` | string | - | System uptime formatted | \`5d 12h 34m\` |
| \`OSVersion\` | string | - | OpenWrt version | \`23.05.2\` |
| \`SN\` | string | - | Device serial number | \`PCT2-A1B2C3\` |

#### Power and Battery

| Data Key | Type | Units | Description | Example Value |
|----------|------|-------|-------------|---------------|
| \`BatteryWattage\` | float | W | Battery power draw/charge | \`5.2\` or \`-12.5\` |
| \`BatteryVoltage\` | float | V | Battery voltage | \`11.8\` |
| \`DCVoltage\` | float | V | DC input voltage | \`12.1\` |
| \`BatterySOC\` | integer | % | Battery state of charge | \`85\` |

**Note:** \`BatteryWattage\` is:
- Positive when charging
- Negative when discharging

#### Cellular Modem

| Data Key | Type | Units | Description | Example Value |
|----------|------|-------|-------------|---------------|
| \`ISPName\` | string | - | Cellular carrier name | \`Verizon\` |
| \`ModemNetworkInfo\` | string | - | Cell band and type | \`5G SA N41\` |
| \`SimNumber\` | string | - | SIM card phone number | \`+1-555-0123\` |
| \`ModemModel\` | string | - | Modem model | \`RM520N-GL\` |
| \`SimState\` | string | - | SIM card status | \`Ready\` |

#### Device Statistics

| Data Key | Type | Units | Description | Example Value |
|----------|------|-------|-------------|---------------|
| \`WiFiClientsCount\` | integer | - | Connected WiFi clients | \`5\` |
| \`DHCPClientsCount\` | integer | - | DHCP leases active | \`8\` |
| \`SdState\` | string | - | SD card status | \`Mounted\` or \`None\` |
| \`FanRPM\` | integer | RPM | Fan speed | \`3200\` or \`0\` |
| \`BoardTemperature\` | integer | °C | SoC/board temperature | \`48\` |

---

### Font Types

Available font sizes for text rendering:

| Font Type | Size | Best Used For |
|-----------|------|---------------|
| \`tiny\` | Very small | Labels, IP addresses, long text |
| \`unit\` | Small | Units, secondary info |
| \`reg\` | Regular | Standard text |
| \`thin\` | Thin regular | Subtle text |
| \`big\` | Large | Important values |
| \`huge\` | Very large | Primary metrics |

**Visual Size Comparison:**
\`\`\`
huge    ← 45.3
big     ← 45.3
reg     ← 45.3
thin    ← 45.3
unit    ← 45.3
tiny    ← 45.3
\`\`\`

**Choosing a Font:**
- Use \`huge\` for the most important metric on each page
- Use \`big\` for secondary important values
- Use \`reg\` or \`thin\` for standard data display
- Use \`unit\` for units and labels
- Use \`tiny\` for IP addresses, long text, or less important info

---

### Color Values

Colors are specified as RGB arrays: \`[Red, Green, Blue]\`

Each value ranges from 0-255.

#### Common Colors

\`\`\`json
[255, 255, 255]   // White
[255, 229, 0]     // Yellow (default accent color)
[255, 229, 255]   // Light pink
[255, 0, 0]       // Red
[0, 255, 0]       // Green
[0, 0, 255]       // Blue
[0, 255, 255]     // Cyan
[255, 165, 0]     // Orange
[128, 128, 128]   // Gray
[0, 0, 0]         // Black
\`\`\`

**Color Usage Tips:**
- **Yellow** \`[255, 229, 0]\` - Good for labels and important metrics
- **White** \`[255, 255, 255]\` - Good for primary data
- **Light Pink** \`[255, 229, 255]\` - Good for secondary data
- **Red** \`[255, 0, 0]\` - Use sparingly for errors or alerts
- **Green** \`[0, 255, 0]\` - Good for status indicators

**Readability:**
- High contrast is essential on small screens
- Yellow and white show well on dark backgrounds
- Avoid dark colors (they won't be visible)

---

## Configuration Examples

### Example 1: Simple Network Monitor

**Goal:** Display only WAN speeds and ping statistics

**Configuration:**
\`\`\`json
{
  "ping_site0": "8.8.8.8",
  "ping_site1": "1.1.1.1",
  "show_sms": false,
  "screen_dimmer_time_on_battery_seconds": 60,
  "screen_dimmer_time_on_dc_seconds": 86400,
  "screen_max_brightness": 100,
  "screen_min_brightness": 0,
  "display_template": {
    "elements": {
      "page0": [
        {
          "type": "fixed_text",
          "label": "Upload Speed",
          "position": {"x": 10, "y": 10},
          "font": "unit",
          "color": [255, 229, 0],
          "enable": 1
        },
        {
          "type": "text",
          "label": "WAN Upload",
          "position": {"x": 10, "y": 30},
          "font": "huge",
          "color": [255, 255, 255],
          "units": "Mbps",
          "data_key": "WanUP",
          "units_font": "unit",
          "enable": 1
        },
        {
          "type": "fixed_text",
          "label": "Download Speed",
          "position": {"x": 10, "y": 90},
          "font": "unit",
          "color": [255, 229, 0],
          "enable": 1
        },
        {
          "type": "text",
          "label": "WAN Download",
          "position": {"x": 10, "y": 110},
          "font": "huge",
          "color": [255, 255, 255],
          "units": "Mbps",
          "data_key": "WanDOWN",
          "units_font": "unit",
          "enable": 1
        },
        {
          "type": "fixed_text",
          "label": "Ping to Google DNS",
          "position": {"x": 10, "y": 170},
          "font": "unit",
          "color": [255, 229, 0],
          "enable": 1
        },
        {
          "type": "text",
          "label": "Ping0",
          "position": {"x": 10, "y": 190},
          "font": "big",
          "color": [0, 255, 0],
          "units": "ms",
          "data_key": "Ping0",
          "units_font": "unit",
          "enable": 1
        }
      ]
    }
  }
}
\`\`\`

**Result:** Single page showing upload speed, download speed, and ping to 8.8.8.8

---

### Example 2: System Stats Dashboard

**Goal:** Two pages - one for network, one for system resources

\`\`\`json
{
  "ping_site0": "1.1.1.1",
  "ping_site1": "photonicat.com",
  "show_sms": false,
  "screen_max_brightness": 90,
  "display_template": {
    "elements": {
      "page0": [
        {
          "type": "icon",
          "icon_path": "assets/svg/up_trig.svg",
          "position": {"x": 10, "y": 20},
          "enable": 1
        },
        {
          "type": "text",
          "label": "UP",
          "position": {"x": 30, "y": 10},
          "font": "huge",
          "color": [255, 229, 0],
          "units": "Mbps",
          "data_key": "WanUP",
          "units_font": "unit",
          "enable": 1
        },
        {
          "type": "icon",
          "icon_path": "assets/svg/down_trig.svg",
          "position": {"x": 10, "y": 70},
          "enable": 1
        },
        {
          "type": "text",
          "label": "DOWN",
          "position": {"x": 30, "y": 55},
          "font": "huge",
          "color": [255, 229, 0],
          "units": "Mbps",
          "data_key": "WanDOWN",
          "units_font": "unit",
          "enable": 1
        }
      ],
      "page1": [
        {
          "type": "fixed_text",
          "label": "CPU Usage",
          "position": {"x": 10, "y": 10},
          "font": "unit",
          "color": [255, 229, 0],
          "enable": 1
        },
        {
          "type": "text",
          "label": "CPU",
          "position": {"x": 10, "y": 30},
          "font": "huge",
          "color": [255, 255, 255],
          "units": "%",
          "data_key": "CpuUsage",
          "units_font": "unit",
          "enable": 1
        },
        {
          "type": "fixed_text",
          "label": "Temperature",
          "position": {"x": 10, "y": 170},
          "font": "unit",
          "color": [255, 229, 0],
          "enable": 1
        },
        {
          "type": "text",
          "label": "Temp",
          "position": {"x": 10, "y": 190},
          "font": "big",
          "color": [255, 165, 0],
          "units": "°C",
          "data_key": "BoardTemperature",
          "units_font": "unit",
          "enable": 1
        }
      ]
    }
  }
}
\`\`\`

**Result:** Page 0 shows network speeds, Page 1 shows CPU and temperature

---

### Example 3: Minimalist Display

**Goal:** Ultra-simple display with just essential info

\`\`\`json
{
  "ping_site0": "1.1.1.1",
  "show_sms": false,
  "screen_max_brightness": 70,
  "display_template": {
    "elements": {
      "page0": [
        {
          "type": "text",
          "label": "Download",
          "position": {"x": 20, "y": 50},
          "font": "huge",
          "color": [255, 255, 255],
          "units": "Mbps",
          "data_key": "WanDOWN",
          "units_font": "unit",
          "enable": 1
        },
        {
          "type": "text",
          "label": "CPU",
          "position": {"x": 20, "y": 130},
          "font": "huge",
          "color": [255, 255, 255],
          "units": "%",
          "data_key": "CpuUsage",
          "units_font": "unit",
          "enable": 1
        }
      ]
    }
  }
}
\`\`\`

**Result:** Single page with two large metrics

---

### Example 4: Colorful Dashboard

**Goal:** Custom colors with categorical sections

\`\`\`json
{
  "ping_site0": "cloudflare.com",
  "show_sms": false,
  "display_template": {
    "elements": {
      "page0": [
        {
          "type": "fixed_text",
          "label": "=== NETWORK ===",
          "position": {"x": 40, "y": 5},
          "font": "unit",
          "color": [0, 255, 255],
          "enable": 1
        },
        {
          "type": "text",
          "label": "Upload",
          "position": {"x": 10, "y": 25},
          "font": "big",
          "color": [255, 165, 0],
          "units": "Mbps",
          "data_key": "WanUP",
          "units_font": "tiny",
          "enable": 1
        },
        {
          "type": "fixed_text",
          "label": "=== SYSTEM ===",
          "position": {"x": 40, "y": 100},
          "font": "unit",
          "color": [0, 255, 255],
          "enable": 1
        },
        {
          "type": "text",
          "label": "CPU",
          "position": {"x": 10, "y": 120},
          "font": "reg",
          "color": [0, 255, 0],
          "units": "%",
          "data_key": "CpuUsage",
          "units_font": "tiny",
          "enable": 1
        }
      ]
    }
  }
}
\`\`\`

**Result:** Colorful single page with cyan headers, orange network, green system stats

---

## Cooling Fan

### Fan Hardware Specifications

| Specification | Value |
|---------------|-------|
| **Type** | PWM-controlled DC fan |
| **Interface** | PWM1, Channel 0 |
| **Control Method** | Automatic via kernel thermal zones |
| **Duty Cycle Range** | 0-100% (0-25000ns period) |
| **PWM Period** | 25000 nanoseconds (40 kHz) |
| **Device Path** | \`/sys/class/pwm/pwmchip0/pwm0\` |

---

### How Fan Works

#### Architecture

\`\`\`
Temperature Sensors → Thermal Zones → Cooling Device → PWM Controller → Fan
        ↓                  ↓              ↓               ↓           ↓
  /sys/class/      thermal_zone0    cooling_device0   pwmchip0    Physical
    thermal/       thermal_zone1                                    Fan
\`\`\`

#### Thermal Zone Operation

1. **Temperature Monitoring**
   - Multiple thermal zones monitor different parts of the SoC
   - CPU, GPU, and NPU each have dedicated temperature sensors
   - Readings available in \`/sys/class/thermal/thermal_zone*/temp\`

2. **Thermal Policy**
   - Kernel thermal management evaluates temperatures
   - Compares current temp against defined trip points
   - Determines required cooling level

3. **Fan Speed Adjustment**
   - Cooling device adjusts PWM duty cycle
   - Higher temperatures = higher duty cycle = faster fan
   - Lower temperatures = lower duty cycle = slower/off fan

4. **Hysteresis**
   - Built-in delay prevents rapid fan speed changes
   - Provides smooth transitions and reduces noise

---

### Thermal Management

#### Temperature Monitoring

**Check current temperatures:**
\`\`\`bash
# View all thermal zones
cat /sys/class/thermal/thermal_zone*/temp

# View specific zone with name
cat /sys/class/thermal/thermal_zone0/type
cat /sys/class/thermal/thermal_zone0/temp
\`\`\`

**Temperature values** are in millidegrees Celsius (divide by 1000):
\`\`\`bash
# Example output
55000    # = 55.0°C
\`\`\`

#### Thermal Trip Points

Trip points define temperature thresholds where fan speed changes.

**View trip points:**
\`\`\`bash
# List all trip points for a zone
cat /sys/class/thermal/thermal_zone0/trip_point_*_temp
cat /sys/class/thermal/thermal_zone0/trip_point_*_type
\`\`\`

**Typical trip points** (defined in device tree):
| Temperature | Action | Fan Speed |
|-------------|--------|-----------|
| < 50°C | Passive | Off or very low |
| 50-60°C | Passive | Low speed |
| 60-70°C | Active | Medium speed |
| 70-80°C | Active | High speed |
| > 80°C | Critical | Maximum speed |

#### Automatic Fan Control (Default)

The fan is controlled automatically by the kernel with no user intervention needed.

**How it works:**
1. Kernel monitors SoC temperature continuously
2. When temperature rises, fan speed increases automatically
3. When temperature drops, fan speed decreases
4. Fan may turn off completely when system is cool (<50°C)

**View fan status:**
\`\`\`bash
# Check if fan is enabled
cat /sys/class/pwm/pwmchip0/pwm0/enable
# Output: 1 (enabled) or 0 (disabled)

# Check current duty cycle (fan speed)
cat /sys/class/pwm/pwmchip0/pwm0/duty_cycle
# Output: 0-25000 (higher = faster)

# Calculate fan speed percentage
duty=\$(cat /sys/class/pwm/pwmchip0/pwm0/duty_cycle)
period=\$(cat /sys/class/pwm/pwmchip0/pwm0/period)
echo "Fan speed: \$(( duty * 100 / period ))%"
\`\`\`

---

### Manual Fan Control

**⚠️ Warning:** Manual fan control disables automatic thermal management. Your device may overheat if not properly configured.

#### Enable Manual Control

1. **Export PWM device** (if not already exported):
\`\`\`bash
echo 0 > /sys/class/pwm/pwmchip0/export
\`\`\`

2. **Set PWM period**:
\`\`\`bash
echo 25000 > /sys/class/pwm/pwmchip0/pwm0/period
\`\`\`

3. **Set duty cycle** (fan speed):
\`\`\`bash
# Off (0%)
echo 0 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# 25% speed
echo 6250 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# 50% speed
echo 12500 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# 75% speed
echo 18750 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# 100% speed (maximum)
echo 25000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
\`\`\`

4. **Enable PWM output**:
\`\`\`bash
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
\`\`\`

#### Custom Fan Control Script

Create a script for temperature-based fan control:

**File: \`/usr/local/bin/fan-control.sh\`**
\`\`\`bash
#!/bin/sh

# Temperature thresholds (in millidegrees Celsius)
TEMP_LOW=50000   # 50°C - fan off
TEMP_MED=65000   # 65°C - medium speed
TEMP_HIGH=75000  # 75°C - high speed

# Fan speeds (duty cycle out of 25000)
SPEED_OFF=0
SPEED_LOW=8000    # ~32%
SPEED_MED=15000   # ~60%
SPEED_HIGH=25000  # 100%

# PWM paths
PWM_CHIP="/sys/class/pwm/pwmchip0"
PWM="\${PWM_CHIP}/pwm0"
THERMAL_ZONE="/sys/class/thermal/thermal_zone0/temp"

# Initialize PWM if not already done
if [ ! -d "\$PWM" ]; then
    echo 0 > \${PWM_CHIP}/export
    sleep 1
fi

# Set period
echo 25000 > \${PWM}/period

# Enable PWM
echo 1 > \${PWM}/enable

# Main loop
while true; do
    # Read temperature
    TEMP=\$(cat \$THERMAL_ZONE)
    
    # Determine fan speed based on temperature
    if [ \$TEMP -lt \$TEMP_LOW ]; then
        SPEED=\$SPEED_OFF
    elif [ \$TEMP -lt \$TEMP_MED ]; then
        SPEED=\$SPEED_LOW
    elif [ \$TEMP -lt \$TEMP_HIGH ]; then
        SPEED=\$SPEED_MED
    else
        SPEED=\$SPEED_HIGH
    fi
    
    # Set fan speed
    echo \$SPEED > \${PWM}/duty_cycle
    
    # Wait before next check
    sleep 5
done
\`\`\`

**Make executable:**
\`\`\`bash
chmod +x /usr/local/bin/fan-control.sh
\`\`\`

#### Disable Manual Control (Return to Auto)

To restore automatic thermal management:

\`\`\`bash
# Disable PWM
echo 0 > /sys/class/pwm/pwmchip0/pwm0/enable

# Unexport PWM device
echo 0 > /sys/class/pwm/pwmchip0/unexport

# Reboot to fully restore kernel control
reboot
\`\`\`

---

## Advanced Topics

### HTTP API for Display Control

The display application provides an HTTP API on port 8080.

#### Get Backlight Level

**Request:**
\`\`\`bash
curl http://192.168.1.1:8080/api/v1/go_get_max_backlight
\`\`\`

**Response:**
\`\`\`json
{
  "status": "ok",
  "max_brightness": 100
}
\`\`\`

#### Set Backlight Level

**Request:**
\`\`\`bash
curl -X POST -d "max_brightness=50" \\
  http://192.168.1.1:8080/api/v1/go_set_max_backlight
\`\`\`

**Response:**
\`\`\`json
{
  "status": "ok",
  "max_brightness": 50
}
\`\`\`

#### API Usage Examples

**Dim screen at night (cron job):**
\`\`\`bash
# Add to /etc/crontabs/root
0 22 * * * curl -X POST -d "max_brightness=10" http://localhost:8080/api/v1/go_set_max_backlight
0 7 * * * curl -X POST -d "max_brightness=100" http://localhost:8080/api/v1/go_set_max_backlight
\`\`\`

---

### Creating Custom Icons

You can add your own SVG icons to \`assets/svg/\` directory.

**Requirements:**
- SVG format
- Monochrome recommended
- Simple paths
- Size: 20x20 to 40x40 pixels

**Example:**
\`\`\`svg
<!-- assets/svg/custom_alert.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <path d="M12 2L2 22h20L12 2z" fill="white"/>
</svg>
\`\`\`

---

## Troubleshooting

### Display Issues

#### Screen is Black / Not Showing Anything

**Check service status:**
\`\`\`bash
/etc/init.d/pcat2-display-mini status
\`\`\`

**Check SPI device:**
\`\`\`bash
ls -l /dev/spidev1.0
\`\`\`

**Manually initialize GPIOs:**
\`\`\`bash
echo 122 > /sys/class/gpio/export
echo 121 > /sys/class/gpio/export
echo 13 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio122/direction
echo out > /sys/class/gpio/gpio121/direction
echo out > /sys/class/gpio/gpio13/direction
\`\`\`

**View service logs:**
\`\`\`bash
logread | grep pcat2
\`\`\`

---

#### Display Shows Corrupted Graphics

**Validate config JSON:**
\`\`\`bash
cat /etc/pcat2_mini_display-config.json | python3 -m json.tool
\`\`\`

**Check for assets:**
\`\`\`bash
ls /usr/share/pcat2_mini_display/assets/fonts/
ls /usr/share/pcat2_mini_display/assets/svg/
\`\`\`

**Restart service:**
\`\`\`bash
/etc/init.d/pcat2-display-mini restart
\`\`\`

---

#### Wrong Data Displayed

**Verify data keys match reference:**
- Check [Data Keys Reference](#data-keys-reference)
- Ensure \`data_key\` spelling is exact

**Test data sources manually:**
\`\`\`bash
# Network
ip addr show br-lan

# System
cat /proc/stat
free

# Battery
cat /sys/class/power_supply/battery/capacity
\`\`\`

---

### Fan Issues

#### Fan Not Spinning

**Check temperature:**
\`\`\`bash
cat /sys/class/thermal/thermal_zone0/temp
# If < 50000 (50°C), fan may be intentionally off
\`\`\`

**Check PWM status:**
\`\`\`bash
ls /sys/class/pwm/
cat /sys/class/pwm/pwmchip0/pwm0/enable
cat /sys/class/pwm/pwmchip0/pwm0/duty_cycle
\`\`\`

**Manually test fan:**
\`\`\`bash
# Export PWM
echo 0 > /sys/class/pwm/pwmchip0/export

# Set period
echo 25000 > /sys/class/pwm/pwmchip0/pwm0/period

# Set 50% speed
echo 12500 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# Enable
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
\`\`\`

**Stress test to heat up:**
\`\`\`bash
opkg update
opkg install stress-ng

# Run CPU stress
stress-ng --cpu 8 --timeout 60s

# Monitor
watch -n 1 'cat /sys/class/thermal/thermal_zone0/temp'
\`\`\`

---

#### Fan Always Running at Full Speed

**Check for custom fan scripts:**
\`\`\`bash
ps | grep fan
\`\`\`

**Reset to automatic control:**
\`\`\`bash
echo 0 > /sys/class/pwm/pwmchip0/pwm0/enable
echo 0 > /sys/class/pwm/pwmchip0/unexport
reboot
\`\`\`

---

## Reference

### File Locations

| File | Path | Purpose |
|------|------|---------|
| Configuration | \`/etc/pcat2_mini_display-config.json\` | Main config file |
| User Config | \`/etc/pcat2_mini_display-user_config.json\` | User overrides |
| Binary | \`/usr/bin/photonicat2_mini_display\` | Display application |
| Init Script | \`/etc/init.d/pcat2-display-mini\` | Service control |
| Assets | \`/usr/share/pcat2_mini_display/assets/\` | Fonts and icons |

### System Paths

**Display:**
\`\`\`
/dev/spidev1.0                          # SPI device
/sys/class/gpio/gpio122/                # Reset pin
/sys/class/gpio/gpio121/                # DC pin
/sys/class/gpio/gpio13/                 # CS pin
/sys/class/backlight/backlight/         # Backlight control
\`\`\`

**Fan:**
\`\`\`
/sys/class/pwm/pwmchip0/                # PWM controller
/sys/class/pwm/pwmchip0/pwm0/           # Fan PWM channel
/sys/class/thermal/thermal_zone*/       # Temperature sensors
\`\`\`

### Kernel Modules

**Display:**
\`\`\`
kmod-spi-dev
kmod-spi-bitbang
kmod-spi-rockchip
kmod-fb
kmod-fb-sys-fops
kmod-backlight
\`\`\`

**Fan:**
\`\`\`
kmod-pwm
kmod-pwm-rockchip
kmod-thermal
kmod-hwmon-core
\`\`\`

### Additional Resources

- **Display Application**: https://github.com/photonicat/photonicat2_mini_display
- **English Config Guide**: https://github.com/photonicat/photonicat2_mini_display/blob/main/docs/screen_guide_en.md
- **Chinese Config Guide**: https://github.com/photonicat/photonicat2_mini_display/blob/main/docs/screen_guide-zh_cn.md
- **OpenWrt**: https://openwrt.org/docs/start

---

**Document Version**: 1.0  
**Last Updated**: November 2024  
**Device**: Photonicat 2 (RK3576)  
**Display**: GC9307 LCD (172×320)  
**Application**: pcat2-display-mini v1.0+
