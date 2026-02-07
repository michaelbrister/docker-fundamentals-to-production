# Lab 16 — Capstone: Release Candidate Mini-Platform (Compose “prod mode”)

## Goal
Turn the existing mini-platform into a **release candidate** that can be:

- Run in **dev mode** (build from source)
- Run in **prod-like mode** (run from **versioned images**, hardened runtime)
- Validated locally and in CI with **quality gates**
- Operated with **evidence** (logs + metrics + health signals)
- Supported by a minimal **runbook** and **incident report**

This lab is about **shipping + operating**, not adding random services.

---

## What you will deliver (strict)
You must create these learner artifacts:

- `INCIDENT.md` (from template)
- `RUNBOOK.md` (from template)
- `.env` (from `.env.example`)
- `secrets/db_password.txt` (from example)

Validators will fail if these are missing.

---

## Lab structure
```text
lab-16/
├── README.md
├── .env.example
├── compose.yaml
├── compose.dev.yaml
├── compose.prod.yaml
├── compose.secrets.yaml
├── hints.md
├── instructor-notes.md
├── validate.sh
├── validate.ps1
├── RELEASE.md
├── RUNBOOK_TEMPLATE.md
├── RUNBOOK.md                 # you create this
├── INCIDENT_TEMPLATE.md
├── INCIDENT.md                # you create this
├── db/
│   └── init.sql
├── api/
│   ├── go.mod
│   ├── main.go
│   ├── Dockerfile.distroless
│   └── .dockerignore
└── secrets/
    ├── db_password.txt.example
    └── db_password.txt         # you create this (DO NOT COMMIT)
```

---

## Step 0 — Create local-only files (required)

### 0a) Config file (.env)
```bash
cp .env.example .env
```

### 0b) Secret file (DB password)
```bash
cp secrets/db_password.txt.example secrets/db_password.txt
```

Edit `secrets/db_password.txt` and set a single-line value (>= 12 chars).

### 0c) Runbook + incident report
```bash
cp RUNBOOK_TEMPLATE.md RUNBOOK.md
cp INCIDENT_TEMPLATE.md INCIDENT.md
```

Fill both in (short + direct is fine).

---

## Step 1 — Dev mode (build from source)
Dev mode is for iteration and learning.

```bash
docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml up -d --build
docker compose ps
```

Hit endpoints (dev uses host port **8082**):

```bash
curl -s http://localhost:8082/healthz
curl -s http://localhost:8082/readyz
curl -s http://localhost:8082/notes
curl -s http://localhost:8082/metrics | head
curl -s http://localhost:8082/version
```

Cleanup:
```bash
docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml down
```

---

## Step 2 — Prod-like mode (run from versioned images)
Prod mode must run from an **image tag**, not build context.

### 2a) Build and tag the release image
Set `RELEASE_VERSION` in `.env` (example: `0.3.0-rc.1`).

```bash
source .env
docker build -f api/Dockerfile.distroless -t dzth/mini-platform-api:${RELEASE_VERSION} api
```

### 2b) Run prod-like stack (no build)
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d
docker compose ps
```

Validate endpoints (prod uses host port **8082** too for consistency):

```bash
curl -s http://localhost:8082/readyz
curl -s http://localhost:8082/metrics | egrep 'http_requests_total|http_errors_total|db_ping_failures_total'
curl -s http://localhost:8082/version
```

Cleanup:
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down
```

---

## Step 3 — Incident drill (required)
Use the runbook to diagnose a DB outage using evidence (no guessing).

```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml stop db
curl -i http://localhost:8082/readyz
curl -i http://localhost:8082/notes
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs api --tail 120
curl -s http://localhost:8082/metrics | egrep 'http_errors_total|db_ping_failures_total'
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml start db
```

Write the outcome into `INCIDENT.md`.

---

## Validation
From repo root:
- bash: `./scripts/validate/validate.sh lab-16`
- PowerShell: `\scripts\validate\validate.ps1 lab-16`

---

## Cleanup (STRICT)
Always end the lab with:

```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down
```

If you changed DB password and got stuck, wipe the volume:

```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down -v
```
