# ЛР4: Развёртывание приложения на удалённом сервере

Приложение — сервис бронирования столиков (микросервисы из ЛР2/ЛР3):
`api-gateway` → `auth-service`, `restaurant-service`, `booking-service`, PostgreSQL (БД на каждый сервис).

## Схема

```
Интернет ──:80──▶ nginx (на хосте, reverse proxy)
                     │ proxy_pass 127.0.0.1:3000
                     ▼
              ┌─ docker compose ───────────────────────────┐
              │ gateway:3000 ─┬─▶ auth:8001       ─┐       │
              │               ├─▶ restaurant:8002 ─┼─▶ postgres:5432
              │               └─▶ booking:8003    ─┘       │
              └────────────────────────────────────────────┘
```

Наружу открыты только 22 (SSH) и 80/443 (nginx). Порты сервисов и БД доступны лишь внутри docker-сети,
gateway слушает только `127.0.0.1`.

## Что изменено относительно ЛР3

| Проблема в ЛР3 | Исправление |
|---|---|
| БД `auth_db`, `restaurant_db`, `booking_db` нигде не создавались → сервисы падали | `db/init.sql` монтируется в `docker-entrypoint-initdb.d` |
| `booking-service` ходил в `localhost:8001/8002` (внутри контейнера это он сам) | адреса через `AUTH_URL`, `RESTAURANT_URL` |
| Логин/пароль БД и JWT-секрет захардкожены | читаются из env, значения — в `.env` (не в git) |
| Все порты (в т.ч. Postgres, RabbitMQ) торчали наружу | наружу только nginx; gateway на `127.0.0.1:3000` |
| При ошибке подключения к БД процесс висел без сервера | `process.exit(1)` + `restart: unless-stopped` |
| Нет точки для проверки работоспособности | `GET /health` в gateway |
| gateway скачивал `tsx` при каждом старте контейнера | `tsx` ставится при сборке образа; добавлен `.dockerignore` |

## Шаги развёртывания

### 1. Сервер
Любая ВМ с Ubuntu 22.04/24.04, 2 vCPU / 2 ГБ RAM (например, грант Yandex Cloud).
При создании указать свой публичный SSH-ключ.

```bash
ssh ubuntu@<IP>
```

### 2. Предварительная настройка (зависимости)
```bash
git clone https://github.com/Gppovrm/ITMO-ACS-Backend-2026-A.git ~/repo
cd ~/repo && git switch lab-4
sudo bash "БР1.1/Савченко Анастасия/labs/lab4/scripts/server-setup.sh" ubuntu
exit   # перелогиниться, чтобы применилась группа docker
```
Скрипт ставит Docker Engine + compose plugin, nginx, git, настраивает ufw и создаёт `/opt/restaurant-booking`.

### 3. Развёртывание приложения
```bash
ssh ubuntu@<IP>
cp -r ~/repo/"БР1.1/Савченко Анастасия/labs/lab4"/. /opt/restaurant-booking/
cd /opt/restaurant-booking
cp .env.example .env && nano .env        # задать DB_PASS и JWT_SECRET
bash scripts/deploy.sh
docker compose ps
```

Наполнить БД тестовыми данными (по желанию):
```bash
docker compose exec restaurant npx tsx seed.ts
docker compose exec auth npx tsx seed.ts
```

### 4. nginx как обратный прокси
```bash
sudo cp nginx/restaurant-booking.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/restaurant-booking.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

### 5. Проверка извне
```bash
curl http://<IP>/health
curl http://<IP>/api/v1/restaurants
curl -X POST http://<IP>/api/v1/auth/register -H "Content-Type: application/json" \
     -d '{"email":"test@mail.ru","password":"123456","name":"Test","phone_num":"+79990000000"}'
```

## Что приложить в отчёт (скриншоты)
1. Характеристики ВМ в консоли облака.
2. Вывод `docker --version`, `docker compose version`, `nginx -v` после `server-setup.sh`.
3. `docker compose ps` — все контейнеры `Up`.
4. `sudo nginx -t` и содержимое конфига.
5. Запросы к `http://<IP>/...` из браузера/Postman **с вашего компьютера**.
6. `sudo ufw status` — открыты только SSH и Nginx.
