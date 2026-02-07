# Lab 15 — Solution (reference)

## 1) Create local-only files
```bash
cp .env.example .env
cp secrets/db_password.txt.example secrets/db_password.txt
# edit secrets/db_password.txt (>= 12 chars, single line)
cp OBSERVABILITY_NOTES_TEMPLATE.md OBSERVABILITY_NOTES.md
```

## 2) Run the platform
```bash
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build
curl -s http://localhost:8080/metrics | head
```

## 3) Generate traffic and observe
```bash
curl -s http://localhost:8080/notes > /dev/null
curl -s -X POST http://localhost:8080/notes -H 'content-type: application/json' -d '{"message":"hello"}' > /dev/null
curl -s http://localhost:8080/metrics | egrep 'http_requests_total|http_errors_total|http_request_duration_ms_(count|sum)'
docker compose logs api --tail 80
```

## 4) DB outage drill
```bash
docker compose stop db
curl -i http://localhost:8080/readyz
curl -i http://localhost:8080/notes
curl -s http://localhost:8080/metrics | egrep 'db_ping_failures_total|http_errors_total'
docker compose start db
```

## 5) Cleanup
```bash
docker compose -f compose.yaml -f compose.secrets.yaml down
```
