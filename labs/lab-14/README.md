# Lab 14 — Secrets & Configuration (Reuse the mini-platform)

## Goal
This lab teaches you to pass **configuration** and **secrets** into containers safely **without**:
- baking secrets into images
- committing secrets into git
- rebuilding images just to change configuration

By the end you will be able to:
- explain **config vs secrets**
- use `.env.example` for non-secret config
- use Docker Compose `secrets:` for sensitive values
- run the **same image** in different environments without rebuilding
- prove secrets are **not leaked** in logs or images

> **Strict mode:** cleanup must be done with `docker compose down`.

---

## Prerequisites
- Labs 08–13 completed (mini-platform, debugging, hardening, CI)
- Docker + Docker Compose installed and working

---

## Mental model (read this)
- **Configuration**: safe to share (log level, environment name, feature flags)
- **Secrets**: sensitive (passwords, API keys). Treat as **runtime-only**.

If your image contains secrets, you have already lost.

---

## Lab structure
```text
lab-14/
├── README.md
├── .env.example
├── SECRETS_NOTES_TEMPLATE.md
├── SECRETS_NOTES.md              # you create this
├── compose.yaml                  # base topology (no secrets)
├── compose.secrets.yaml          # secrets overlay (compose secrets)
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
    └── db_password.txt           # you create this (DO NOT COMMIT)
```

---

## Step 0 — Create your local-only secret file (DO NOT COMMIT)

Create the real secret file:

```bash
cp secrets/db_password.txt.example secrets/db_password.txt
```

Edit `secrets/db_password.txt` and set a password value (single line).

✅ Rules:
- the secret file must exist locally
- the secret file must **not** be committed to git

---

## Step 1 — Create your local config file

Create a local `.env` from the example:

```bash
cp .env.example .env
```

✅ Rules:
- `.env` is for **non-secret config only**
- `.env` must **not** be committed to git
- do not put passwords or API keys in `.env`

---

## Step 2 — Prove the base compose fails without secrets

Run the base compose file (no secrets overlay):

```bash
docker compose -f compose.yaml up -d --build
docker compose logs api --tail 50
```

✅ Expected:
- API exits with an error like “missing required settings: DB_PASSWORD (or DB_PASSWORD_FILE)”

Cleanup:
```bash
docker compose -f compose.yaml down
```

This is good. It proves secrets are required and not defaulted.

---

## Step 3 — Run with secrets overlay (the correct way)

Start the system with secrets:

```bash
docker compose -f compose.yaml -f compose.secrets.yaml up -d --build
docker compose ps
```

Verify endpoints:

```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes
```

✅ Expected:
- `healthz` = ok
- `readyz` = ready
- `/notes` returns JSON

---

## Step 4 — Change config WITHOUT rebuilding

Change `LOG_LEVEL` in `.env` (e.g., `debug` → `info`) and restart:

```bash
docker compose -f compose.yaml -f compose.secrets.yaml up -d
docker compose logs api --tail 50
```

✅ Expected:
- behavior changes (config log lines reflect the new level)
- you did **not** rebuild the image to change config

---

## Step 5 — Prove secrets are NOT leaked
1) Check logs: your DB password must not appear in `docker compose logs api`.
2) Check Dockerfile: it must not contain secret values or secret env defaults.

---

## Deliverable — SECRETS_NOTES.md (required)
Create `SECRETS_NOTES.md` from the template:

```bash
cp SECRETS_NOTES_TEMPLATE.md SECRETS_NOTES.md
```

Fill it in with short answers.

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
- bash: `./scripts/validate/validate.sh lab-14`
- PowerShell: `\scripts\validate\validate.ps1 lab-14`
