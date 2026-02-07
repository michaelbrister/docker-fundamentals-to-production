# Lab 19 — Promotion & Provenance (Build Once → Promote Many)

## Goal
Learn the core production release rule:

> **Build once → promote the same artifact → never rebuild between environments.**

In this lab you will:
- build a **release candidate** image once in **dev**
- capture the immutable **image digest/ID** as provenance evidence
- “promote” that *same* artifact to **prod-like** by reference (no rebuild)
- prove the running prod container matches the promoted artifact

Host ports:
- Dev: **8084**
- Prod-like: **8085**

---

## Required learner artifacts (strict)
You must create these files (validators will fail if missing):

```bash
cp .env.example .env
cp secrets/db_password.txt.example secrets/db_password.txt
cp PROMOTION_TEMPLATE.md PROMOTION.md
cp PROVENANCE_TEMPLATE.md PROVENANCE.md
```

- Edit `secrets/db_password.txt` to a unique value (>= 12 chars)
- Fill out `PROMOTION.md` and `PROVENANCE.md` (remove REPLACE_ME placeholders)

---

## Structure
```text
lab-19/
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
├── PROMOTION_TEMPLATE.md
├── PROMOTION.md                 # you create
├── PROVENANCE_TEMPLATE.md
├── PROVENANCE.md                # you create
├── db/
│   └── init.sql
├── api/
│   ├── go.mod
│   ├── main.go
│   ├── Dockerfile.distroless
│   └── .dockerignore
└── secrets/
    ├── db_password.txt.example
    └── db_password.txt          # you create (DO NOT COMMIT)
```

---

## Step 0 — Create required files
From `labs/lab-19/`:

```bash
cp .env.example .env
cp secrets/db_password.txt.example secrets/db_password.txt
cp PROMOTION_TEMPLATE.md PROMOTION.md
cp PROVENANCE_TEMPLATE.md PROVENANCE.md
```

---

## Step 1 — Build the release candidate (DEV build)
This is the **only** time you build in this lab.

```bash
source .env
docker compose -f compose.yaml -f compose.dev.yaml build
```

The build tags the image as:
- `dzth/mini-platform-api:${RC_VERSION}`

Capture the immutable image identifier (used as provenance evidence):

```bash
source .env
docker image inspect dzth/mini-platform-api:${RC_VERSION} --format '{{.Id}}'
```

Copy that `sha256:...` value into:
- `.env` as `PROMOTED_IMAGE_REF=sha256:...`
- `PROVENANCE.md`

⚠️ Why `.Id` and not `RepoDigests`?
Local images usually do not have `RepoDigests` unless pushed to a registry.
The local image **ID** is still an immutable content digest and works for this lab.

---

## Step 2 — Deploy DEV using the RC tag
```bash
source .env
docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml up -d
curl -i http://localhost:8084/readyz
curl -s http://localhost:8084/version
```

Expected:
- `/readyz` returns **200**
- `/version` reports your `RC_VERSION`

---

## Step 3 — Promote to PROD-like (NO REBUILD)
Promotion means: prod runs the **same artifact** you built in dev.

```bash
# stop dev
docker compose -f compose.yaml -f compose.dev.yaml -f compose.secrets.yaml down

# start prod-like using the immutable image ref (sha256:...)
source .env
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d
curl -i http://localhost:8085/readyz
curl -s http://localhost:8085/version
```

Expected:
- `/readyz` returns **200**
- `/version` still reports the same `RC_VERSION`

---

## Step 4 — Prove provenance (required)
Your `PROVENANCE.md` must include:
- RC tag: `dzth/mini-platform-api:${RC_VERSION}`
- promoted image ref: `sha256:...`
- evidence command output (image inspect)
- confirmation that prod is running the promoted ref

Your `PROMOTION.md` must explain:
- what “build once, promote many” means
- why rebuilds in prod break provenance
- how you would implement this in CI (high level)

---

## Cleanup
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down
```

If you changed DB password and got stuck:
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down -v
```

---

## Validation
From repo root:
```bash
./scripts/validate/validate.sh lab-19
```
Windows:
```powershell
.\scripts\validate\validate.ps1 lab-19
```
