# Lab 07 — Hints

Use these only if you’re stuck. Read errors carefully before acting.

---

## Database never becomes healthy
- Check logs:
  - `docker compose logs db --tail 50`
- First initialization can take longer than restarts

---

## Init script didn’t run
- This is expected behavior
- Init scripts run only when the data directory is empty
- To force re-run (destructive):
  - `docker compose down -v`

---

## Can’t connect from Adminer
- Ensure server is `db`, not `localhost`
- Verify db is healthy before accessing Adminer

---

## Data disappeared
- You likely removed the volume
- Check:
  - `docker volume ls`
