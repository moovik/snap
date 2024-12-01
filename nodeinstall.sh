#!/bin/bash

# Параметры для swap
SWAP_FILE="/swapfile"
SWAP_SIZE="300G"

# 1. Обновляем сервер и устанавливаем необходимый софт
echo "Обновляем сервер и устанавливаем необходимый софт..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget nano git htop iotop dstat inotify-tools lvm2

echo "Обновление и установка ПО завершены."

# 2. Получаем список NVMe-дисков
nvme_disks=$(lsblk -dn -o NAME,TYPE | grep "disk" | awk '{print $1}')
echo "Найденные NVMe-диски: $nvme_disks"

# 3. Определяем диск, на котором находится системный раздел "/"
system_disk=$(lsblk -dn -o NAME,MOUNTPOINT | grep " /$" | awk '{print $1}')
echo "Системный диск: $system_disk"

# 4. Проверяем, какие диски свободны
for disk in $nvme_disks; do
    if [[ "$disk" == "$system_disk" ]]; then
        echo "Пропускаем системный диск: $disk"
        continue
    fi

    # Проверяем, смонтирован ли диск
    if lsblk -dn -o NAME,MOUNTPOINT | grep -q "^$disk "; then
        mount_point=$(lsblk -dn -o NAME,MOUNTPOINT | grep "^$disk " | awk '{print $2}')
        echo "Диск $disk уже смонтирован в $mount_point."

        if [[ "$mount_point" == "/mnt/disk2" ]]; then
            echo "Диск $disk уже настроен. Пропускаем настройку."
            break
        else
            echo "Диск $disk смонтирован в $mount_point, обновляем монтирование."
            sudo umount "/dev/$disk"
        fi
    fi

    # Проверяем, есть ли старые записи в /etc/fstab для этого диска
    if grep -q "/dev/$disk" /etc/fstab; then
        echo "Удаляем старую запись для /dev/$disk из /etc/fstab."
        sudo sed -i "\|/dev/$disk|d" /etc/fstab
    fi

    # Проверяем, есть ли разделы на диске
    if lsblk -dn -o NAME,TYPE | grep -q "^$disk part"; then
        echo "Ошибка: На диске $disk есть существующие разделы. Необходима ручная проверка."
        exit 1
    fi

    # 5. Форматируем незанятый диск и монтируем его в /mnt/disk2
    echo "Форматируем и монтируем диск $disk в /mnt/disk2..."
    sudo mkfs.ext4 "/dev/$disk" -F
    sudo mkdir -p /mnt/disk2
    sudo mount "/dev/$disk" /mnt/disk2

    # 6. Добавляем актуальную запись в /etc/fstab
    echo "/dev/$disk /mnt/disk2 ext4 defaults 0 0" | sudo tee -a /etc/fstab

    echo "Диск $disk успешно настроен."
    break
done

# Если не найден подходящий диск
if ! mount | grep -q "/mnt/disk2"; then
    echo "Ошибка: Не найден свободный диск для монтирования в /mnt/disk2."
    exit 1
fi

# 7. Создание папки /mnt/ramdisk
echo "Создаём папку /mnt/ramdisk..."
sudo mkdir -p /mnt/ramdisk
echo "Папка /mnt/ramdisk создана."

# 8. Отключение текущих swap
echo "Отключаем активные swap..."
sudo swapoff -a

# 9. Закомментирование старых swap-записей в /etc/fstab
echo "Закомментируем старые swap-записи в /etc/fstab..."
sudo sed -i '/swap/ s/^/#/' /etc/fstab

# 10. Проверка существования нового swap-файла
if [[ -f "$SWAP_FILE" ]]; then
    echo "Swap-файл уже существует: $SWAP_FILE. Удаляем для создания нового..."
    sudo rm -f "$SWAP_FILE"
fi

# 11. Создание нового swap-файла
echo "Создаём новый swap-файл размером $SWAP_SIZE..."
sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE" || { echo "Ошибка при создании swap-файла."; exit 1; }
sudo chmod 600 "$SWAP_FILE"
sudo mkswap "$SWAP_FILE"
sudo swapon "$SWAP_FILE"

# 12. Добавление нового swap в /etc/fstab
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "Добавляем запись для нового swap-файла в /etc/fstab..."
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# 13. Проверка статуса swap
echo "Новый swap-файл активирован:"
swapon --show

echo "Настройка завершена."
