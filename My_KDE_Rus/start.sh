#!/bin/bash

# Автоматически получаем путь к директории, где находится скрипт
CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Список конфигурационных файлов в этой папке
CONFIGS=("Gotham" "Process" "Network" "Weather" "Player")
# Путь к файлу обоев (ищется в той же папке)
WALLPAPER="$CONFIG_DIR/wallpaper.png"

# Флаг для управления сменой обоев (по умолчанию отключен)
CHANGE_WALLPAPER=false

set_wallpaper() {
    if [ -f "$WALLPAPER" ]; then
        echo "Setting KDE wallpaper..."
        # Короткая пауза, чтобы D-Bus сессия Plasma успела инициализироваться
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
    # Если скрипт запущен при загрузке системы, ждем подольше для загрузки рабочего стола
    if [ "$1" == "boot" ]; then
        echo "Waiting for desktop environment to load..."
        sleep 10
    fi

    # Меняем обои только если установлен флаг -change
    if [ "$CHANGE_WALLPAPER" = true ]; then
        set_wallpaper
    else
        echo "  [i] Wallpaper change skipped (use -change flag to enable)"
    fi

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

# Разбираем аргументы для проверки флага -change
for arg in "$@"; do
    case "$arg" in
        -change)
            CHANGE_WALLPAPER=true
            ;;
    esac
done

# Основная логика команд
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
