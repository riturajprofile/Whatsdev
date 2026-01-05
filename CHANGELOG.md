# Changelog

All notable changes to WhatsDev will be documented in this file.

## [1.0.1] - 2026-01-05

### Added
- 🔔 **Desktop notifications with sound** for new messages
  - Displays sender name in notification title
  - Shows message preview (up to 100 characters) in notification body
  - Click notification to focus WhatsDev window
  - Only triggers when window is unfocused to avoid spam
  
- 🔢 **Unread badge on tray icon**
  - Shows message count directly on the tray icon
  - Real-time updates as messages arrive
  - Displays up to 99+ for large counts
  
- 📋 **Message preview on hover**
  - Hover over tray icon to see detailed unread message summary
  - Displays sender names with message counts
  - Shows last message preview for each conversation
  - Lists top 5 chats with "and more" indicator

### Improved
- Enhanced notification reliability
- Better memory management for message tracking
- Improved tooltip formatting
- Optimized message polling (every 5 seconds)

### Changed
- Updated to Electron 28.3.3
- Improved user agent for better WhatsApp Web compatibility

## [1.0.0] - 2026-01-01

### Initial Release
- ✅ Portable AppImage for Linux
- ✅ System tray integration
- ✅ Clean UI without menu bar clutter
- ✅ Single instance lock
- ✅ Autostart support
- ✅ Performance modes (Normal/Low Resource)
- ✅ Modern Chrome user agent
