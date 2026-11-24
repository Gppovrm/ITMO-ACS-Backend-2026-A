#!/usr/bin/env bash
# Развёртывание/обновление приложения. Запускается на сервере из каталога приложения
# (вручную в ЛР4, автоматически из GitHub Actions в ДЗ6).
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "Нет файла .env — скопируйте .env.example в .env и задайте секреты" >&2
  exit 1
fi

docker compose pull postgres
docker compose up -d --build --remove-orphans
docker image prune -f

echo "==> Ждём, пока поднимется api-gateway"
for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:3000/health >/dev/null; then
    echo "OK: приложение отвечает"
    docker compose ps
    exit 0
  fi
  sleep 2
done
echo "api-gateway не ответил за 60 c" >&2
docker compose ps
docker compose logs --tail=50
exit 1
