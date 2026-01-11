#!/bin/bash

# Автоматическое определение пути к папке, в которой находится этот скрипт
CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Список файлов конфигурации в этой папке
CONFIGS=("Gotham" "Process" "Network" "Weather")
# Путь к файлу обоев (ищется в той же папке)
WALLPAPER="$CONFIG_DIR/wallpaper.png"

set_wallpaper() {
    if [ -f "$WALLPAPER" ]; then
        echo "Установка обоев KDE..."
        # Короткая пауза, чтобы Plasma успела инициализировать сессию D-Bus
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
        echo "  [-] Обои не найдены: $WALLPAPER"
    fi
}

start_conky() {
    # Если скрипт запускается при старте системы, ждем дольше для загрузки рабочего стола
    if [ "$1" == "boot" ]; then
        echo "Ожидание загрузки рабочего стола..."
        sleep 10
    fi

    set_wallpaper

    echo "Запуск Conky..."
    for config in "${CONFIGS[@]}"; do
        FILE_PATH="$CONFIG_DIR/$config"
        if [ -f "$FILE_PATH" ]; then
            conky -c "$FILE_PATH" -d
            echo "  [+] $config запущен"
        else
            echo "  [-] ОШИБКА: $config не найден"
        fi
    done
}

stop_conky() {
    echo "Остановка всех процессов Conky..."
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
        # Специальный режим для автозагрузки
        stop_conky
        start_conky "boot"
        ;;
    *)
        # Действие по умолчанию: перезапуск
        stop_conky
        start_conky
        ;;
esac

exit 0
