# WhatsDev

<p align="center">
  <img src="icon.png" alt="WhatsDev Logo" width="128" height="128">
</p>

<h3 align="center">WhatsApp Web Desktop App for Linux</h3>

<p align="center">
  A lightweight, portable WhatsApp desktop client that runs on any Linux distribution.
</p>

<p align="center">
  <a href="https://snapcraft.io/whatsdev">
    <img alt="Get it from the Snap Store" src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg" />
  </a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#download">Download</a> •
  <a href="#license">License</a>
</p>

---

## Features

✅ **Portable AppImage** - No installation required, runs on any Linux distro  
✅ **Snap Package** - Available on Snap Store for easy installation  
✅ **System Tray Integration** - Minimize to tray, click to restore  
✅ **Unread Badge** - Shows unread message count on tray icon  
✅ **Smart Notifications** - Desktop notifications with sound for new messages  
✅ **Message Preview** - Hover over tray icon to see unread message summary  
✅ **Clean UI** - No menu bar clutter, just WhatsApp  
✅ **Single Instance** - Prevents multiple windows  
✅ **Modern Chrome UA** - Bypasses browser compatibility checks  
✅ **Lightweight** - ~180MB AppImage with Electron  
✅ **Performance Modes** - Choose between Normal or Low Resource mode during install  

## Installation

### Install from Snap Store 
```bash
sudo snap install whatsdev
```

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/whatsdev)

### One-Line Install (AppImage) (Recommended)

**Normal Mode (default):**
```bash
curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash
```

**Low Resource Mode (for older PCs):**
```bash
curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash -s 2
```

Or using wget:
```bash
wget -qO- https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash
```

The installer will automatically:
- Download the latest AppImage (updates old versions)
- Create a desktop launcher
- Enable autostart on login
- Launch WhatsDev

### Performance Modes

Choose your mode during installation:

| Mode | Command | RAM Usage | Description |
|------|---------|-----------|-------------|
| **Normal Mode** | `bash` or `bash -s 1` | ~300-500MB | Full features, best experience |
| **Low Resource Mode** | `bash -s 2` | ~150-250MB | Optimized for older PCs |

**Low Resource Mode** is recommended for:
- Older computers with limited RAM
- Systems running many applications
- Lightweight Linux distributions

### Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash -s uninstall
```

### Supported Distributions

| Distribution | Status |
|-------------|--------|
| Ubuntu / Debian | ✅ Supported |
| Linux Mint | ✅ Supported |
| Fedora | ✅ Supported |
| Arch Linux | ✅ Supported |
| Manjaro | ✅ Supported |
| openSUSE | ✅ Supported |
| Pop!_OS | ✅ Supported |
| Other | ✅ Supported |

## Download

### Pre-built Packages

| Format | Download | Install Command |
|--------|----------|-----------------|
| **Snap** | [![Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/whatsdev) | `sudo snap install whatsdev` |
| **AppImage** | [Download](https://github.com/riturajprofile/whatsdev/releases/latest/download/WhatsDev.AppImage) | `chmod +x WhatsDev.AppImage && ./WhatsDev.AppImage` |
| **Flatpak** | Coming Soon | `flatpak install whatsdev` |

### Pre-built AppImage

Download the latest AppImage directly:

```bash
# Download
wget https://github.com/riturajprofile/whatsdev/releases/download/v1.0.0/WhatsDev.AppImage

# Make executable
chmod +x WhatsDev.AppImage

# Run
./WhatsDev.AppImage
```

Or download from [Releases](https://github.com/riturajprofile/whatsdev/releases).


### System Tray

- **Left Click**: Toggle window visibility
- **Right Click**: Show context menu
  - Show WhatsDev
  - Hide WhatsDev
  - Quit WhatsDev
- **Hover**: View unread message summary with sender names and message previews

### Notifications

WhatsDev provides native desktop notifications:
- 🔔 **Sound alerts** for new messages
- 👤 **Sender name** displayed in notification title
- 💬 **Message preview** shown in notification body
- 🖱️ **Click to focus** - Click notification to open WhatsDev
- 🎯 **Smart triggers** - Only notifies when window is unfocused

### Unread Badge

- Shows unread message count directly on tray icon
- Updates in real-time as messages arrive
- Displays up to 99+ for large counts

### Keyboard Shortcuts

Use standard WhatsApp Web shortcuts:
- `Ctrl + N` - New chat
- `Ctrl + Shift + ]` - Next chat
- `Ctrl + Shift + [` - Previous chat
- `Ctrl + E` - Archive chat
- `Ctrl + Shift + M` - Mute chat

## Screenshots

<p align="center">
  <img src="https://web.whatsapp.com/img/intro-connection-light.png" alt="WhatsDev Screenshot" width="600">
</p>

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/riturajprofile/whatsdev/main/install.sh | bash -s -- --uninstall
```

## Requirements

- Linux x86_64
- FUSE (auto-installed if missing)

### Installing FUSE

```bash
# Ubuntu/Debian
sudo apt install libfuse2

# Fedora
sudo dnf install fuse-libs

# Arch
sudo pacman -S fuse2
```

## Troubleshooting

### AppImage won't run

```bash
# Install FUSE
sudo apt install libfuse2  # Debian/Ubuntu
# or
sudo dnf install fuse-libs  # Fedora
```

### "Update Chrome" message

This is fixed in the latest version. Re-run the build script to get the updated version with modern Chrome user agent.

### GPU/VSync errors

These are harmless warnings and can be ignored. They don't affect functionality.

### SUID sandbox error

If you see an error like `The SUID sandbox helper binary was found, but is not configured correctly`, run with the `--no-sandbox` flag:

```bash
./WhatsDev.AppImage --no-sandbox
```

## Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

### Building Packages

To build Snap and Flatpak packages locally:

```bash
# Build all packages (Snap + Flatpak)
./build-packages.sh all

# Build only Snap
./build-packages.sh snap

# Build only Flatpak
./build-packages.sh flatpak
```

**Requirements:**
- Snap: `sudo snap install snapcraft --classic`
- Flatpak: `sudo apt install flatpak-builder`

## License

MIT License - feel free to use, modify, and distribute.

## Credits

- Built with [Electron](https://www.electronjs.org/)
- Packaged with [electron-builder](https://www.electron.build/)
- WhatsApp is a trademark of Meta Platforms, Inc.

---

<p align="center">
  Made with ❤️ for the Linux community
</p>

<p align="center">
  <a href="https://github.com/riturajprofile/whatsdev/stargazers">⭐ Star this repo</a> •
  <a href="https://github.com/riturajprofile/whatsdev/issues">🐛 Report Bug</a> •
  <a href="https://github.com/riturajprofile/whatsdev/issues">💡 Request Feature</a>
</p>
