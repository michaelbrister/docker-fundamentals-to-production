# Lab 16 — Hints

## Dev vs Prod mental model
- **Dev**: you may use `build:` so you can iterate.
- **Prod**: you must run from **versioned images** (no build context).

## “/readyz is stuck 503”
Most common causes:
- DB isn't healthy yet
- DB password changed but volume still has old credentials → `down -v`

## Proving “prod mode uses images”
Inspect the container image:

```bash
docker inspect -f '{{.Config.Image}}' lab16-api
```

It must match the tag in `.env`.

## Runtime hardening checks
Your API container should be:
- non-root
- read-only rootfs
- `no-new-privileges`
- all capabilities dropped

## Don’t leak secrets
Never log the password value. Only log “[REDACTED]”.
