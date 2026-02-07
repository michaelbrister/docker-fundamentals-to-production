# Lab 12 — Solution (reference)

## Baseline
```bash
docker compose -f compose.yaml up -d --build
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
docker compose -f compose.yaml down
```

## Distroless hardened
```bash
docker compose -f compose.distroless.yaml up -d --build
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes

# Prove no shell:
docker exec -it lab12-api sh  # should fail

docker compose -f compose.distroless.yaml down
```

If schema is missing because volume already exists:
```bash
docker compose -f compose.distroless.yaml down -v
docker compose -f compose.distroless.yaml up -d --build
```
