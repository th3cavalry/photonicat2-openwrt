# Quick Start: Building OpenWrt for Photonicat 2

## PRIMARY RECOMMENDED METHOD ⭐

Building your own OpenWrt image is the **recommended** way to flash your Photonicat 2. You get:
- ✅ Full customization and control
- ✅ Latest security updates
- ✅ Latest features and optimizations
- ✅ Reproducible, verifiable builds

## Fastest Way to Build

### One Command Build (Everything)

```bash
cd ~/path/to/photonicat2
./scripts/build-openwrt.sh --full --extract --backup
```

This will:
1. ✅ Clone Photonicat OpenWrt repository
2. ✅ Update feeds and packages
3. ✅ Open configuration menu (menuconfig)
4. ✅ Download all sources
5. ✅ Compile firmware
6. ✅ Extract the image
7. ✅ Backup to `~/photonicat2-images/`

**Time:** 2-4 hours on first build (depends on CPU and internet)

---

## Step-by-Step Manual Build

If you prefer more control, follow [05-BUILDING_OPENWRT.md](./guides/05-BUILDING_OPENWRT.md)

---

## After Building

Your flashable image is ready at:
```
~/openwrt-builds/openwrt/bin/targets/rockchip/armv8/
```

**Image file:** `openwrt-rockchip-armv8-armsom_sige7-*.img.gz`

### Next: Flash to Device

Follow [01-INSTALLATION.md](./guides/01-INSTALLATION.md) to flash your custom image to Photonicat 2

---

## Build Script Options

```bash
# Full build with options
./scripts/build-openwrt.sh [OPTIONS]

OPTIONS:
  -f, --full               Full build (clone → configure → download → compile)
  -c, --clone              Clone repository only
  -d, --download           Download sources only  
  -b, --build              Configure and compile only
  -j, --jobs N             Parallel jobs (default: auto-detect CPU cores)
  -v, --verbose            Show detailed build output
  --extract                Extract compressed image after build
  --backup                 Backup images to ~/photonicat2-images/
  --dir DIR                Custom build directory (default: ~/openwrt-builds)
```

### Common Builds

```bash
# Quick test with 2 cores
./scripts/build-openwrt.sh --full --jobs 2

# Verbose build to see all compile output
./scripts/build-openwrt.sh --full --verbose

# Build only (repo already cloned, config exists)
./scripts/build-openwrt.sh --build --extract

# Use custom directory
./scripts/build-openwrt.sh --full --dir /tmp/openwrt
```

---

## Troubleshooting Build

### Build Fails During Compilation

```bash
# Check what went wrong and retry
cd ~/openwrt-builds/openwrt
make clean
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig     # reconfigure if needed
make download -j8
make V=s -j1        # single-threaded verbose for debugging
```

### Out of Disk Space

```bash
# Free up space
cd ~/openwrt-builds/lede
make distclean       # removes everything
# Or use external drive with --dir option
./scripts/build-openwrt.sh --full --dir /mnt/external/openwrt
```

### Need to Reconfigure

```bash
cd ~/openwrt-builds/lede
rm -rf .config
make menuconfig
make V=s -j1
```

---

## What's in the Config Menu?

When `menuconfig` opens, you need:

1. **Target System** → `Rockchip`
2. **Subtarget** → `Rockchip RK3568/RK3566`  
3. **Target Profile** → `ArmSoM Sige7` (upstream profile for Photonicat 2)
4. **Target Images** → Select desired formats
5. **Kernel Modules** → Add SPI, USB-serial for modem
6. **LuCI** (optional) → Web interface

Space bar to toggle options, Q to save and exit.

---

## Next Steps

1. ✅ Build complete → Image at `~/openwrt-builds/lede/bin/targets/rockchip/rockchip-rk3568/`
2. 🔧 Flash to device → See [01-INSTALLATION.md](./guides/01-INSTALLATION.md)
3. 🖥️ Setup LCD → See [02-LCD_SCREEN_SETUP.md](./guides/02-LCD_SCREEN_SETUP.md)
4. 📡 Configure 5G → See [03-5G_MODEM_SETUP.md](./guides/03-5G_MODEM_SETUP.md)

---

**Pro Tips:**
- 💾 First build takes 2-4 hours, subsequent builds much faster
- 🔄 Keep `--backup` flag to organize images by build date
- 📊 Use `--jobs 4` or `--jobs 8` for faster builds on multi-core systems
- 🐛 Add `--verbose` if troubleshooting build issues

