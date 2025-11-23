#!/bin/bash

#############################################################################
# Photonicat 2 OpenWrt Build Helper Script
# 
# This script automates the OpenWrt build process for Photonicat 2
# Usage: ./build-openwrt.sh [OPTIONS]
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
BUILD_DIR="${BUILD_DIR:-$HOME/openwrt-builds}"
REPO_URL="https://github.com/photonicat/photonicat_openwrt"
REPO_DIR="$BUILD_DIR/lede"
PARALLEL_JOBS="${PARALLEL_JOBS:-$(nproc)}"
VERBOSE="${VERBOSE:-0}"

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

check_user() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Do NOT run this script as root!"
        exit 1
    fi
    print_success "Running as non-root user"
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
        echo "  sudo apt update && sudo apt install -y ${missing_deps[@]}"
        exit 1
    fi
}

check_disk_space() {
    print_header "Checking Disk Space"
    
    # Check available space (need at least 50GB)
    local available=$(df "$BUILD_DIR" | tail -1 | awk '{print $4}')
    local required=$((50 * 1024 * 1024))  # 50GB in KB
    
    if [ $available -lt $required ]; then
        print_warning "Low disk space: $(numfmt --to=iec $((available * 1024))) available"
        print_warning "Recommended: at least 50GB"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Sufficient disk space: $(numfmt --to=iec $((available * 1024)))"
    fi
}

clone_repo() {
    print_header "Cloning OpenWrt Repository"
    
    if [ -d "$REPO_DIR" ]; then
        print_warning "Repository already exists at $REPO_DIR"
        read -p "Update existing repo? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$REPO_DIR"
            git pull origin master
            print_success "Repository updated"
        fi
    else
        mkdir -p "$BUILD_DIR"
        cd "$BUILD_DIR"
        git clone "$REPO_URL" lede
        cd lede
        print_success "Repository cloned to $REPO_DIR"
    fi
}

update_feeds() {
    print_header "Updating Feeds"
    
    cd "$REPO_DIR"
    ./scripts/feeds update -a
    print_success "Feeds updated"
    
    ./scripts/feeds install -a
    print_success "Feeds installed"
}

configure_build() {
    print_header "Configuring Build"
    
    cd "$REPO_DIR"
    
    if [ -f ".config" ]; then
        print_warning ".config already exists"
        read -p "Reconfigure? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f .config
            make menuconfig
        fi
    else
        make menuconfig
    fi
    
    print_success "Build configured"
}

download_sources() {
    print_header "Downloading Sources"
    
    cd "$REPO_DIR"
    
    print_info "This may take 10-30 minutes..."
    make download -j${PARALLEL_JOBS}
    
    print_success "Sources downloaded"
}

compile_firmware() {
    print_header "Compiling Firmware"
    
    cd "$REPO_DIR"
    
    if [ $VERBOSE -eq 1 ]; then
        print_info "Compilation with verbose output..."
        make V=s -j${PARALLEL_JOBS}
    else
        print_info "Compilation in progress (use Ctrl+C to cancel)..."
        make -j${PARALLEL_JOBS}
    fi
    
    print_success "Firmware compiled successfully!"
}

locate_images() {
    print_header "Build Complete!"
    
    local output_dir="$REPO_DIR/bin/targets/rockchip/rockchip-rk3568"
    
    if [ -d "$output_dir" ]; then
        echo ""
        print_info "Compiled images:"
        ls -lh "$output_dir"/*.img* 2>/dev/null || echo "No images found"
        echo ""
        print_info "Output directory: $output_dir"
    fi
}

extract_image() {
    print_header "Extracting Image"
    
    local output_dir="$REPO_DIR/bin/targets/rockchip/rockchip-rk3568"
    local image=$(ls "$output_dir"/*.img.gz 2>/dev/null | head -1)
    
    if [ -z "$image" ]; then
        print_error "No compressed image found"
        return 1
    fi
    
    print_info "Extracting: $(basename $image)"
    gunzip -f "$image"
    
    local extracted="${image%.gz}"
    print_success "Image extracted: $extracted"
}

backup_image() {
    print_header "Backing Up Image"
    
    local backup_dir="$HOME/photonicat2-images/$(date +%Y%m%d-%H%M%S)"
    local output_dir="$REPO_DIR/bin/targets/rockchip/rockchip-rk3568"
    
    mkdir -p "$backup_dir"
    cp "$output_dir"/*.img "$backup_dir/" 2>/dev/null || true
    cp "$output_dir"/*.md5 "$backup_dir/" 2>/dev/null || true
    
    print_success "Images backed up to: $backup_dir"
}

show_usage() {
    cat << USAGEEOF
Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -c, --clone             Clone repository only
    -d, --download          Download sources only
    -b, --build             Compile firmware only
    -f, --full              Full build (clone, download, compile)
    -j, --jobs N            Number of parallel jobs (default: $(nproc))
    -v, --verbose           Verbose output
    --dir DIR               Build directory (default: $BUILD_DIR)
    --extract               Extract compiled image after build
    --backup                Backup compiled image

EXAMPLES:
    # Full build
    $0 --full

    # Build with 4 parallel jobs
    $0 --full --jobs 4

    # Clone and update only
    $0 --clone

    # Download and compile with extraction
    $0 --download --build --extract

USAGEEOF
}

# Main script
main() {
    local action="full"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_usage; exit 0 ;;
            -c|--clone) action="clone" ;;
            -d|--download) action="download" ;;
            -b|--build) action="build" ;;
            -f|--full) action="full" ;;
            -j|--jobs) PARALLEL_JOBS="$2"; shift ;;
            -v|--verbose) VERBOSE=1 ;;
            --dir) BUILD_DIR="$2"; REPO_DIR="$BUILD_DIR/lede"; shift ;;
            --extract) EXTRACT=1 ;;
            --backup) BACKUP=1 ;;
            *) print_error "Unknown option: $1"; show_usage; exit 1 ;;
        esac
        shift
    done
    
    print_info "Photonicat 2 OpenWrt Build Helper"
    print_info "Build directory: $BUILD_DIR"
    print_info "Parallel jobs: $PARALLEL_JOBS"
    echo ""
    
    # Run checks
    check_user
    check_dependencies
    check_disk_space
    
    # Execute requested actions
    case $action in
        clone)
            clone_repo
            update_feeds
            ;;
        download)
            clone_repo
            update_feeds
            download_sources
            ;;
        build)
            cd "$REPO_DIR" 2>/dev/null || clone_repo
            configure_build
            download_sources
            compile_firmware
            locate_images
            ;;
        full)
            clone_repo
            update_feeds
            configure_build
            download_sources
            compile_firmware
            locate_images
            [ $EXTRACT -eq 1 ] && extract_image
            [ $BACKUP -eq 1 ] && backup_image
            ;;
    esac
    
    echo ""
    print_success "Done!"
}

# Run main function
main "$@"
