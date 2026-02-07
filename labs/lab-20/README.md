# Lab 20 — Incident Day (Final Exam) — 2 Break Modes

This lab is a **no-hints incident simulation**.

You will be given a broken “prod-like” deployment of the mini-platform. Your job is to:
- **detect** what’s wrong using evidence
- **recover** safely (no rebuilds)
- **document** what happened (incident + timeline + recovery)

Host port: **8086**

---

## Rules (strict)
- **NO rebuilds** after the incident begins.
- Fix via **configuration and promotion discipline** (env values / image ref), not new code.
- You must produce the required incident artifacts (validators fail if missing/placeholder).

---

## Required learner artifacts (strict)
Create these files (validators will fail if missing):

```bash
cp .env.example .env
cp secrets/db_password.txt.example secrets/db_password.txt
cp INCIDENT_TEMPLATE.md INCIDENT.md
cp TIMELINE_TEMPLATE.md TIMELINE.md
cp RECOVERY_TEMPLATE.md RECOVERY.md
```

Then:
- Set `secrets/db_password.txt` to a unique value (**>= 12 chars**) (DO NOT COMMIT)
- Fill out the 3 markdown artifacts (remove `REPLACE_ME` placeholders)

---

## Step 0 — Build the known-good artifact (allowed ONCE, before the incident)
This is the only build you should do in this lab.

```bash
source .env
docker build -f api/Dockerfile.distroless -t dzth/mini-platform-api:${RC_VERSION} api
``

Capture the immutable image ID (this is your “known-good artifact reference”):

```bash
source .env
docker image inspect dzth/mini-platform-api:${RC_VERSION} --format '{{.Id}}'
```

Paste that value into `.env` as:
- `KNOWN_GOOD_IMAGE_REF=sha256:...`
- `PROMOTED_IMAGE_REF=sha256:...`

Verify `.env` no longer contains `REPLACE_ME`.

---

## Step 1 — Start the incident (choose a break mode)
Two break modes are provided. Pick one:

- **Mode A**: Misconfiguration (DB_HOST wrong)
- **Mode B**: Bad promotion (PROMOTED_IMAGE_REF wrong)

Run one of the reset scripts **from `labs/lab-20/`**:

### macOS / Linux
```bash
./reset.sh mode-a
# or
./reset.sh mode-b
```

### Windows PowerShell
```powershell
.\reset.ps1 mode-a
# or
.\reset.ps1 mode-b
```

This writes:
- `break-mode.txt` (which mode is active)
- modifies `.env` to introduce the failure

You should now be “on call.”

---

## Step 2 — Triage (no hints)
Bring up the prod-like stack and diagnose using evidence.

```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml up -d
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml ps
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml logs --tail 200 api
curl -i http://localhost:8086/readyz
```

No hints are provided beyond what you can observe.

---

## Step 3 — Recover safely (no rebuilds)
Fix the issue without rebuilding.

**Constraints:**
- you may edit `.env`
- you may restart services
- you may tear down and bring back up
- you may NOT rebuild images

Evidence to confirm recovery:
```bash
curl -i http://localhost:8086/readyz
curl -i http://localhost:8086/notes
curl -s http://localhost:8086/version
```

**Expected when recovered:**
- `/readyz` returns **200**
- `/notes` returns **200**
- `/version` reports your `RC_VERSION`

---

## Step 4 — Document the incident (required)
You must fill:
- `INCIDENT.md`
- `TIMELINE.md`
- `RECOVERY.md`

These should be written as if you were reporting to your team lead.

---

## Cleanup
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down
```

If you get stuck and need a full reset (clears volume):
```bash
docker compose -f compose.yaml -f compose.prod.yaml -f compose.secrets.yaml down -v
```

---

## Validation
From repo root:
```bash
./scripts/validate/validate.sh lab-20
```
Windows:
```powershell
.\scripts\validate\validate.ps1 lab-20
```
