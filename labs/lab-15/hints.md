# Lab 15 — Hints

## “I don’t see JSON logs”
Your logger must write to stdout/stderr. In containers, file logs are the wrong default.

Use:
```bash
docker compose logs api --tail 80
```

## Metrics basics
Your `/metrics` output should include:
- a request counter (by method/path/status)
- a duration metric (count + sum is fine)
- an error counter

## Readiness stuck at 503
- Confirm DB is healthy:
```bash
docker compose ps
docker compose logs db --tail 80
```
- If you changed the DB password, you may need to reset the volume:
```bash
docker compose down -v
docker compose up -d --build
```

## Don’t leak secrets
Never log environment variable values for passwords.
Log “loaded” and redact the value.
