# Scenario 1 — Env mismatch (DB auth)

## Intentional break
The API uses the wrong DB password.

## What success looks like
- `/healthz` ok
- `/readyz` becomes ready after you fix config
- `GET /notes` works

## Hints
- Start here: `docker compose ps`
- Then: `docker compose logs api --tail 80`
- Fix should be in configuration, not code.
