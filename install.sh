#!/bin/bash

# ============================================================
# WhatsDev Installer
# Downloads and installs pre-built AppImage - No build required!
# 
# One-line install:
#   curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash
#   
# Or with wget:
#   wget -qO- https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash
# ============================================================

set -e

APP_NAME="WhatsDev"
INSTALL_DIR="$HOME/Applications"
GITHUB_REPO="riturajprofile/whatsdev"
APPIMAGE_URL="https://github.com/$GITHUB_REPO/releases/latest/download/WhatsDev.AppImage"
ICON_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/icon.png"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║     █     █ █   █  ███  █████ ███  ███   ███ █   █             ║"
    echo "║     █     █ █   █ █   █   █   █  █ █  █ █    █   █             ║"
    echo "║     █  █  █ █████ █████   █   █  █ █  █ ████ █   █             ║"
    echo "║     █ █ █ █ █   █ █   █   █   █  █ █  █ █     █ █              ║"
    echo "║      █   █  █   █ █   █   █   ███  ███   ███   █               ║"
    echo "║                                                                ║"
    echo "║              WhatsApp Web Desktop for Linux                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }

# Check for required tools
check_requirements() {
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl -fsSL -o"
    elif command -v wget &> /dev/null; then
        DOWNLOADER="wget -q -O"
    else
        log_error "Please install curl or wget"
        exit 1
    fi
}

# Install FUSE if needed (required for AppImage)
install_fuse() {
    if ! ldconfig -p 2>/dev/null | grep -q libfuse; then
        log_info "Installing FUSE (required for AppImage)..."
        
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y libfuse2
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y fuse-libs
        elif command -v pacman &> /dev/null; then
            sudo pacman -Sy --noconfirm fuse2
        elif command -v zypper &> /dev/null; then
            sudo zypper install -y fuse
        else
            log_warn "Could not install FUSE automatically. Please install it manually."
        fi
    fi
}

# Download AppImage
download_appimage() {
    mkdir -p "$INSTALL_DIR"
    
    log_info "Downloading WhatsDev AppImage..."
    
    if ! $DOWNLOADER "$INSTALL_DIR/WhatsDev.AppImage" "$APPIMAGE_URL"; then
        log_error "Failed to download AppImage"
        log_info "Trying alternative download..."
        
        # Try direct raw download if releases not set up yet
        DIRECT_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/WhatsDev.AppImage"
        $DOWNLOADER "$INSTALL_DIR/WhatsDev.AppImage" "$DIRECT_URL" || {
            log_error "Download failed. Please check your internet connection."
            exit 1
        }
    fi
    
    chmod +x "$INSTALL_DIR/WhatsDev.AppImage"
    log_success "Downloaded to: $INSTALL_DIR/WhatsDev.AppImage"
}

# Download icon
download_icon() {
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
    mkdir -p "$ICON_DIR"
    
    $DOWNLOADER "$ICON_DIR/whatsdev.png" "$ICON_URL" 2>/dev/null || true
}

# Create desktop entry
create_desktop_entry() {
    DESKTOP_DIR="$HOME/.local/share/applications"
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
    
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/whatsdev.desktop" << EOF
[Desktop Entry]
Name=WhatsDev
Comment=WhatsApp Web Desktop App
Exec=$INSTALL_DIR/WhatsDev.AppImage
Icon=$ICON_DIR/whatsdev.png
Type=Application
Categories=Network;InstantMessaging;Chat;
StartupWMClass=WhatsDev
Terminal=false
Keywords=whatsapp;chat;messaging;
EOF
    
    chmod +x "$DESKTOP_DIR/whatsdev.desktop"
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    log_success "Desktop launcher created"
}

# Create autostart entry
create_autostart() {
    AUTOSTART_DIR="$HOME/.config/autostart"
    ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
    
    mkdir -p "$AUTOSTART_DIR"
    
    cat > "$AUTOSTART_DIR/whatsdev.desktop" << EOF
[Desktop Entry]
Name=WhatsDev
Comment=WhatsApp Web Desktop App
Exec=$INSTALL_DIR/WhatsDev.AppImage
Icon=$ICON_DIR/whatsdev.png
Type=Application
X-GNOME-Autostart-enabled=true
StartupNotify=false
Terminal=false
EOF
    
    log_success "Autostart enabled"
}

# Uninstall
uninstall() {
    log_info "Uninstalling WhatsDev..."
    
    rm -f "$HOME/Applications/WhatsDev.AppImage"
    rm -f "$HOME/.local/share/applications/whatsdev.desktop"
    rm -f "$HOME/.config/autostart/whatsdev.desktop"
    rm -f "$HOME/.local/share/icons/hicolor/512x512/apps/whatsdev.png"
    
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    log_success "WhatsDev uninstalled"
    exit 0
}

# Main
main() {
    # Check for uninstall flag
    if [[ "$1" == "--uninstall" ]] || [[ "$1" == "-u" ]]; then
        uninstall
    fi
    
    print_banner
    
    log_info "Installing WhatsDev..."
    echo ""
    
    check_requirements
    install_fuse
    download_appimage
    download_icon
    
    echo ""
    read -p "Create desktop launcher? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        create_desktop_entry
    fi
    
    read -p "Start on login? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_autostart
    fi
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    Installation Complete!                       ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}Run:${NC} ~/Applications/WhatsDev.AppImage"
    echo -e "  ${CYAN}Or:${NC}  Search 'WhatsDev' in your app menu"
    echo ""
    echo -e "  ${CYAN}Uninstall:${NC} curl -sSL https://raw.githubusercontent.com/$GITHUB_REPO/main/install.sh | bash -s -- --uninstall"
    echo ""
    
    read -p "Launch WhatsDev now? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        nohup "$INSTALL_DIR/WhatsDev.AppImage" > /dev/null 2>&1 &
        log_success "WhatsDev is starting!"
    fi
    
    echo ""
    log_success "Enjoy WhatsDev! 🚀"
}

main "$@"
