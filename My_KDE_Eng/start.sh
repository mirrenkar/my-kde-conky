#!/bin/bash

# Automatically get the path to the directory where this script is located
CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# List of config files in this folder
CONFIGS=("Gotham" "Process" "Network" "Weather" "Player")
# Path to the wallpaper file (searches in the same folder)
WALLPAPER="$CONFIG_DIR/wallpaper.png"

set_wallpaper() {
    if [ -f "$WALLPAPER" ]; then
        echo "Setting KDE wallpaper..."
        # Short pause to ensure Plasma has initialized the D-Bus session
        sleep 2
        dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript "string:
        var Desktops = desktops();
        for (i=0;i<Desktops.length;i++) {
            d = Desktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://$WALLPAPER');
        }"
    else
        echo "  [-] Wallpaper not found: $WALLPAPER"
    fi
}

start_conky() {
    # If the script runs at system startup, wait a bit longer for the desktop to load
    if [ "$1" == "boot" ]; then
        echo "Waiting for desktop environment to load..."
        sleep 10
    fi

    set_wallpaper

    echo "Starting Conky..."
    for config in "${CONFIGS[@]}"; do
        FILE_PATH="$CONFIG_DIR/$config"
        if [ -f "$FILE_PATH" ]; then
            conky -c "$FILE_PATH" -d
            echo "  [+] $config started"
        else
            echo "  [-] ERROR: $config not found"
        fi
    done
}

stop_conky() {
    echo "Stopping all Conky processes..."
    killall conky 2>/dev/null
    sleep 1
}

case "$1" in
    stop)
        stop_conky
        ;;
    restart)
        stop_conky
        start_conky
        ;;
    boot)
        stop_conky
        start_conky "boot"
        ;;
    *)
        stop_conky
        start_conky
        ;;
esac

exit 0
