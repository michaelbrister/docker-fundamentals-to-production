# Lab 09 — Hints

## Compose build fails
- Build errors appear during `docker compose build`
- Try rebuilding the API only:
  - `docker compose build api`
- If you're truly stuck, try:
  - `docker compose build --no-cache api` (last resort)

## API doesn't become ready
- Check logs:
  - `docker compose logs api --tail 100`
- Confirm DB is healthy:
  - `docker compose ps`
- Confirm schema exists (init.sql ran only on first init):
  - If the volume already existed, init.sql may not rerun.
  - To force re-init (destructive): `docker compose down -v`

## Code change not reflected
- You must rebuild the image and recreate the container:
  - `docker compose build api`
  - `docker compose up -d --no-deps api`
