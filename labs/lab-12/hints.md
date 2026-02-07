# Lab 12 — Hints

## Distroless surprise: exec fails
Expected. Use:
- `docker compose ps`
- `docker compose logs api --tail 100`
- `/healthz` and `/readyz`

## API not ready
- Check DB health: `docker compose ps`
- Check logs: `docker compose logs api --tail 100`
- Ensure init.sql ran (volume may already exist):
  - Destructive reset: `docker compose down -v`

## Build fails pulling distroless
You need access to pull `gcr.io/distroless/...` images.
Capture the error and proceed with baseline while troubleshooting.
