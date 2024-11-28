#!/bin/bash

# Переменные
SNAPSHOT_URL="http://api.mainnet-beta.solana.com/snapshot.tar.bz2"
INCREMENTAL_SNAPSHOT_URL="http://api.mainnet-beta.solana.com/incremental-snapshot.tar.bz2"
TARGET_DIR="/root/solana/snapshots/"
SNAPSHOT_MASK="snapshot-*.tar.*"
INCREMENTAL_SNAPSHOT_MASK="incremental-snapshot-*.tar.*"

# Функция для загрузки файла с проверкой
download_file() {
    local url="$1"
    local target_dir="$2"
    local success=0

    # Загрузка с повторными попытками
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

# Проверяем, существует ли основной снимок
if ls "${TARGET_DIR}${SNAPSHOT_MASK}" 1>/dev/null 2>&1; then
    echo "Основной снимок уже существует."
else
    echo "Основной снимок отсутствует. Начинаем загрузку..."
    download_file "$SNAPSHOT_URL" "$TARGET_DIR"
fi

# Если основной снимок существует, переходим к загрузке инкрементального снимка
if ls "${TARGET_DIR}${SNAPSHOT_MASK}" 1>/dev/null 2>&1; then
    echo "Переходим к загрузке инкрементального снимка..."
    if ls "${TARGET_DIR}${INCREMENTAL_SNAPSHOT_MASK}" 1>/dev/null 2>&1; then
        echo "Инкрементальный снимок уже существует."
    else
        download_file "$INCREMENTAL_SNAPSHOT_URL" "$TARGET_DIR"
    fi
else
    echo "Основной снимок отсутствует. Инкрементальный снимок загружаться не будет."
    exit 1
fi

# Перезагрузка демонов и перезапуск Solana
systemctl daemon-reload
systemctl restart solana.service

# Мониторинг валидатора
agave-validator --ledger /root/solana/ledger monitor
