# Lab 12 — Security Hardening: Distroless + Least Privilege

## Goal
By the end of this lab you will be able to:
- Run the API using a **distroless** runtime image (no shell)
- Enforce **non-root** execution
- Reduce container attack surface by removing unnecessary OS tooling
- Use **logs + health/readiness** to debug (not `exec sh`)
- Apply basic runtime hardening settings in Compose:
  - `read_only`
  - `tmpfs`
  - `cap_drop`
  - `no-new-privileges`
- Produce a short `HARDENING_NOTES.md` describing what changed and how you verified it

> **Strict mode:** Cleanup must be done with `docker compose down`.

---

## Prerequisites
- Labs 01–11 completed (especially Labs 09–11)
- You understand the difference between **build** and **run**
- You can debug with `docker compose ps` and `docker compose logs`

---

## Concepts (10 minutes)

### Distroless means “no shell”
A distroless image typically does **not** contain:
- `/bin/sh`
- package managers
- common Linux utilities

If you try:
```bash
docker exec -it <container> sh
```
…it will fail.

That is the point.

### Production debugging uses observability
In production you rely on:
- logs
- health endpoints
- readiness endpoints
- metrics/traces (later)

Not interactive shell sessions.

---

## Lab structure
```text
lab-12/
├── README.md
├── compose.yaml                # baseline (Alpine runtime)
├── compose.distroless.yaml     # hardened runtime (distroless + restrictions)
├── HARDENING_NOTES.md          # you create this
├── HARDENING_TEMPLATE.md
├── hints.md
├── instructor-notes.md
├── validate.sh
├── validate.ps1
├── db/
│   └── init.sql
└── api/
    ├── go.mod
    ├── main.go
    ├── Dockerfile              # alpine runtime (baseline)
    ├── Dockerfile.distroless   # distroless static runtime (hardened)
    └── .dockerignore
```

---

## Step 1 — Baseline run (Alpine runtime)

From `labs/lab-12/`:

```bash
docker compose -f compose.yaml up -d --build
docker compose ps
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
```

✅ Expected:
- healthz = ok
- readyz = ready
- you can `exec sh` (baseline only)

Bring it down:
```bash
docker compose -f compose.yaml down
```

---

## Step 2 — Hardened run (Distroless static)

Start the hardened stack:

```bash
docker compose -f compose.distroless.yaml up -d --build
docker compose ps
```

Verify endpoints:
```bash
curl -s http://localhost:8080/healthz
curl -s http://localhost:8080/readyz
curl -s http://localhost:8080/notes
```

✅ Expected:
- healthz = ok
- readyz = ready
- notes returns JSON

Now prove there is no shell:
```bash
docker exec -it lab12-api sh
```
✅ Expected:
- command fails (no shell)

---

## Step 3 — Verify write restrictions

The hardened compose config uses:
- `read_only: true`
- `tmpfs: /tmp`

The app should still run because it does not write to the root filesystem.

---

## Step 4 — Produce HARDENING_NOTES.md (required)

Copy the template and fill it in:
```bash
cp HARDENING_TEMPLATE.md HARDENING_NOTES.md
```

Document:
- what you changed
- what broke (if anything)
- how you verified behavior without shell access
- what you’d do in production (logs, metrics)

---

## Cleanup (STRICT)
```bash
docker compose -f compose.distroless.yaml down
```

Optional destructive cleanup:
```bash
docker compose -f compose.distroless.yaml down -v
```

---

## Validation
From repo root:
- bash: `./scripts/validate/validate.sh lab-12`
- PowerShell: `.\scriptsalidatealidate.ps1 lab-12`

Validation checks:
- No lab-12 containers remain
- `HARDENING_NOTES.md` exists and contains required headings

---

## Quick quiz
1) Why is “no shell” a security improvement?
2) If you can’t exec into the container, how do you debug?
3) Why does `read_only` reduce risk?
4) What does `no-new-privileges` do at a high level?
