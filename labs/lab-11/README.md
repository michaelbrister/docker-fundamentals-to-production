# Lab 11 — Debugging & Break/Fix: Operating a Containerized System

## Goal

This lab teaches you to debug **systems**, not individual containers.

By the end of this lab you will be able to:

- Diagnose failures using evidence (`ps`, `logs`, health, readiness)
- Classify failures: config vs networking vs state vs environment shape
- Fix issues methodically (no random commands)
- Write a short runbook documenting symptoms → root cause → fix → prevention

> **Strict mode:** You must clean up with `docker compose down`.  
> You must produce `RUNBOOK.md` in this lab folder.

---

## Prerequisites

- Labs 01–10 completed (especially 08–10)
- Docker installed and running
- Comfort with `docker compose ps` and `docker compose logs`

---

## Rules of engagement (enforced in spirit)

1. **Observe first.** Do not edit files until you can describe the symptom.
2. **One change at a time.** Apply one fix, retest.
3. **Prove it.** Use `/healthz` and `/readyz` and a DB query to confirm.
4. **Document.** Every scenario requires runbook notes.

---

## Scenarios

You will complete 4 independent scenarios. Each scenario lives in its own folder.

Run scenarios from their folder, e.g.:

```bash
cd scenarios/scenario-01
docker compose up -d --build
docker compose ps
docker compose logs -f --tail 50 api
```

### What “done” means per scenario

- The stack starts
- `/healthz` is OK
- `/readyz` becomes ready
- `GET /notes` works and returns JSON
- You can insert a note and read it back
- You bring it down with `docker compose down`

---

## Deliverable: RUNBOOK.md (required)

Create `RUNBOOK.md` in `labs/lab-11/` with sections:

- Scenario 1
- Scenario 2
- Scenario 3
- Scenario 4

For each:

- Symptoms observed
- Commands run (and why)
- Root cause
- Fix applied
- Prevention note

A template exists at `RUNBOOK_TEMPLATE.md`.

---

## Validation

From repo root:

- bash: `./scripts/validate/validate.sh lab-11`
- PowerShell: `.\scripts/validatealidate.ps1 lab-11`

Validation checks:

- No lab-11 scenario containers exist
- RUNBOOK.md exists and includes all scenario headings

---

## Quick quiz (answer from memory)

1. Why is “Up” not the same as “Ready”?
2. What’s your first command when a system won’t start?
3. Name 3 categories of failure in containerized systems.
4. Why is “one change at a time” important in debugging?
