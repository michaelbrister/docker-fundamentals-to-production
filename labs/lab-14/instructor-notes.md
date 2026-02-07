# Lab 14 — Instructor Notes
**Topic:** Secrets vs configuration in a containerized platform

## Teaching intent
This lab prevents the most common beginner mistake:
- baking secrets into images
- committing secrets in `.env`

Learners must internalize:
- images are build-time artifacts
- secrets are runtime concerns

## Enforce strictly
- Base compose must fail without secrets
- Secrets must be injected via Compose `secrets:` overlay
- `.env` contains non-secret config only
- `SECRETS_NOTES.md` is required
- No secret values in logs

## Common traps
- putting DB password in `.env`
- hardcoding in code
- adding `ENV DB_PASSWORD=...` in Dockerfile
- committing `secrets/db_password.txt`

## Timing
- 60–75 minutes
- Most time is spent on the mindset shift, not typing.
