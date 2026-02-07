# Lab 11 — Solution guidance (instructor reference)

This lab is intentionally scenario-based. Do not hand learners this file up front.

## Scenario 1 — Env mismatch
- Fix env so API and DB credentials match (DB_PASSWORD must match POSTGRES_PASSWORD)
- Recreate API or whole stack as needed

## Scenario 2 — Localhost regression
- Set DB_HOST=db

## Scenario 3 — Schema missing
- Ensure init.sql is mounted into docker-entrypoint-initdb.d
- If volume already contains an empty DB without schema, use `docker compose down -v` then `up`

## Scenario 4 — Override leak
- Run with explicit compose file list:
  - `docker compose -f compose.yaml up -d --build`
- Or remove/rename override for prod-like run
