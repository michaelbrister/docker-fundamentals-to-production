# Lab 14 — Hints

## The API fails immediately
That is expected when secrets are missing.
Check logs:
```bash
docker compose logs api --tail 80
```

## Secrets should be runtime-only
- Don't put passwords in Dockerfiles
- Don't put passwords in `.env`
- Prefer Compose `secrets:`

## DB schema missing
If you re-used a volume and init didn't run:
```bash
docker compose down -v
docker compose up -d --build
```

## You want to "exec sh"
Remember: distroless has no shell. Use logs and endpoints.
