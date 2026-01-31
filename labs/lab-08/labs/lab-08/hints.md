# Lab 08 — Hints

- If `/readyz` never becomes ready, check DB_HOST (must be `db`)
- If schema missing, ensure `init.sql` ran (volume must be empty first)
- Check logs with `docker compose logs api`
