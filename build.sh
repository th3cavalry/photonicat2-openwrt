#!/bin/bash

#############################################################################
# Photonicat 2 OpenWrt Build System Wrapper
# 
# This script wraps the upstream photonicat_openwrt build process and
# applies custom configurations for factory-like installation with NVMe
# overlay support.
#
# Usage: ./build.sh
#
#############################################################################

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Configuration
BUILD_DIR="${BUILD_DIR:-$(pwd)/build}"
UPSTREAM_REPO="https://github.com/photonicat/photonicat_openwrt"
UPSTREAM_DIR="$BUILD_DIR/photonicat_openwrt"
CUSTOM_CONFIG="$(pwd)/configs/pcat2_custom.config"
CUSTOM_FILES="$(pwd)/files"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    
    # Check required commands
    for cmd in git make gcc curl wget; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=("$cmd")
        else
            print_success "$cmd found"
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[@]}"
        echo ""
        echo "Install on Ubuntu/Debian:"
        echo "  sudo apt update && sudo apt install -y build-essential git curl wget"
        exit 1
    fi
}

check_custom_config() {
    print_header "Checking Custom Configuration"
    
    if [ ! -f "$CUSTOM_CONFIG" ]; then
        print_error "Custom config not found: $CUSTOM_CONFIG"
        echo ""
        print_info "Please generate a custom config file using the upstream diffconfig.sh script:"
        print_info "  1. Build OpenWrt upstream with desired settings"
        print_info "  2. Run: ./scripts/diffconfig.sh > $CUSTOM_CONFIG"
        print_info "  3. See configs/README.md for required options"
        echo ""
        exit 1
    fi
    
    print_success "Custom config found: $CUSTOM_CONFIG"
}

clone_upstream() {
    print_header "Cloning Upstream Repository"
    
    if [ -d "$UPSTREAM_DIR" ]; then
        print_warning "Upstream repository already exists at $UPSTREAM_DIR"
        read -p "Update existing repo? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$UPSTREAM_DIR"
            git pull origin master || git pull origin main
            print_success "Repository updated"
        fi
    else
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        git clone "$UPSTREAM_REPO" photonicat_openwrt
        cd photonicat_openwrt
        print_success "Repository cloned to $UPSTREAM_DIR"
    fi
}

update_feeds() {
    print_header "Updating and Installing Feeds"
    
    cd "$UPSTREAM_DIR"
    ./scripts/feeds update -a
    print_success "Feeds updated"
    
    ./scripts/feeds install -a
    print_success "Feeds installed"
}

apply_custom_config() {
    print_header "Applying Custom Configuration"
    
    cd "$UPSTREAM_DIR"
    
    # Copy custom config
    cp "$CUSTOM_CONFIG" .config
    print_success "Custom config copied to .config"
    
    # Run defconfig to expand the config
    make defconfig
    print_success "Configuration expanded with defconfig"
}

copy_custom_files() {
    print_header "Copying Custom Files"
    
    if [ -d "$CUSTOM_FILES" ]; then
        # Find the package/base-files/files directory or similar
        local target_dir="$UPSTREAM_DIR/package/base-files/files"
        
        if [ -d "$target_dir" ]; then
            cp -r "$CUSTOM_FILES"/* "$target_dir/"
            print_success "Custom files copied to $target_dir"
        else
            print_warning "Target directory $target_dir not found"
            print_info "Custom files will be integrated during package build"
            
            # Alternative: copy to a staging area that gets integrated
            mkdir -p "$UPSTREAM_DIR/files"
            cp -r "$CUSTOM_FILES"/* "$UPSTREAM_DIR/files/"
            print_success "Custom files copied to $UPSTREAM_DIR/files"
        fi
    else
        print_warning "No custom files directory found at $CUSTOM_FILES"
    fi
}

download_sources() {
    print_header "Downloading Sources"
    
    cd "$UPSTREAM_DIR"
    
    print_info "This may take 10-30 minutes depending on your connection..."
    make download -j${PARALLEL_JOBS}
    
    print_success "Sources downloaded"
}

build_image() {
    print_header "Building OpenWrt Image"
    
    cd "$UPSTREAM_DIR"
    
    print_info "This may take 1-4 hours on first build..."
    print_info "Using $PARALLEL_JOBS parallel jobs"
    echo ""
    
    make -j${PARALLEL_JOBS}
    
    print_success "Build completed successfully!"
}

show_results() {
    print_header "Build Complete!"
    
    local output_dir="$UPSTREAM_DIR/bin/targets"
    
    if [ -d "$output_dir" ]; then
        echo ""
        print_info "Compiled images can be found in:"
        find "$output_dir" -name "*.img*" -o -name "*.bin" 2>/dev/null | while read img; do
            echo "  $img"
        done
        echo ""
        print_success "Flash the image to your Photonicat 2 eMMC"
        print_info "The image will automatically use NVMe for /overlay if present"
    else
        print_warning "Output directory not found: $output_dir"
    fi
}

show_usage() {
    cat << USAGEEOF
Usage: $0 [OPTIONS]

This script builds a custom OpenWrt image for Photonicat 2 with:
  - Factory-like installation on eMMC
  - Automatic NVMe overlay mount on first boot
  - Custom kernel modules and configurations

OPTIONS:
    -h, --help              Show this help message
    -j, --jobs N            Number of parallel jobs (default: $(nproc))
    --dir DIR               Build directory (default: ./build)
    --skip-clone            Skip cloning upstream repo
    --skip-feeds            Skip feed update/install
    
EXAMPLES:
    # Full build
    $0
    
    # Build with 4 parallel jobs
    $0 --jobs 4
    
    # Rebuild without updating feeds
    $0 --skip-feeds

USAGEEOF
}

# Main script
main() {
    local skip_clone=0
    local skip_feeds=0
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_usage; exit 0 ;;
            -j|--jobs) 
                if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    print_error "Missing value for --jobs"
                    exit 1
                fi
                PARALLEL_JOBS="$2"
                shift 
                ;;
            --dir) 
                if [ -z "$2" ] || [[ "$2" =~ ^- ]]; then
                    print_error "Missing value for --dir"
                    exit 1
                fi
                BUILD_DIR="$2"
                UPSTREAM_DIR="$BUILD_DIR/photonicat_openwrt"
                shift 
                ;;
            --skip-clone) skip_clone=1 ;;
            --skip-feeds) skip_feeds=1 ;;
            *) print_error "Unknown option: $1"; show_usage; exit 1 ;;
        esac
        shift
    done
    
    print_info "Photonicat 2 OpenWrt Build System Wrapper"
    print_info "Build directory: $BUILD_DIR"
    print_info "Parallel jobs: $PARALLEL_JOBS"
    echo ""
    
    # Run checks
    check_dependencies
    check_custom_config
    
    # Execute build steps
    if [ $skip_clone -eq 0 ]; then
        clone_upstream
    else
        print_info "Skipping upstream clone"
    fi
    
    if [ $skip_feeds -eq 0 ]; then
        update_feeds
    else
        print_info "Skipping feed update"
    fi
    
    apply_custom_config
    copy_custom_files
    download_sources
    build_image
    show_results
    
    echo ""
    print_success "Done!"
}

# Run main function
main "$@"
