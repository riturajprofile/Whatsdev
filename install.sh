#!/bin/bash

# ============================================================
# WhatsDev Installer
# Downloads and installs pre-built AppImage - No build required!
# 
# Install (Normal Mode - default):
#   curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash -s 1
#
# Install (Low Resource Mode):
#   curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash -s 2
#   
# Uninstall:
#   curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash -s uninstall
# ============================================================

set -e

APP_NAME="WhatsDev"
VERSION="1.0.1"
INSTALL_DIR="$HOME/.local/whatsdev"
GITHUB_REPO="riturajprofile/whatsdev"
APPIMAGE_URL="https://github.com/$GITHUB_REPO/releases/latest/download/WhatsDev.AppImage"
ICON_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/icon.png"
DESKTOP_DIR="$HOME/.local/share/applications"
AUTOSTART_DIR="$HOME/.config/autostart"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
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
    echo "║                      v${VERSION}                                     ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_step() { echo -e "${MAGENTA}[→]${NC} $1"; }

# Confirm prompt
confirm() {
    local prompt="$1"
    local default="$2"
    
    if [[ "$default" == "y" ]]; then
        read -p "$prompt [Y/n] " -n 1 -r REPLY
    else
        read -p "$prompt [y/N] " -n 1 -r REPLY
    fi
    echo
    
    if [[ "$default" == "y" ]]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Check if already installed
check_existing() {
    if [[ -f "$INSTALL_DIR/WhatsDev.AppImage" ]]; then
        log_warn "WhatsDev is already installed, reinstalling..."
    fi
}

# Check for required tools
check_requirements() {
    log_step "Checking requirements..."
    
    if command -v curl &> /dev/null; then
        DOWNLOADER="curl"
        DOWNLOAD_CMD="curl -fsSL --progress-bar -o"
    elif command -v wget &> /dev/null; then
        DOWNLOADER="wget"
        DOWNLOAD_CMD="wget -q --show-progress -O"
    else
        log_error "Please install curl or wget"
        exit 1
    fi
    
    log_success "Using $DOWNLOADER for downloads"
}

# Install FUSE if needed (required for AppImage)
install_fuse() {
    log_step "Checking FUSE library..."
    
    if ldconfig -p 2>/dev/null | grep -q "libfuse.so.2\|libfuse2"; then
        log_success "FUSE is available"
        return 0
    fi
    
    log_warn "FUSE not found (required for AppImage)"
    log_info "Installing FUSE..."
    
    if command -v apt &> /dev/null; then
        sudo apt update -qq && sudo apt install -y libfuse2 || sudo apt install -y fuse
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y fuse-libs fuse
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm fuse2
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y fuse libfuse2
    elif command -v apk &> /dev/null; then
        sudo apk add fuse
    else
        log_error "Could not detect package manager"
        log_info "Please install fuse/libfuse2 manually and run installer again"
        exit 1
    fi
    
    log_success "FUSE installed"
}

# Download AppImage
download_appimage() {
    mkdir -p "$INSTALL_DIR"
    
    local NEED_DOWNLOAD=true
    
    # Check if AppImage already exists
    if [[ -f "$INSTALL_DIR/WhatsDev.AppImage" ]]; then
        local SIZE=$(stat -c%s "$INSTALL_DIR/WhatsDev.AppImage" 2>/dev/null || stat -f%z "$INSTALL_DIR/WhatsDev.AppImage" 2>/dev/null)
        if [[ "$SIZE" -gt 100000000 ]]; then
            # Size > 100MB means it's likely latest version
            log_success "Latest AppImage already installed ($(numfmt --to=iec $SIZE 2>/dev/null || echo "${SIZE} bytes"))"
            chmod +x "$INSTALL_DIR/WhatsDev.AppImage"
            NEED_DOWNLOAD=false
        else
            log_warn "Older version detected ($(numfmt --to=iec $SIZE 2>/dev/null || echo "${SIZE} bytes")), downloading latest..."
            rm -f "$INSTALL_DIR/WhatsDev.AppImage"
        fi
    fi
    
    if [[ "$NEED_DOWNLOAD" == "true" ]]; then
        log_step "Downloading WhatsDev AppImage v$VERSION..."
        echo ""
    
    local TEMP_FILE="$INSTALL_DIR/WhatsDev.AppImage.tmp"
    
    # Try GitHub releases first
    if [[ "$DOWNLOADER" == "curl" ]]; then
        if curl -fSL --progress-bar -o "$TEMP_FILE" "$APPIMAGE_URL" 2>&1; then
            mv "$TEMP_FILE" "$INSTALL_DIR/WhatsDev.AppImage"
        else
            log_warn "Release download failed, trying direct URL..."
            DIRECT_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/WhatsDev.AppImage"
            if curl -fSL --progress-bar -o "$TEMP_FILE" "$DIRECT_URL" 2>&1; then
                mv "$TEMP_FILE" "$INSTALL_DIR/WhatsDev.AppImage"
            else
                rm -f "$TEMP_FILE"
                log_error "Download failed. Please check your internet connection."
                exit 1
            fi
        fi
    else
        if wget --show-progress -O "$TEMP_FILE" "$APPIMAGE_URL" 2>&1; then
            mv "$TEMP_FILE" "$INSTALL_DIR/WhatsDev.AppImage"
        else
            log_warn "Release download failed, trying direct URL..."
            DIRECT_URL="https://raw.githubusercontent.com/$GITHUB_REPO/main/WhatsDev.AppImage"
            if wget --show-progress -O "$TEMP_FILE" "$DIRECT_URL" 2>&1; then
                mv "$TEMP_FILE" "$INSTALL_DIR/WhatsDev.AppImage"
            else
                rm -f "$TEMP_FILE"
                log_error "Download failed. Please check your internet connection."
                exit 1
            fi
        fi
    fi
    
    chmod +x "$INSTALL_DIR/WhatsDev.AppImage"
    
    # Verify the download
    local SIZE=$(stat -c%s "$INSTALL_DIR/WhatsDev.AppImage" 2>/dev/null || stat -f%z "$INSTALL_DIR/WhatsDev.AppImage" 2>/dev/null)
    if [[ "$SIZE" -lt 1000000 ]]; then
        log_error "Downloaded file seems too small. Download may have failed."
        rm -f "$INSTALL_DIR/WhatsDev.AppImage"
        exit 1
    fi
    
    echo ""
    log_success "Downloaded to: $INSTALL_DIR/WhatsDev.AppImage ($(numfmt --to=iec $SIZE 2>/dev/null || echo "${SIZE} bytes"))"
    fi
}

# Download icon
download_icon() {
    log_step "Downloading icon..."
    
    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL -o "$INSTALL_DIR/icon.png" "$ICON_URL" 2>/dev/null || true
    else
        wget -q -O "$INSTALL_DIR/icon.png" "$ICON_URL" 2>/dev/null || true
    fi
    
    if [[ -f "$INSTALL_DIR/icon.png" ]]; then
        log_success "Icon downloaded"
    else
        log_warn "Could not download icon (non-critical)"
    fi
}

# Performance mode flags
NORMAL_FLAGS="--no-sandbox"
LOW_RESOURCE_FLAGS="--no-sandbox --disable-gpu-sandbox --disable-software-rasterizer --disable-dev-shm-usage --disable-background-networking --disable-default-apps --disable-extensions --disable-sync --disable-translate --no-first-run --no-default-browser-check --single-process --js-flags=--max-old-space-size=256 --disable-features=TranslateUI --disable-ipc-flooding-protection --disable-renderer-backgrounding --memory-pressure-off"

# Selected flags (will be set by argument)
SELECTED_FLAGS="$NORMAL_FLAGS"

# Set performance mode from argument
set_performance_mode() {
    local mode="$1"
    case "$mode" in
        2)
            SELECTED_FLAGS="$LOW_RESOURCE_FLAGS"
            log_success "Low Resource Mode selected"
            ;;
        *)
            SELECTED_FLAGS="$NORMAL_FLAGS"
            log_success "Normal Mode selected"
            ;;
    esac
}

# Create desktop entry
create_desktop_entry() {
    log_step "Creating desktop launcher..."
    mkdir -p "$DESKTOP_DIR"
    
    cat > "$DESKTOP_DIR/whatsdev.desktop" << EOF
[Desktop Entry]
Name=WhatsDev
Comment=WhatsApp Web Desktop App
GenericName=WhatsApp Client
Exec=$INSTALL_DIR/WhatsDev.AppImage $SELECTED_FLAGS %U
Icon=$INSTALL_DIR/icon.png
Type=Application
Categories=Network;InstantMessaging;Chat;
StartupWMClass=WhatsDev
Terminal=false
Keywords=whatsapp;chat;messaging;web;
MimeType=x-scheme-handler/whatsapp;
Actions=quit;

[Desktop Action quit]
Name=Quit WhatsDev
Exec=killall WhatsDev
EOF
    
    chmod +x "$DESKTOP_DIR/whatsdev.desktop"
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    log_success "Desktop launcher created"
}

# Create autostart entry
create_autostart() {
    log_step "Setting up autostart..."
    mkdir -p "$AUTOSTART_DIR"
    
    cat > "$AUTOSTART_DIR/whatsdev.desktop" << EOF
[Desktop Entry]
Name=WhatsDev
Comment=WhatsApp Web Desktop App
Exec=$INSTALL_DIR/WhatsDev.AppImage $SELECTED_FLAGS --hidden
Icon=$INSTALL_DIR/icon.png
Type=Application
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=5
StartupNotify=false
Terminal=false
EOF
    
    log_success "Autostart enabled"
}

# Uninstall
uninstall() {
    print_banner
    log_info "Uninstalling WhatsDev..."
    echo ""
    
    # Kill running instance
    pkill -f "WhatsDev" 2>/dev/null || true
    
    # Remove all files and directories
    rm -rf "$INSTALL_DIR"
    rm -f "$DESKTOP_DIR/whatsdev.desktop"
    rm -f "$AUTOSTART_DIR/whatsdev.desktop"
    rm -rf "$HOME/.config/WhatsDev"
    
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    
    echo ""
    log_success "WhatsDev uninstalled completely!"
    exit 0
}

# Main
main() {
    # Check for uninstall
    if [[ "$1" == "uninstall" ]]; then
        uninstall
    fi
    
    print_banner
    log_info "Installing WhatsDev..."
    echo ""
    
    check_existing
    check_requirements
    install_fuse
    download_appimage
    download_icon
    
    # Set performance mode from argument (default: 1 = Normal)
    set_performance_mode "$1"
    
    # Always create desktop launcher and autostart
    create_desktop_entry
    create_autostart
    
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    Installation Complete!                       ${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Run:${NC} ~/.local/whatsdev/WhatsDev.AppImage"
    echo -e "  ${BOLD}Or:${NC}  Search 'WhatsDev' in app menu"
    echo ""
    
    log_step "Starting WhatsDev..."
    nohup "$INSTALL_DIR/WhatsDev.AppImage" $SELECTED_FLAGS > /dev/null 2>&1 &
    disown 2>/dev/null || true
    sleep 1
    log_success "WhatsDev is running!"
    
    echo ""
    log_success "Enjoy WhatsDev! 🚀"
    echo ""
}

main "$@"
