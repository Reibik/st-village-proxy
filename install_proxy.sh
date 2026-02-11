#!/bin/bash

# 1. Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите скрипт от имени root (sudo)."
  exit
fi

echo "--- Начало установки MTProxy (Official Image) ---"

# 2. Проверка Docker
if ! command -v docker &> /dev/null; then
    echo "Docker не найден. Устанавливаем..."
    apt-get update && apt-get install -y curl
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "Docker уже установлен."
fi

# 3. Настройка параметров
# Порт на сервере (внешний)
PORT=8443

# Генерация секрета (32 hex символа)
SECRET=$(head -c 16 /dev/urandom | xxd -ps)

echo "Параметры:"
echo "Порт: $PORT"
echo "Секрет: $SECRET"

# 4. Очистка и запуск
# Удаляем старый контейнер, если он есть (или если он сломан)
docker rm -f mtproto-proxy &> /dev/null

echo "Скачиваем и запускаем официальный контейнер Telegram..."

# Запуск официального образа
# Обратите внимание: внутри контейнера порт всегда 443, мы мапим его на ваш $PORT
docker run -d -p $PORT:443 \
    --name=mtproto-proxy \
    --restart=always \
    -e SECRET=$SECRET \
    telegrammessenger/proxy:latest

# Проверка, запустился ли контейнер
if [ $? -eq 0 ]; then
    PUBLIC_IP=$(curl -s -4 ifconfig.me)
    
    echo ""
    echo "------------------------------------------------"
    echo "✅ MTProxy УСПЕШНО ЗАПУЩЕН!"
    echo "------------------------------------------------"
    echo "IP сервера: $PUBLIC_IP"
    echo "Порт: $PORT"
    echo "Secret: $SECRET"
    echo "------------------------------------------------"
    echo "Ссылка для подключения (нажмите для копирования):"
    echo "tg://proxy?server=$PUBLIC_IP&port=$PORT&secret=$SECRET"
    echo "------------------------------------------------"
else
    echo ""
    echo "❌ Ошибка при запуске Docker контейнера. Проверьте логи: docker logs mtproto-proxy"
fi
