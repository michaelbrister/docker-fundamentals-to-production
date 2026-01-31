# Lab 09 — Solution (reference)

```bash
docker compose build
docker compose up -d

curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes

# rebuild after a code change
docker compose build api
docker compose up -d --no-deps api

docker compose down
```
