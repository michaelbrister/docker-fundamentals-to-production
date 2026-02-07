# Lab 16 — Instructor Notes

## Intent
Lab 16 is the capstone workflow lab:
- ship a versioned image
- run “prod mode” from images
- enforce quality gates
- demonstrate operational maturity with a short runbook + incident report

## What to watch for
- Students trying to keep `build:` in prod mode
- Not understanding `.env` versioning and tags
- Treating “up” as “healthy” (must check readiness + metrics)
- Forgetting to clean up

## Evidence-based incident drill
During DB outage:
- readiness flips 503
- error metrics increment
- logs show a clear DB-not-ready event

## Strictness
Fail students if:
- `RUNBOOK.md` or `INCIDENT.md` missing/empty
- secret appears in logs
- prod mode uses build context
- runtime hardening not present in prod
