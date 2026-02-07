# Lab 15 — Observability: Logs, Metrics, and Signals (mini-platform)

## Goal
You will upgrade the mini-platform so you can **operate it like a production system**:

- Emit **structured logs** (not random print statements)
- Expose **metrics** at `/metrics` (Prometheus text format)
- Use logs + metrics to diagnose failures **without exec/SSH**
- Prove it works under a realistic failure (DB outage)

> Strict mode: cleanup is required (`docker compose down`).

---

## What you will build
A Go API + Postgres system (same shape as Labs 08–14) with:

- `/healthz` (process alive)
- `/readyz` (dependency-ready)
- `/notes` (API functionality)
- `/metrics` (operational metrics)

---

## Prerequisites
- Labs 08–14 recommended
- Docker + Docker Compose working

---

## Lab structure
```text
lab-15/
├── README.md
├── .env.example
├── OBSERVABILITY_NOTES_TEMPLATE.md
├── OBSERVABILITY_NOTES.md            # you create this
├── compose.yaml
├── compose.secrets.yaml              # optional overlay for DB/API password
├── hints.md
├── instructor-notes.md
├── validate.sh
├── validate.ps1
├── db/
│   └── init.sql
├── api/
│   ├── go.mod
│   ├── main.go
│   ├── Dockerfile.distroless
│   └── .dockerignore
└── secrets/
    ├── db_password.txt.example
    └── db_password.txt               # you create this (DO NOT COMMIT)
```

---

## Step 0 — Create local-only files (required)

### 0a) Config file (.env)
```bash
cp .env.example .env
```

### 0b) Secret file (for DB/API password)
Use a unique value so it can’t match normal log output:

```bash
cp secrets/db_password.txt.example secrets/db_password.txt
```

Edit `secrets/db_password.txt` and set a single-line value (>= 12 chars).

---

## Step 1 — Start the platform
Run with the secrets overlay:

```bash
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build
docker compose ps
```

Verify endpoints:

```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes
curl -s http://localhost:8080/metrics | head
```

Expected:
- `/healthz` returns `ok`
- `/readyz` returns `ready`
- `/metrics` returns text metrics

---

## Step 2 — Generate traffic and observe
Make some requests:

```bash
curl -s http://localhost:8080/notes > /dev/null
curl -s -X POST http://localhost:8080/notes -H 'content-type: application/json' -d '{"message":"hello"}' > /dev/null
curl -s http://localhost:8080/notes > /dev/null
```

Now observe:

### Logs
```bash
docker compose logs api --tail 80
```

Expected:
- structured logs (JSON)
- fields like: `level`, `event`, `path`, `method`, `status`, `duration_ms`

### Metrics
```bash
curl -s http://localhost:8080/metrics | egrep 'http_requests_total|http_request_duration_ms_(count|sum)'
```

Expected:
- request counters increment
- latency metrics exist

---

## Step 3 — Simulate a failure (DB outage) and diagnose with evidence

Stop the DB container:

```bash
docker compose stop db
```

Now hit the API:

```bash
curl -i http://localhost:8080/readyz
curl -i http://localhost:8080/notes
```

Expected:
- `/readyz` becomes `503`
- `/notes` becomes `503`
- logs contain an error event explaining DB not ready
- metrics include increased error counts

Check logs + metrics:

```bash
docker compose logs api --tail 120
curl -s http://localhost:8080/metrics | egrep 'db_ping_failures_total|http_requests_total'
```

Bring DB back:

```bash
docker compose start db
```

Wait for readiness:

```bash
for i in $(seq 1 30); do curl -fsS http://localhost:8080/readyz && break || true; sleep 2; done
```

---

## Step 4 — Deliverable: OBSERVABILITY_NOTES.md (required)
Create it from the template:

```bash
cp OBSERVABILITY_NOTES_TEMPLATE.md OBSERVABILITY_NOTES.md
```

Fill it in with short, direct answers.

---

## Cleanup (STRICT)
```bash
docker compose -f compose.yaml -f compose.secrets.yaml down
```

Optional destructive cleanup:
```bash
docker compose -f compose.yaml -f compose.secrets.yaml down -v
```

---

## Validation
From repo root:
- bash: `./scripts/validate/validate.sh lab-15`
- PowerShell: `\scripts\validate\validate.ps1 lab-15`
