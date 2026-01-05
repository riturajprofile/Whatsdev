const { app, BrowserWindow, Tray, Menu, nativeImage, shell } = require('electron');
const path = require('path');

// Suppress GPU warnings
app.commandLine.appendSwitch('disable-gpu-vsync');
app.commandLine.appendSwitch('disable-frame-rate-limit');

let mainWindow;
let tray;
let isQuitting = false;
let unreadCount = 0;
let unreadChats = [];
let lastNotifiedCount = 0;

const userAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

function showNotification(title, body, silent = false) {
    if (!mainWindow || mainWindow.isDestroyed()) return;
    
    const notification = {
        title: title,
        body: body,
        icon: path.join(__dirname, 'icons/icon.png'),
        silent: silent,
        urgency: 'normal',
        timeoutType: 'default'
    };
    
    // Show notification
    mainWindow.webContents.send('show-notification', notification);
    
    // Use Electron's Notification API
    const { Notification } = require('electron');
    if (Notification.isSupported()) {
        const n = new Notification(notification);
        n.on('click', () => {
            mainWindow.show();
            mainWindow.focus();
        });
        n.show();
    }
}

function updateTrayIcon(count) {
    if (!tray) return;
    
    const iconPath = path.join(__dirname, 'icons/tray-icon.png');
    let baseIcon;
    
    try {
        baseIcon = nativeImage.createFromPath(iconPath);
        if (baseIcon.isEmpty()) {
            baseIcon = nativeImage.createFromPath(path.join(__dirname, 'icons/icon.png'));
        }
    } catch (error) {
        console.error('Error loading tray icon:', error);
        return;
    }

    if (count === 0) {
        tray.setImage(baseIcon.resize({ width: 22, height: 22 }));
        return;
    }

    // Create badge with count using Electron's native image API
    try {
        // Use overlay to show badge (Linux notification style)
        const size = baseIcon.getSize();
        const overlaySize = Math.floor(size.width * 0.6);
        
        // Create a simple badge overlay
        // On Linux, we can use the badge count feature if available
        tray.setImage(baseIcon.resize({ width: 22, height: 22 }));
        
        // For Linux systems that support app indicator badges
        if (process.platform === 'linux' && app.setBadgeCount) {
            app.setBadgeCount(count);
        }
    } catch (error) {
        console.error('Error creating badge:', error);
        tray.setImage(baseIcon.resize({ width: 22, height: 22 }));
    }
}

function updateTooltip() {
    if (!tray) return;
    
    if (unreadCount === 0) {
        tray.setToolTip('WhatsDev');
        return;
    }
    
    let tooltip = `WhatsDev - ${unreadCount} unread message${unreadCount > 1 ? 's' : ''}`;
    
    if (unreadChats.length > 0) {
        tooltip += '\n\n';
        unreadChats.forEach(chat => {
            tooltip += `${chat.name} (${chat.count})\n`;
            if (chat.lastMessage) {
                tooltip += `  ${chat.lastMessage}${chat.lastMessage.length >= 50 ? '...' : ''}\n`;
            }
        });
        
        if (unreadCount > unreadChats.length) {
            tooltip += `\n... and more`;
        }
    }
    
    tray.setToolTip(tooltip);
}

function createWindow() {
    mainWindow = new BrowserWindow({
        width: 1200,
        height: 800,
        show: false,
        frame: true,              // Keep window frame with close/min/max buttons
        autoHideMenuBar: true,    // Hide menu bar
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            webviewTag: false,
            enableRemoteModule: false,
            spellcheck: true
        },
        icon: path.join(__dirname, 'icons/icon.png'),
        title: 'WhatsDev'
    });

    // Remove application menu (File, Edit, View, etc.) but keep title bar
    Menu.setApplicationMenu(null);

    mainWindow.webContents.setUserAgent(userAgent);
    mainWindow.loadURL('https://web.whatsapp.com');

    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
    });

    // Keep title as WhatsDev even when WhatsApp changes it
    mainWindow.on('page-title-updated', (event) => {
        event.preventDefault();
    });
    mainWindow.setTitle('WhatsDev');

    mainWindow.on('close', (event) => {
        if (!isQuitting) {
            event.preventDefault();
            mainWindow.hide();
            return false;
        }
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
    
    mainWindow.on('focus', () => {
        // Reset notification count when user focuses the window
        lastNotifiedCount = unreadCount;
    });

    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
    });

    mainWindow.webContents.on('page-title-updated', (event, title) => {
        if (tray) {
            const match = title.match(/\((\d+)\)/);
            if (match) {
                const newCount = parseInt(match[1], 10);
                
                // Show notification for new messages
                if (newCount > lastNotifiedCount && !mainWindow.isFocused()) {
                    const newMessages = newCount - lastNotifiedCount;
                    showNotification(
                        'WhatsDev - New Messages',
                        `You have ${newMessages} new message${newMessages > 1 ? 's' : ''}`,
                        false
                    );
                }
                
                lastNotifiedCount = newCount;
                unreadCount = newCount;
                updateTrayIcon(unreadCount);
                tray.setToolTip('WhatsDev - ' + match[1] + ' unread');
            } else {
                unreadCount = 0;
                lastNotifiedCount = 0;
                updateTrayIcon(0);
                tray.setToolTip('WhatsDev');
            }
        }
    });

    // Get unread message details for tooltip
    setInterval(() => {
        if (mainWindow && !mainWindow.isDestroyed()) {
            mainWindow.webContents.executeJavaScript(`
                (() => {
                    try {
                        const chats = [];
                        const chatElements = document.querySelectorAll('[data-testid="cell-frame-container"]');
                        
                        chatElements.forEach(chat => {
                            const unreadBadge = chat.querySelector('[data-testid="icon-unread-count"]');
                            if (unreadBadge) {
                                const nameElement = chat.querySelector('[data-testid="cell-frame-title"]');
                                const lastMessageElement = chat.querySelector('[data-testid="last-msg-text"]');
                                
                                const name = nameElement ? nameElement.textContent : 'Unknown';
                                const count = unreadBadge.parentElement?.textContent || '1';
                                const lastMessage = lastMessageElement ? lastMessageElement.textContent : '';
                                
                                chats.push({ name, count, lastMessage: lastMessage.substring(0, 50) });
                            }
                        });
                        
                        return chats;
                    } catch (e) {
                        return [];
                    }
                })()
            `).then(chats => {
                // Check for new chats with unread messages
                if (chats.length > 0 && !mainWindow.isFocused()) {
                    const newChats = chats.filter(chat => {
                        return !unreadChats.some(old => old.name === chat.name && old.count === chat.count);
                    });
                    
                    // Show detailed notification for new chat messages
                    newChats.slice(0, 3).forEach(chat => {
                        const body = chat.lastMessage 
                            ? `${chat.lastMessage.substring(0, 100)}${chat.lastMessage.length > 100 ? '...' : ''}`
                            : `${chat.count} unread message${chat.count !== '1' ? 's' : ''}`;
                        
                        showNotification(chat.name, body, false);
                    });
                }
                
                unreadChats = chats.slice(0, 5); // Limit to 5 most recent
                updateTooltip();
            }).catch(() => {});
        }
    }, 5000); // Update every 5 seconds
}

function createTray() {
    const iconPath = path.join(__dirname, 'icons/tray-icon.png');
    let trayIcon;
    
    try {
        trayIcon = nativeImage.createFromPath(iconPath);
        if (trayIcon.isEmpty()) {
            trayIcon = nativeImage.createFromPath(path.join(__dirname, 'icons/icon.png'));
        }
        trayIcon = trayIcon.resize({ width: 22, height: 22 });
    } catch (error) {
        console.error('Error loading tray icon:', error);
        trayIcon = nativeImage.createEmpty();
    }

    tray = new Tray(trayIcon);

    const contextMenu = Menu.buildFromTemplate([
        {
            label: 'Show WhatsDev',
            click: () => {
                mainWindow.show();
                mainWindow.focus();
            }
        },
        {
            label: 'Hide WhatsDev',
            click: () => {
                mainWindow.hide();
            }
        },
        {
            type: 'separator'
        },
        {
            label: 'Quit WhatsDev',
            click: () => {
                isQuitting = true;
                app.quit();
            }
        }
    ]);

    tray.setContextMenu(contextMenu);
    tray.setToolTip('WhatsDev');

    tray.on('click', () => {
        if (mainWindow.isVisible()) {
            mainWindow.hide();
        } else {
            mainWindow.show();
            mainWindow.focus();
        }
    });
}

const gotTheLock = app.requestSingleInstanceLock();

if (!gotTheLock) {
    app.quit();
} else {
    app.on('second-instance', () => {
        if (mainWindow) {
            if (mainWindow.isMinimized()) mainWindow.restore();
            if (!mainWindow.isVisible()) mainWindow.show();
            mainWindow.focus();
        }
    });

    app.whenReady().then(() => {
        createWindow();
        createTray();
    });
}

app.on('before-quit', () => {
    isQuitting = true;
});

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    } else if (mainWindow) {
        mainWindow.show();
        mainWindow.focus();
    }
});

app.on('window-all-closed', (event) => {
    event.preventDefault();
});
