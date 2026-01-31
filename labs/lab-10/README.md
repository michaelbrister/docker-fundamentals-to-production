# Lab 10 — Dev vs Prod: Compose Overrides and Env Files

## Goal
By the end of this lab you will be able to:
- Run the **same system** in dev and prod-like modes
- Understand how **Compose layering** works (`compose.yaml` + `compose.override.yaml`)
- Use **env files** to inject configuration
- Know when bind mounts are appropriate (dev) and when they are not (prod-like)
- Switch environments **without editing code**

> **Strict mode:** Cleanup must be done with `docker compose down`.

---

## Prerequisites
- Labs 01–09 completed
- You can build and run the Lab 09 system
- Basic familiarity with env vars

---

## Concepts (5–10 minutes)

### Compose layering
Compose automatically applies `compose.override.yaml` when present.
- Base file = shared truth
- Override = environment-specific behavior (dev)

### Environments are overlays
You do **not** fork compose files per environment.
You layer configuration on top of a stable base.

### Env files
Configuration lives outside compose files.
Compose loads variables from:
- `.env`
- files passed via `--env-file`

---

## Files in this lab
```text
lab-10/
├── README.md
├── compose.yaml
├── compose.override.yaml
├── env/
│   ├── dev.env
│   └── prod.env
├── db/
│   └── init.sql
├── api/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── go.mod
│   └── main.go
├── hints.md
├── instructor-notes.md
├── validate.sh
├── validate.ps1
└── solutions/
    └── solution.md
```

---

## Step 1 — Base compose (shared)

`compose.yaml` defines the **prod-like** shape:
- built images only
- no bind mounts
- minimal config

---

## Step 2 — Dev override

`compose.override.yaml`:
- adds bind mounts
- enables faster iteration
- automatically applied locally

---

## Step 3 — Env files

- `env/dev.env` → dev config
- `env/prod.env` → prod-like config

No secrets in compose files.

---

## Tasks

### Task 0 — Dev mode (default)
```bash
docker compose --env-file env/dev.env up -d --build
docker compose ps
```

Change code in `api/main.go`, rebuild only API:
```bash
docker compose build api
docker compose up -d --no-deps api
```

✅ Expected:
- Changes visible after rebuild
- Bind mounts present (dev convenience)

---

### Task 1 — Prod-like mode
```bash
docker compose --env-file env/prod.env -f compose.yaml up -d --build
docker compose ps
```

Change code **without rebuilding**.

✅ Expected:
- No change visible
- Confirms prod-like behavior

---

## Cleanup (STRICT)
```bash
docker compose down
```

---

## Validation
```bash
./scripts/validate/validate.sh lab-10
# or
.\scripts\validate\validate.ps1 lab-10
```

---

## Quick quiz
1) Why does dev allow bind mounts but prod-like does not?
2) Why are env files preferred over hardcoding values?
3) What file does Compose auto-load locally?
