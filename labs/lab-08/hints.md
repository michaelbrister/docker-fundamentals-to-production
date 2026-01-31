# Lab 08 — Hints

Use these only if you’re stuck. Read errors carefully before acting.

---

## API never becomes ready
- Check API logs:
  - `docker compose logs api --tail 100`
- Check DB is healthy:
  - `docker compose ps`
  - `docker compose logs db --tail 100`

---

## “schema missing” message
- This is expected if init.sql never ran.
- Init scripts run only when the data directory is empty.
- To force rerun (destructive):
  - `docker compose down -v` then `docker compose up -d`

---

## You used DB_HOST=localhost and it broke
- Good — that’s the lesson.
- Inside a container, `localhost` means the API container.
- Fix by setting `DB_HOST=db` and restarting API:
  - `docker compose up -d --no-deps api`

---

## Ports in use
- Change host ports (left side) in compose.yaml:
  - API: 8080
  - Adminer: 8082
  - Postgres: 5433
