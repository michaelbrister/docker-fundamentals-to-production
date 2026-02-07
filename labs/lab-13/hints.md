# Lab 13 — Hints

## CI didn’t run
- Confirm Actions are enabled in the repo settings.
- Confirm workflow file exists at `.github/workflows/ci.yml` on the branch you pushed.
- Confirm your PR targets the correct default branch.

## Policy job failed
Read the job output. The failure message should say what rule you violated:
- `:latest` disallowed
- root user disallowed / missing USER

## Trivy scan failed
This lab fails on **CRITICAL** only.
Fix options:
- update/pin base image tags
- rebuild and re-run
If a CRITICAL has no practical fix, document it in `SECURITY_EXCEPTIONS.md`.

## Smoke test failed
Common causes:
- wrong compose path
- services not becoming ready in time
- ports collide (rare on runners)

Check the logs from:
- `docker compose logs api`
- `docker compose logs db`
