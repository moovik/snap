#!/bin/bash

# Переменные
SNAPSHOT_URL="http://api.mainnet-beta.solana.com/snapshot.tar.bz2"
INCREMENTAL_SNAPSHOT_URL="http://api.mainnet-beta.solana.com/incremental-snapshot.tar.bz2"
TARGET_DIR="/root/solana/snapshots/"

# Функция для загрузки файла с повторными попытками
download_file() {
    local url="$1"
    local target_dir="$2"
    local success=0

    while [ $success -eq 0 ]; do
        wget --trust-server-names -P "$target_dir" "$url"
        if [ $? -eq 0 ]; then
            echo "Файл $url успешно скачан!"
            success=1
        else
            echo "Ошибка загрузки файла $url, повтор через 5 секунд..."
            sleep 5
        fi
    done
}

# Скачивание первого файла
echo "Пытаемся скачать основной снимок..."
download_file "$SNAPSHOT_URL" "$TARGET_DIR"

# Если первый файл успешно скачан, пробуем скачать второй
if [ $? -eq 0 ]; then
    echo "Основной снимок успешно скачан. Переходим к загрузке инкрементального снимка..."
    download_file "$INCREMENTAL_SNAPSHOT_URL" "$TARGET_DIR"
else
    echo "Не удалось скачать основной снимок. Загрузка инкрементального снимка отменена."
    exit 1
fi

# Перезагрузка демонов и перезапуск Solana
systemctl daemon-reload
systemctl restart solana.service

# Мониторинг валидатора
agave-validator --ledger /root/solana/ledger monitor
