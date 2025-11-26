# Photonicat 2 OpenWrt - Troubleshooting Guide

## Build Issues

### Build Hangs or Freezes
**Symptom**: Build process stops making progress (no new log lines for 5+ minutes)

**Solutions**:
1. Check memory:
   ```bash
   free -h
   ps aux --sort=-%mem | head -5
   ```
   If memory < 500MB available, kill other processes

2. Check disk space:
   ```bash
   df -h
   ```
   Need at least 500MB free in `/home`

3. Rebuild completely:
   ```bash
   cd /home/th3cavalry/photonicat2/build/openwrt
   make clean all
   ```

### Build Fails With "ERROR"
**Symptom**: Build process exits with error message

**Solution**:
1. Get full error context:
   ```bash
   tail -50 /home/th3cavalry/photonicat2/build/openwrt/build.log | grep -A 10 "ERROR:"
   ```

2. Most common errors:
   - **"Permission denied"** → Run with `sudo make`
   - **"No space left"** → Clean build dir: `make clean`
   - **"Configure failed"** → Update feeds: `./scripts/feeds update -a && ./scripts/feeds install -a`

3. Start from scratch:
   ```bash
   cd /home/th3cavalry/photonicat2/build/openwrt
   make distclean
   make menuconfig                         # Load configs
   cp /home/th3cavalry/photonicat2/configs/pcat2_custom.config ./.config
   make -j4
   ```

### No Image Output
**Symptom**: Build completes but no `.img` file in `bin/targets/`

**Solution**:
1. Check if build actually succeeded:
   ```bash
   tail -20 /home/th3cavalry/photonicat2/build/openwrt/build.log
   ```
   Should end with "Built profile packages" or similar

2. Image should be at:
   ```bash
   ls -lh /home/th3cavalry/photonicat2/build/openwrt/bin/targets/rockchip/armv8/
   ```

3. If missing, rebuild image:
   ```bash
   cd /home/th3cavalry/photonicat2/build/openwrt
   make -j4 2>&1 | tail -20
   ```

---

## Flashing Issues

### Device Not Found in Maskrom Mode
**Symptom**: `lsusb` shows no Rockchip device, flashing fails

**Solutions**:
1. Verify device is in Maskrom mode:
   - **Yellow LED** = Maskrom ✓ (ready to flash)
   - **Green LED** = Normal boot ✗ (put back in Maskrom)
   
2. To enter Maskrom:
   - 3 quick short presses of power button (LED blinks)
   - Hold power button 15-20 seconds (LED turns yellow)
   - Release

3. Check device detection:
   ```bash
   lsusb | grep -i rockchip
   ```
   Should show: `Bus 00X Device 0YY: ID 2207:350a Fuzhou Rockchip Electronics Co., Ltd.`

4. Try different USB port/cable:
   - Use USB 2.0 port if available
   - Try USB hub if built-in ports fail
   - Try different cable

5. Reset rkdeveloptool:
   ```bash
   sudo pkill rkdeveloptool
   sleep 2
   lsusb | grep -i rockchip    # Should still see device
   ```

### Flashing Hangs at 0%
**Symptom**: Flash starts but doesn't progress

**Solutions**:
1. Verify image exists and is correct size:
   ```bash
   ls -lh /home/th3cavalry/photonicat2/build/openwrt/bin/targets/rockchip/armv8/*.img
   # Should be ~100-200 MB
   ```

2. Verify device still in Maskrom:
   ```bash
   lsusb | grep 2207:350a    # Should still see it
   ```

3. Try manual flash:
   ```bash
   cd /home/th3cavalry/photonicat2/rkdeveloptool
   sudo ./rkdeveloptool db RK3576_MiniLoaderAll.bin
   sleep 3
   sudo ./rkdeveloptool wl 0x0 /home/th3cavalry/photonicat2/build/openwrt/bin/targets/rockchip/armv8/openwrt-*-sysupgrade.img
   sudo ./rkdeveloptool rd
   ```

### Flashing Fails with "Bad file descriptor" or USB Error
**Symptom**: Flash command exits with USB error

**Solutions**:
1. Put device back in Maskrom (see above)
2. Kill any running rkdeveloptool:
   ```bash
   sudo pkill -f rkdeveloptool
   ```
3. Try again:
   ```bash
   cd /home/th3cavalry/photonicat2/release
   ./flash.sh
   ```

---

## Network Issues After Flash

### No Network IP (Still Getting 169.*)
**Symptom**: Device gets APIPA address (169.254.*.*)

**Root Cause**: Board detection script (`02_network`) didn't run properly

**Solutions**:
1. Check if board was detected:
   ```bash
   ssh root@169.254.x.x         # Use APIPA IP if available
   cat /proc/device-tree/compatible
   ```
   Should show: `ariaboard,photonicat2` or similar `photonicat` string

2. Check if network config is correct:
   ```bash
   cat /etc/config/network
   ```
   Should show:
   ```
   config interface 'lan'
       option device 'br-lan'
       option proto 'static'
       option ipaddr '172.16.0.1'
   ```

3. If board.d script didn't run, manually set:
   ```bash
   # On device via serial or APIPA SSH
   uci set network.lan.device='eth1'
   uci set network.wan.device='eth0'
   uci commit
   /etc/init.d/network restart
   ```

4. If interfaces are still wrong, rebuild with board.d fix:
   - Verify `files/etc/board.d/02_network` exists locally
   - Check that board name matches in script (search for "photonicat")
   - Rebuild: `cd build/openwrt && make clean world -j4`

### WiFi Not Showing
**Symptom**: No WiFi SSID broadcast, no wlan0 interface

**Solutions**:
1. Check if WiFi hardware detected:
   ```bash
   ssh root@172.16.0.1
   iwconfig                # Should show wlan0
   iw list                 # Should show supported bands
   ```

2. If no wlan0, check WiFi driver:
   ```bash
   lsmod | grep ath       # Should show ath10k or ath11k module
   dmesg | grep -i "ath"  # Should show driver loading
   ```

3. If driver not loaded, enable in config:
   ```bash
   # Locally, before rebuild
   grep "^CONFIG_PACKAGE_kmod-ath" /home/th3cavalry/photonicat2/configs/pcat2_custom.config
   # Should show: CONFIG_PACKAGE_kmod-ath=y (and other ath packages)
   ```

4. Force reload WiFi:
   ```bash
   # On device
   /etc/init.d/network restart
   ```

5. Check WiFi is enabled:
   ```bash
   # On device
   uci show wireless
   # Should show radio config sections
   ```

### Can't SSH to Device
**Symptom**: `ssh root@172.16.0.1` times out or refuses connection

**Solutions**:
1. Device is online but SSH not responding:
   ```bash
   ping 172.16.0.1        # From your PC
   ```
   If no response, device not booted or network issue

2. Wait for full boot (2-3 minutes):
   - Watch for stable system (no disk activity)
   - Check with `ping` every 10 seconds

3. Try via serial console:
   - Connect USB serial port
   - Default baud: 1500000
   - Login: root (no password)

4. If SSH still won't connect:
   ```bash
   ssh -vv root@172.16.0.1    # Verbose output
   ssh -o ConnectTimeout=10 root@172.16.0.1
   ```

### Ping Works But SSH Fails
**Symptom**: `ping 172.16.0.1` works, but `ssh` times out

**Solutions**:
1. SSH service not running:
   ```bash
   # Via serial console
   /etc/init.d/dropbear status
   /etc/init.d/dropbear start
   ```

2. SSH port blocked:
   ```bash
   nmap 172.16.0.1         # From your PC (if nmap installed)
   # Port 22 should be open
   ```

3. SSH service crashed:
   ```bash
   # Via serial console
   ps aux | grep drop      # Should see dropbear process
   logread | grep ssh      # Check for SSH errors
   ```

4. Firewall blocking SSH:
   ```bash
   # Via serial console (or SSH once working)
   uci set firewall.@zone[0].input='ACCEPT'
   uci commit firewall
   /etc/init.d/firewall restart
   ```

---

## NVMe Issues

### NVMe Not Auto-mounting
**Symptom**: NVMe installed but `/overlay` not on it, `df -h` shows eMMC full

**Solutions**:
1. Check if NVMe detected:
   ```bash
   ssh root@172.16.0.1
   lsblk              # Should show nvme0n1
   dmesg | tail -20   # Check for NVMe detection errors
   ```

2. If NVMe not detected, check:
   - NVMe actually installed?
   - Try in different M.2 slot
   - Check physical connection

3. If detected but not mounted, manually mount:
   ```bash
   mkdir -p /overlay
   mount /dev/nvme0n1p1 /overlay
   df -h
   ```

4. To persist across reboots:
   ```bash
   # Add to /etc/rc.local or /etc/init.d/
   mount /dev/nvme0n1p1 /overlay
   ```

5. To auto-partition fresh NVMe:
   ```bash
   # On device
   fdisk /dev/nvme0n1
   # n (new), p (primary), default start/end
   # w (write)
   mkfs.ext4 /dev/nvme0n1p1
   mount /dev/nvme0n1p1 /overlay
   ```

---

## Display Issues

### Display Not Showing
**Symptom**: LCD blank, no system info shown

**Solutions**:
1. Check display service:
   ```bash
   ssh root@172.16.0.1
   ps aux | grep display
   # Should show pcat2-display or similar
   ```

2. Check for errors:
   ```bash
   logread | grep -i "display\|lcd"
   ```

3. Restart display service:
   ```bash
   /etc/init.d/pcat2-setup restart    # Or similar service name
   sleep 2
   logread | tail -20
   ```

4. Check device tree (if display service in custom build):
   ```bash
   cat /proc/device-tree/compatible
   # Verify photonicat compatible string
   ```

---

## Serial Console (Last Resort)

Use serial console if device is completely broken and can't SSH:

### Hardware Setup
- USB-TTL adapter required
- Connections: GND, TX, RX (check pinout for Photonicat 2)
- Baud rate: 1500000 (unusual!)

### Access via Linux
```bash
sudo minicom -s                    # Setup
# Device: /dev/ttyUSB0
# Baud: 1500000
# Hardware flow control: OFF

# Or using screen:
sudo screen /dev/ttyUSB0 1500000

# Or using picocom:
sudo picocom -b 1500000 /dev/ttyUSB0
```

### What to Try from Serial Console
```bash
# Check if device is booting
# Should see kernel messages, then login prompt

root                               # Press Enter multiple times
# Should get root@... prompt (no password)

# Basic checks:
ip addr show                       # Check network IPs
iwconfig                          # Check WiFi
df -h                             # Check storage
logread | tail -50                # Check system logs
dmesg | tail -20                  # Check kernel messages

# Network restart:
/etc/init.d/network restart       # Reload network config

# Full system reboot:
reboot
```

---

## Emergency Recovery

If device won't boot at all:

1. **Enter Maskrom mode** (3 quick presses + 15 sec hold)
2. **Flash factory image**:
   ```bash
   cd /home/th3cavalry/photonicat2/release
   ./flash.sh
   # Select factory image when prompted
   ```
3. **Verify factory works**:
   - SSH to 172.16.0.1 after boot
   - All systems working

4. **Then try custom build again**:
   - Return to Maskrom
   - Flash custom image

---

## Getting Help

1. **Check logs** - Always first step:
   ```bash
   logread | grep -i error
   dmesg | grep -i error
   journalctl -e  # If systemd available
   ```

2. **Check documentation**:
   - `PROJECT_STATUS.md` - Session history & fixes
   - `QUICK_REFERENCE.md` - Common commands
   - `README.md` - Build instructions

3. **Factory image for reference**:
   - Located at: `/tmp/factory_extract/mnt_root/`
   - Or re-extract: `mount -o loop,offset=$(( 262144*512 )),ro factory.img mnt_root`

4. **Community resources**:
   - Telegram: https://t.me/+IATZElRYPydkM2Rl
   - OpenWrt docs: https://openwrt.org/docs/start

---

**Last Updated**: Nov 26, 2025 - 17:25  
**Build Status**: In Progress
