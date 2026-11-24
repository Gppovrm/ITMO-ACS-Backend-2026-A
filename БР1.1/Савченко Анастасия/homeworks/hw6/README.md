# ДЗ6: Автодеплой бэкенда через GitHub Actions

Workflow: [`.github/workflows/deploy.yml`](../../../../.github/workflows/deploy.yml)
Разворачиваемое приложение: [`labs/lab4`](../../labs/lab4) (сервер подготовлен в ЛР4).

## Как работает

```
git push → ветка hw6 ──▶ GitHub Actions
                          ├─ job build:  docker compose config → build → поднять стек в CI → curl /health
                          └─ job deploy (только если build зелёный):
                               SSH-ключ из секретов → rsync кода в /opt/restaurant-booking
                               → .env из секретов → scripts/deploy.sh (docker compose up -d --build)
                               → curl http://<IP>/health через nginx
```

- **Триггер:** `push` в ветку `hw6`, только если менялся код приложения или сам workflow; плюс ручной запуск (`workflow_dispatch`).
- **Секреты** не хранятся в репозитории: пароль БД и JWT-секрет попадают на сервер в `.env` с правами `600`.
- `concurrency` не даёт двум деплоям идти одновременно.
- Если сборка или смоук-тест падают, до сервера дело не доходит.

## Настройка (один раз)

1. **Включить Actions в форке:** вкладка *Actions* → *I understand my workflows, go ahead and enable them*.
2. **Отдельный SSH-ключ для деплоя** (на своём компьютере):
   ```bash
   ssh-keygen -t ed25519 -C "github-deploy" -f ~/.ssh/gh_deploy -N ""
   ssh-copy-id -i ~/.ssh/gh_deploy.pub ubuntu@<IP>
   ```
3. **Секреты:** *Settings → Environments → New environment* `production` → *Add secret*:

   | Секрет | Значение |
   |---|---|
   | `SSH_HOST` | публичный IP сервера |
   | `SSH_USER` | `ubuntu` (пользователь из группы docker) |
   | `SSH_PRIVATE_KEY` | содержимое `~/.ssh/gh_deploy` (приватный ключ целиком) |
   | `SSH_PORT` | необязательно, по умолчанию 22 |
   | `DB_PASS` | пароль Postgres (тот же, что в `.env` на сервере из ЛР4) |
   | `JWT_SECRET` | секрет для JWT |

   ⚠️ Postgres берёт пароль только при **первой** инициализации тома. Если меняете `DB_PASS`, на сервере нужно
   `docker compose down -v` (данные удалятся) или сменить пароль через `ALTER USER`.

4. **Проверка:** внести изменение в `labs/lab4` (например, текст в `api-gateway/src/index.ts`), `git push origin hw6`,
   открыть вкладку *Actions* и дождаться зелёных `build` и `deploy`.

## Что приложить в отчёт
1. Файл workflow с пояснениями.
2. Список секретов в Settings (значения скрыты).
3. Скриншот успешного запуска в Actions (оба job’а, логи шагов деплоя).
4. Демонстрация: коммит с изменением → новый запуск → изменение видно по `http://<IP>/...`.
5. (по желанию) упавший запуск при ошибке сборки — деплой не выполнился.
