#!/usr/bin/env bash
# Предварительная настройка чистого сервера Ubuntu 22.04/24.04.
# Запуск на сервере:  sudo bash server-setup.sh <имя_пользователя_для_деплоя>
set -euo pipefail

DEPLOY_USER="${1:-${SUDO_USER:-ubuntu}}"
APP_DIR="/opt/restaurant-booking"

echo "==> Обновление пакетов"
apt-get update
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg git ufw nginx

echo "==> Установка Docker Engine + compose plugin"
if ! command -v docker >/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
systemctl enable --now docker
usermod -aG docker "$DEPLOY_USER"

echo "==> Каталог приложения $APP_DIR"
mkdir -p "$APP_DIR"
chown "$DEPLOY_USER:$DEPLOY_USER" "$APP_DIR"

echo "==> Файрвол: открыты только SSH и HTTP(S)"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo "==> Готово. Перелогиньтесь, чтобы группа docker применилась к $DEPLOY_USER"
docker --version
docker compose version
nginx -v
