# Lab 11 — Hints

Use hints only after you have:
- checked `docker compose ps`
- checked `docker compose logs`

General debugging loop:
1) `docker compose ps`
2) `docker compose logs <service> --tail 80`
3) Check `/healthz` and `/readyz`
4) Fix one thing, retest

Common commands:
- `docker compose logs api --tail 100`
- `docker compose logs db --tail 100`
- `docker compose exec db psql -U app -d appdb -c "select * from notes;"`
