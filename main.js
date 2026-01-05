const { app, BrowserWindow, Tray, Menu, nativeImage, shell } = require('electron');
const path = require('path');

// Suppress GPU warnings
app.commandLine.appendSwitch('disable-gpu-vsync');
app.commandLine.appendSwitch('disable-frame-rate-limit');

let mainWindow;
let tray;
let isQuitting = false;

const userAgent = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

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
            webviewTag: false
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

    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
    });

    mainWindow.webContents.on('page-title-updated', (event, title) => {
        if (tray) {
            const match = title.match(/\((\d+)\)/);
            if (match) {
                tray.setToolTip('WhatsDev - ' + match[1] + ' unread');
            } else {
                tray.setToolTip('WhatsDev');
            }
        }
    });
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
