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
# Пакеты из официального репозитория Ubuntu (на Yandex Cloud идут через mirror.yandex.ru).
# download.docker.com из российских облаков часто недоступен, поэтому его не используем.
if ! command -v docker >/dev/null; then
  apt-get install -y docker.io docker-compose-v2 docker-buildx
fi

# CDN Docker Hub (cloudfront) из РФ недоступен — образы тянем через зеркало
if [ ! -f /etc/docker/daemon.json ]; then
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": ["https://dockerhub.timeweb.cloud"],
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
EOF
  systemctl restart docker
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
