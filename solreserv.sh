#!/bin/bash

# Переменные
API_URL="http://api.mainnet-beta.solana.com"
SNAPSHOT_MASK="snapshot-*.tar.*"
INCREMENTAL_SNAPSHOT_MASK="incremental-snapshot-*.tar.*"
TARGET_DIR="$HOME/solana/snapshots"

# Проверяем, передан ли pubkey
if [ -n "$1" ]; then
    pabkey=$1
else
    echo "NO TRUSTED PUBKEY PROVIDED"
    exit 1
fi

echo "Используемый pubkey: $pabkey"

# Пытаемся найти IP-адрес по pubkey
ip=$(solana gossip | grep $pabkey | awk '{print $1}')
if [ -n "$ip" ]; then
    ip="$ip:8899"
    echo "IP-адрес узла: $ip"
else
    echo "Не удалось найти узел по указанному pubkey. Будет использован основной API."
    ip="$API_URL"
fi

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

# Проверяем наличие основного снимка
if ls "${TARGET_DIR}/${SNAPSHOT_MASK}" 1>/dev/null 2>&1; then
    echo "Основной снимок уже существует."
else
    echo "Начинаем загрузку основного снимка..."
    download_file "http://$ip/snapshot.tar.bz2" "$TARGET_DIR"
fi

# Проверяем наличие инкрементального снимка
if ls "${TARGET_DIR}/${INCREMENTAL_SNAPSHOT_MASK}" 1>/dev/null 2>&1; then
    echo "Инкрементальный снимок уже существует."
else
    if ls "${TARGET_DIR}/${SNAPSHOT_MASK}" 1>/dev/null 2>&1; then
        echo "Основной снимок найден. Начинаем загрузку инкрементального снимка..."
        download_file "http://$ip/incremental-snapshot.tar.bz2" "$TARGET_DIR"
    else
        echo "Основной снимок отсутствует. Инкрементальный снимок загружаться не будет."
        exit 1
    fi
fi

# Перезагрузка демонов и перезапуск Solana
systemctl daemon-reload
systemctl restart solana.service

# Мониторинг валидатора
agave-validator --ledger /root/solana/ledger monitor
