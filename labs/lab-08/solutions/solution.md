# Lab 08 — Solution (reference)

This is reference-only.

---

## Start the system
```bash
docker compose up -d
docker compose ps
```

## Health vs readiness
```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
```

## Read notes
```bash
curl -s http://localhost:8080/notes
```

## Write a note
```bash
curl -s -X POST http://localhost:8080/notes   -H "Content-Type: application/json"   -d '{"message":"note created via api"}'
```

## Restart API (data should remain)
```bash
docker compose restart api
curl -s http://localhost:8080/notes
```

## Cleanup (required)
```bash
docker compose down
```

Optional destructive cleanup:
```bash
docker compose down -v
```
