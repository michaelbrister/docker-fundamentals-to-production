# Lab 08 — Application + Database: Wiring a System Together (Compose)

## Goal
By the end of this lab you will be able to:
- Run an **application + database** together as a single Compose “system”
- Configure connectivity using **environment variables** (no hardcoding)
- Understand why `localhost` is almost always wrong inside containers
- Use **readiness** checks to distinguish “running” vs “usable”
- Verify the app detects missing DB schema and reports it clearly
- Prove persistence: restart the app, keep the data
- Tear down cleanly using `docker compose down`

> **Strict mode:** bring the stack down with `docker compose down`.  
> Stopping containers manually is considered failed cleanup.

---

## Prerequisites
- Labs 01–07 completed
- Docker installed and running
- You can run Compose and interpret `docker compose ps`
- Basic understanding of volumes and service-name networking

---

## Concepts you need (5–10 minutes)

### Apps are not standalone
Real services depend on other services:
- databases
- caches
- queues

This lab teaches how to wire those dependencies correctly.

---

### `localhost` means “this container”
Inside a container:
- `localhost` refers to the container itself
- it does **not** refer to your host
- it does **not** refer to another container

In Compose, services talk to each other by **service name** (DNS).

---

### Health vs readiness
- **Health (running):** process is up
- **Readiness (usable):** dependencies are available and working

This lab introduces both on purpose:
- `/healthz` checks the API process
- `/readyz` checks DB connectivity and schema

---

## Lab topology (what you will run)

This lab runs a small “system”:
- `db` (Postgres) — stateful, persistent volume
- `adminer` — optional UI to observe DB state
- `api` (notes-api) — stateless application that reads/writes notes

Data persists because **the database uses a volume**.

---

## Files for this lab

This folder already contains everything you need:
- `compose.yaml`
- `db/init.sql`
- `api/go.mod`
- `api/main.go`
- support files (hints/solutions/instructor notes/validators)

---

## Tasks

### Task 0 — Start the system
From `labs/lab-08/`:

**bash / zsh**
```bash
docker compose up -d
docker compose ps
```

**PowerShell**
```powershell
docker compose up -d
docker compose ps
```

✅ Expected:
- `db` becomes healthy
- `api` is running
- You can see ports 8080 (api) and 8082 (Adminer)

Do not proceed until `db` is healthy.

---

### Task 1 — Confirm `/healthz` vs `/readyz`
**bash / zsh**
```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
```

**PowerShell**
```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8080/healthz | Select-Object -Expand Content
Invoke-WebRequest -UseBasicParsing http://localhost:8080/readyz | Select-Object -Expand Content
```

✅ Expected:
- `/healthz` returns `ok`
- `/readyz` becomes `ready` after startup (may be not-ready briefly)

---

### Task 2 — Read notes
```bash
curl -s http://localhost:8080/notes
```

✅ Expected:
- JSON array includes `hello from lab-08`

---

### Task 3 — Write a note
```bash
curl -s -X POST http://localhost:8080/notes   -H "Content-Type: application/json"   -d '{"message":"note created via api"}'
```

✅ Expected:
- HTTP 201 and JSON with an `id`

---

### Task 4 — Restart only the API and confirm data remains
```bash
docker compose restart api
curl -s http://localhost:8080/notes
```

✅ Expected:
- Your note still exists
- Restarting the app is boring

---

### Task 5 — Intentionally break it: set DB_HOST=localhost
1) Edit `compose.yaml` and set `DB_HOST: "localhost"` for the api service.
2) Restart only the API:
```bash
docker compose up -d --no-deps api
curl -s http://localhost:8080/readyz
```

✅ Expected:
- `not ready: db ping failed` (or similar)

3) Fix DB_HOST back to `db`, restart api again, and confirm readiness returns.

📌 Lesson:
- `localhost` inside a container refers to that container, not the database.

---

### Task 6 — Optional: use Adminer
Visit:
- `http://localhost:8082`

Login:
- System: PostgreSQL
- Server: `db`
- Username: `app`
- Password: `app`
- Database: `appdb`

---

## Cleanup (STRICT)
```bash
docker compose down
docker compose ps
```

Optional destructive cleanup:
```bash
docker compose down -v
```

---

## Validation (recommended)
From repo root:
- bash: `./scripts/validate/validate.sh lab-08`
- PowerShell: `.\scriptsalidatealidate.ps1 lab-08`
