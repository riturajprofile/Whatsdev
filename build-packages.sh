#!/bin/bash

# ============================================================
# WhatsDev Package Builder
# Build Snap and Flatpak packages from AppImage
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           WhatsDev Package Builder                             ║"
    echo "║           Build Snap & Flatpak from AppImage                   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_snapcraft() {
    if ! command -v snapcraft &> /dev/null; then
        log_warn "snapcraft not found"
        log_info "Install with: sudo snap install snapcraft --classic"
        return 1
    fi
    return 0
}

check_flatpak_builder() {
    if ! command -v flatpak-builder &> /dev/null; then
        log_warn "flatpak-builder not found"
        log_info "Install with: sudo apt install flatpak-builder"
        return 1
    fi
    return 0
}

build_snap() {
    log_info "Building Snap package..."
    
    if ! check_snapcraft; then
        log_error "Cannot build Snap without snapcraft"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
    
    # Copy icon to snap/gui
    if [[ -f "icon.png" ]]; then
        cp icon.png snap/gui/icon.png
    fi
    
    # Build snap
    snapcraft --verbose
    
    if [[ -f whatsdev_*.snap ]]; then
        log_success "Snap package built: $(ls whatsdev_*.snap)"
        echo ""
        log_info "Install with: sudo snap install whatsdev_*.snap --dangerous"
    else
        log_error "Snap build failed"
        return 1
    fi
}

build_flatpak() {
    log_info "Building Flatpak package..."
    
    if ! check_flatpak_builder; then
        log_error "Cannot build Flatpak without flatpak-builder"
        return 1
    fi
    
    cd "$SCRIPT_DIR/flatpak"
    
    # Copy icon
    if [[ -f "../icon.png" ]]; then
        cp ../icon.png icon.png
    fi
    
    # Calculate SHA256 of AppImage
    log_info "Downloading AppImage to calculate SHA256..."
    APPIMAGE_URL="https://github.com/riturajprofile/whatsdev/releases/latest/download/WhatsDev.AppImage"
    
    if command -v curl &> /dev/null; then
        SHA256=$(curl -sL "$APPIMAGE_URL" | sha256sum | cut -d' ' -f1)
    else
        SHA256=$(wget -qO- "$APPIMAGE_URL" | sha256sum | cut -d' ' -f1)
    fi
    
    # Update manifest with SHA256
    sed -i "s/PLACEHOLDER_SHA256/$SHA256/" com.github.riturajprofile.WhatsDev.yml
    
    # Install Flatpak runtime if needed
    log_info "Ensuring Flatpak runtime is installed..."
    flatpak install -y flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08 2>/dev/null || true
    
    # Build flatpak
    flatpak-builder --force-clean --user --install-deps-from=flathub build-dir com.github.riturajprofile.WhatsDev.yml
    
    # Create bundle
    flatpak-builder --repo=repo --force-clean build-dir com.github.riturajprofile.WhatsDev.yml
    flatpak build-bundle repo whatsdev.flatpak com.github.riturajprofile.WhatsDev
    
    if [[ -f whatsdev.flatpak ]]; then
        mv whatsdev.flatpak ../
        log_success "Flatpak package built: whatsdev.flatpak"
        echo ""
        log_info "Install with: flatpak install whatsdev.flatpak"
    else
        log_error "Flatpak build failed"
        return 1
    fi
    
    cd "$SCRIPT_DIR"
}

show_help() {
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  snap      Build Snap package only"
    echo "  flatpak   Build Flatpak package only"
    echo "  all       Build both Snap and Flatpak"
    echo "  help      Show this help message"
    echo ""
}

main() {
    print_banner
    
    case "$1" in
        snap)
            build_snap
            ;;
        flatpak)
            build_flatpak
            ;;
        all|"")
            echo ""
            log_info "Building all packages..."
            echo ""
            
            build_snap || log_warn "Snap build skipped/failed"
            echo ""
            build_flatpak || log_warn "Flatpak build skipped/failed"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    log_success "Build process complete!"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
}

main "$@"
