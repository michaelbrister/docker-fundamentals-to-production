# Lab 14 — Solution (reference)

## 1) Create local-only files
```bash
cp .env.example .env
cp secrets/db_password.txt.example secrets/db_password.txt
# edit secrets/db_password.txt (single line)
```

## 2) Base compose fails without secrets (expected)
```bash
docker compose -f compose.yaml up -d --build
docker compose logs api --tail 80
docker compose -f compose.yaml down
```

## 3) Correct run: use the secrets overlay
```bash
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes
docker compose -f compose.yaml -f compose.secrets.yaml down
```

## 4) Change config without rebuilding
Edit `.env` (LOG_LEVEL / APP_ENV), then:
```bash
docker compose -f compose.yaml -f compose.secrets.yaml up -d
docker compose logs api --tail 50
```
No rebuild is required for config changes.
